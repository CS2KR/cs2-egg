# VPK 동기화

한 노드의 여러 CS2 서버가 게임 파일을 공유하게 해서 저장 공간과 대역폭을 크게 아낍니다.

## 개요

서버마다 게임 파일을 통째로 갖는 대신, 한곳에 둔 설치본을 함께 씁니다.

**동작 방식**

1. cron 작업이 SteamCMD 로 중앙 CS2 설치본 하나를 최신으로 유지합니다.
2. 갱신될 때마다 스크립트가 각 서버 볼륨에 게임 파일을 직접 밀어 넣습니다. Pterodactyl 의 Mount 설정이나 수동 구성이 필요 없습니다.
3. VPK 파일은 `VPK_PUSH_METHOD` 설정에 따라 심볼릭 링크(기본), 하드링크, 또는 완전 복사로 공유됩니다.
4. 데몬이 새 컨테이너를 감시하다가 처음 뜰 때 곧바로 파일을 밀어 넣습니다.

> **패널을 고칠 필요가 없습니다.** 스크립트는 Docker 와 Wings 를 직접 다룹니다. 패치도, Mount 설정도, egg 변수 설정도 필요 없습니다.

## 기동 속도

중앙 스크립트와 VPK 동기화를 쓰면 새 서버가 거의 즉시 뜹니다.

| 단계 | 시간 |
| --- | --- |
| 데몬이 컨테이너 기동을 감지 | 약 0초 |
| 데몬이 CS2_DIR 을 컨테이너에 마운트 | 1~3초 |
| entrypoint 가 VPK 를 발견하고 SteamCMD 를 건너뜀 | 약 0초 |
| CS2 서버 프로세스 시작 | 약 2초 |
| **합계 (새 서버 첫 기동)** | **약 5초** |

이게 없으면 첫 기동에 SteamCMD 다운로드로 10~30분이 걸립니다.

## 절약되는 용량

| 서버 수 | 동기화 없이 | 동기화 후 | 절약 |
| --- | --- | --- | --- |
| 1 | 55GB | 55GB | 0GB (0%) |
| 5 | 275GB | 70GB | 205GB (75%) |
| 10 | 550GB | 85GB | 465GB (85%) |
| 20 | 1.1TB | 115GB | 1025GB (86%) |
| 50 | 2.75TB | 205GB | 2.6TB (87%) |

## 준비물

- 노드의 root 권한
- Docker (Pterodactyl 노드에는 기본으로 있습니다)
- `rsync` — `apt-get install -y rsync`
- CS2 설치본 하나를 담을 약 56GB 의 여유 공간
- `hardlink` 방식을 쓴다면 `CS2_DIR` 과 패널 볼륨이 같은 파일시스템에 있어야 합니다

## 설치

설치 스크립트를 root 로 실행하면 나머지는 알아서 합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/CS2KR/cs2-egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh && sudo bash /tmp/install-cs2-update.sh
```

설치 스크립트가 하는 일은 다음과 같습니다.

1. 설정(경로, 밀어 넣는 방식, 재시작 동작)을 물어봅니다.
2. 업데이트 스크립트를 `/usr/local/bin/update-cs2-centralized.sh` 에 내려받습니다.
3. VPK push 데몬을 systemd 서비스로 설치하고 시작합니다.
4. 매분 도는 cron 을 등록합니다 (실제 실행 간격은 `UPDATE_CHECK_INTERVAL` 로 제한됩니다).

설치 뒤에는 스크립트 상단의 설정 부분을 고쳐 값을 바꿀 수 있습니다.

```bash
nano /usr/local/bin/update-cs2-centralized.sh
```

> **`SERVER_IMAGE` 은 마법사가 묻지 않습니다.** 기본값은 `ghcr.io/cs2kr/cs2-egg` 이며, 어떤 컨테이너에
> 파일을 밀어 넣고 재시작할지를 이 값이 정합니다. 다른 이미지를 쓴다면 직접 고쳐야 합니다. 목록에 없는
> 이미지의 컨테이너는 스크립트에도 데몬에도 보이지 않아, 아무 일도 일어나지 않습니다.
> 스크립트가 자기 자신을 갱신할 때 이 값은 보존되므로, 한 번 잘못 두면 계속 잘못된 채로 남습니다.
>
> ```bash
> docker ps --format "{{.Names}}\t{{.Image}}"          # 실제 컨테이너 이미지
> grep '^SERVER_IMAGE=' /usr/local/bin/update-cs2-centralized.sh   # 스크립트가 찾는 이미지
> ```

## 밀어 넣는 방식

| 방식 | 패널이 보는 디스크 사용량 | 쓰기 가능 | 조건 |
| --- | --- | --- | --- |
| `symlink` | 서버당 거의 0 | 불가 (읽기 전용) | 없음. CS2_DIR 이 컨테이너에 자동 마운트됩니다 |
| `hardlink` | 서버당 약 53GB | 불가 (읽기 전용) | CS2_DIR 이 볼륨과 같은 파일시스템에 있어야 함 |
| `copy` | 서버당 약 52GB | 가능 | 없음 |
| `off` | — | — | — |

**symlink** (기본) — 각 서버 볼륨에서 CS2_DIR 로 심볼릭 링크를 겁니다. 패널이 보는 디스크 사용량이 거의 0 입니다. 컨테이너 안에서 링크가 풀리도록 CS2_DIR 이 읽기 전용으로 바인드 마운트됩니다.

**hardlink** — 실제 디스크는 더 쓰지 않지만, 패널의 디스크 쿼터는 서버당 VPK 전체 용량(약 53GB)으로 셉니다. CS2_DIR 이 패널 볼륨과 같은 파일시스템에 있어야 합니다.

**copy** — 서버마다 독립된 사본을 갖습니다. 게임 파일에 써야 하는 경우에 씁니다.

## 자주 쓰는 명령

```bash
# 수동으로 한 번 돌리기
# cron 이 돌고 있으면 잠금 오류가 납니다. 잠시 뒤 다시 시도하세요.
/usr/local/bin/update-cs2-centralized.sh

# 밀어 넣기·재시작 로직만 시험 (SteamCMD 다운로드는 건너뜀)
/usr/local/bin/update-cs2-centralized.sh --simulate

# 데몬 상태
systemctl status cs2-vpk-daemon

# 데몬 로그 (실시간)
journalctl -u cs2-vpk-daemon -f

# 업데이트 로그
tail -f /var/log/cs2-update.log
```

## 유지보수

### 스크립트 자체 업데이트

기본으로 켜져 있습니다. GitHub 에서 새 버전을 확인하고, 설정을 보존하고, 문법을 검사한 뒤 원자적으로 자신을 교체합니다. 백업 3개를 `.script-backups/` 에 남깁니다. 끄려면 `AUTO_UPDATE_SCRIPT="false"` 로 두세요.

### 모니터링

```bash
tail -f /var/log/cs2-update.log
journalctl -u cs2-vpk-daemon --since "1 hour ago"
```

## 문제 해결

> 스크립트가 알아서 처리하는 것들: SteamCMD 설치, 32비트 라이브러리 설정, 권한, Steam SDK 라이브러리, 디렉터리 생성.

> **뭔가 망가졌다면?** 설치 스크립트를 다시 돌리세요. 현재 값을 기본값으로 제시하면서 동작하는 설정으로 되돌려 줍니다.
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/CS2KR/cs2-egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh && sudo bash /tmp/install-cs2-update.sh
> ```

### 파일시스템이 달라 하드링크가 안 될 때

**오류**: `Cross-filesystem hardlink not possible for ptero-xxxx`

`CS2_DIR` 과 패널 볼륨이 서로 다른 파티션에 있습니다.

```bash
# 파일시스템 확인
df -h /srv/cs2-shared
df -h /var/lib/pterodactyl/volumes

# 방법 A: CS2_DIR 을 볼륨과 같은 파티션으로 옮긴다
# 방법 B: 스크립트에서 VPK_PUSH_METHOD="copy" 로 바꾼다
```

### cron 이 안 돌 때

```bash
systemctl status cron
cat /etc/cron.d/cs2-update
/usr/local/bin/update-cs2-centralized.sh  # 수동으로 시험
```

## 자주 묻는 것

**패널을 고치거나 패치를 적용해야 하나요?**
아니요. 스크립트는 Docker 와 Wings 를 직접 다룹니다.

**서버마다 뭔가 설정해야 하나요?**
아니요. 호스트에서 각 서버 볼륨으로 파일을 직접 밀어 넣습니다.

**cron 이 실패하면요?**
서버는 기존 파일로 계속 돕니다. 데몬은 새 컨테이너를 여전히 처리합니다. 수동으로 밀어 넣으려면 `/usr/local/bin/update-cs2-centralized.sh --simulate` 를 돌리세요.

**cron 과 데몬은 뭐가 다른가요?**
cron 은 CS2 업데이트를 받아 이미 있는 모든 서버로 밀어 넣습니다. 데몬은 새 서버를 담당합니다. 컨테이너가 뜨는 순간 반응해서, 시작 스크립트가 돌기 전에 게임 파일을 준비합니다.

**데몬 없이 VPK 동기화만 쓸 수 있나요?**
됩니다. 데몬이 없으면 새 서버는 다음 cron 주기(약 2분)에 파일을 받습니다. CS2 기동이 그보다 오래 걸리므로 대부분은 문제가 없습니다.

## 링크

- [이슈 열기](https://github.com/CS2KR/cs2-egg/issues/new)
- [업데이트 스크립트](https://github.com/CS2KR/cs2-egg/blob/main/misc/update-cs2-centralized.sh)
- [설치 스크립트](https://github.com/CS2KR/cs2-egg/blob/main/misc/install-cs2-update.sh)
