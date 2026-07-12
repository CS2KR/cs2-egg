# 에러 코드

> **여기에 없는 에러거나, 적힌 방법으로 안 풀렸다면?**
> [이슈](https://github.com/CS2KR/cs2-egg/issues/new)를 열어 주세요. `KL-XXX-NN` 코드, 전체 로그, egg 버전, Docker 이미지 태그를 함께 적어 주시면 좋습니다.

egg 가 내는 치명적 오류에는 안정적인 코드가 붙습니다. 콘솔 로그의 `→ 문서:` 링크가 이 문서의 해당 항목으로 옵니다.

로그는 이렇게 보입니다.

```
CS2.KR | 오류   | [KL-STM-01] SteamCMD 접속 오류입니다 (종료 코드 8)
CS2.KR | 오류   |   → 문서: https://github.com/CS2KR/cs2-egg/blob/main/docs/advanced/error-codes.md#kl-stm-01
```

## 목차

- [KL-DMN — 데몬 / VPK 동기화](#kl-dmn)
- [KL-STM — SteamCMD](#kl-stm)
- [KL-SRV — 서버 런타임](#kl-srv)

일부 코드는 이 이미지에서 **더 이상 내보내지 않습니다**. 중앙 VPK 데몬을 쓰던 시절의 것으로, 기록을 위해 남겨 둡니다.

---

<a id="kl-dmn"></a>

## KL-DMN — 데몬 / VPK 동기화

<a id="kl-dmn-01"></a>

### KL-DMN-01 — 데몬 마커가 낡음

> 이 이미지에서는 내보내지 않습니다. 중앙 VPK 데몬을 쓰는 구성에서만 나옵니다.

**증상**: `[KL-DMN-01] Daemon marker stale (Xs > Ys)`

**의미**: 중앙 VPK 데몬이 하트비트 파일(`/home/container/egg/.daemon-managed`)을 더 이상 갱신하지 않습니다. 호스트에서 데몬 프로세스가 죽은 것이 거의 확실합니다.

**자동 복구**: egg 가 낡은 마커와 끊어진 VPK 심볼릭 링크를 지우고 SteamCMD 로 되돌아갑니다. 서버는 그래도 뜹니다.

**진단 (호스트에서)**:
```bash
sudo systemctl status cs2-vpk-daemon
sudo journalctl -u cs2-vpk-daemon -n 100 --no-pager
```

**해결**:
1. 재시작: `sudo systemctl restart cs2-vpk-daemon`
2. 서비스가 아예 없다면 설치합니다.
   ```bash
   curl -fsSL https://raw.githubusercontent.com/CS2KR/cs2-egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh
   sudo bash /tmp/install-cs2-update.sh
   ```

---

<a id="kl-dmn-02"></a>

### KL-DMN-02 — 데몬 바인드 마운트 시간 초과

> 이 이미지에서는 내보내지 않습니다.

**증상**: `[KL-DMN-02] Daemon mount wait timed out after Xs`

**의미**: 데몬 마커는 최신인데(데몬은 살아 있는데) `/tmp/cs2-shared` 가 컨테이너 안으로 바인드 마운트되지 않았습니다. VPK 심볼릭 링크가 빈 마운트를 가리키게 되고, CS2 가 게임 파일을 읽지 못합니다.

**진단 (호스트에서)**:
```bash
uname -r                 # open_tree/move_mount 시스템콜을 쓰려면 5.2 이상이어야 한다
python3 --version        # 데몬이 python3 으로 시스템콜을 호출한다
sudo journalctl -u cs2-vpk-daemon -n 100 --no-pager | grep nsenter
```

**해결**:
1. 커널이 5.2 이상인지 확인하세요 (Ubuntu 20.04+). 그보다 낮으면 이미 돌고 있는 컨테이너 네임스페이스로 바인드 마운트를 할 수 없습니다. 호스트를 올리거나 데몬 설정의 `VPK_PUSH_METHOD` 를 `hardlink` 또는 `copy` 로 바꾸세요.
2. 호스트에 `python3` 이 있는지 확인하세요. `apt-get install -y python3`
3. 데몬을 재시작하세요. `sudo systemctl restart cs2-vpk-daemon`

---

<a id="kl-dmn-05"></a>

### KL-DMN-05 — SYNC_LOCATION 디렉터리 없음 (폐기 예정 경로)

**증상**: `[KL-DMN-05] SYNC_LOCATION 디렉터리가 없습니다: <경로> — VPK 동기화를 건너뜁니다`

**의미**: `SYNC_LOCATION` 환경변수가 설정돼 있지만 컨테이너 안에 그런 경로가 없습니다. 대개 마운트 설정이 잘못된 경우입니다.

**자동 복구**: VPK 동기화를 건너뛰고 SteamCMD 로 진행합니다.

**해결**:
1. 지금 중앙 데몬을 쓰고 있다면 시작 변수에서 **`SYNC_LOCATION` 을 지우세요.** 데몬 마커가 그것을 대신합니다.
2. 아직 옛 방식이라면 Pterodactyl/Pelican 의 **Mount** 가 켜져 있고 호스트의 `/srv/cs2-shared`(또는 쓰는 경로)가 컨테이너 안의 `SYNC_LOCATION` 으로 이어지는지 확인하세요.

`SYNC_LOCATION` 은 **2026-10-01** 이후 제거됩니다. 중앙 데몬으로 옮기세요.

---

<a id="kl-dmn-06"></a>

### KL-DMN-06 — 기본 파일 동기화 실패 (폐기 예정 경로)

**증상**: `[KL-DMN-06] 기본 파일 동기화에 실패했습니다`

**의미**: `SYNC_LOCATION` 에서 `/home/container` 로 `rsync` 하는 데 실패했습니다. 대개 권한 문제이거나 디스크가 찼습니다.

**진단**:
```bash
df -h /home/container
ls -la "$SYNC_LOCATION"
```

**해결**:
1. 디스크 여유 공간을 확보하세요.
2. 호스트의 파일 소유권을 확인하세요. Pterodactyl 사용자가 `SYNC_LOCATION` 을 읽을 수 있어야 합니다.
3. 중앙 데몬으로 옮기세요 ([KL-DMN-05](#kl-dmn-05) 와 같은 이유).

---

<a id="kl-stm"></a>

## KL-STM — SteamCMD

<a id="kl-stm-01"></a>

### KL-STM-01 — SteamCMD 종료 코드 8

**증상**: `[KL-STM-01] SteamCMD 접속 오류입니다 (종료 코드 8)`

**의미**: SteamCMD 가 종료 코드 8 로 실패했습니다. "접속 오류"라는 이름은 오해를 부릅니다. 실제로는 거의 항상 **디스크 공간이나 파일시스템** 문제가 로그인·상태 실패로 번진 것입니다.

**가장 흔한 원인은 디스크 부족입니다.**

**진단**:
1. `df -h /home/container` — CS2 는 약 60GB 가 필요합니다 (VPK 동기화 데몬을 쓰면 3GB).
2. 코드 줄 **위쪽**의 SteamCMD 출력에서 `state is 0x...` 를 찾으세요.
   - `state is 0x202` → 디스크 또는 파일시스템 문제입니다. [KL-STM-03](#kl-stm-03) 을 보세요.
   - `Please use force_install_dir before logon!` → egg 의 인자 순서 문제입니다.
3. 디스크가 멀쩡할 때만 Steam 상태를 확인하세요. [steamstat.us](https://steamstat.us/) 와 `curl -sI https://steamcdn-a.akamaihd.net/`.

**해결**:
1. 호스트의 패널 볼륨 디렉터리에서 디스크 공간을 확보하세요.
2. 서버 디스크 제한(Pterodactyl/Pelican 쿼터)에 걸리지 않았는지 확인하세요.
3. 다시 시도하세요. 일시적인 CDN 문제는 저절로 풀립니다.
4. 계속 난다면 SteamCMD 출력 전체와 `state is 0x...` 코드를 담아 [이슈](https://github.com/CS2KR/cs2-egg/issues/new)를 열어 주세요.

---

<a id="kl-stm-02"></a>

### KL-STM-02 — SteamCMD 일반 실패

**증상**: `[KL-STM-02] SteamCMD 가 종료 코드 <N> 로 실패했습니다`

**의미**: SteamCMD 가 0 이 아닌 코드로 끝났는데 잘 알려진 8 은 아닙니다. 흔한 값은 `7`(구독·appid 접근 권한 없음), `1`(일반), `42`(steamcmd 버그)입니다.

**해결**:
1. 이 줄 바로 위의 SteamCMD 출력에서 진짜 원인을 찾으세요.
2. CS2 는 `SRCDS_APPID=730` 입니다. 다른 값으로 덮이지 않았는지 확인하세요.
3. 계정 로그인(`SRCDS_LOGIN`)을 쓴다면 자격 증명을 확인하세요.

---

<a id="kl-stm-03"></a>

### KL-STM-03 — 상태 0x202 (디스크 공간 / 파일시스템)

> 이 이미지에서는 내보내지 않습니다. SteamCMD 출력에 직접 나타나는 상태 코드입니다.

**증상**: `[KL-STM-03] SteamCMD Error 0x202 - Disk space or filesystem issue`

**의미**: SteamCMD 가 디스크를 다 썼거나, 파일시스템 권한·읽기전용 문제에 걸렸습니다.

**해결**:
1. `df -h /srv/cs2-shared` — 새로 설치하려면 CS2 에 **약 60GB** 가 필요합니다.
2. 마운트가 읽기전용이 아닌지 확인하세요. `mount | grep cs2-shared`
3. 받다 만 파일을 지우고 다시 시도하세요. `rm -rf /srv/cs2-shared/steamapps/downloading`

---

<a id="kl-stm-04"></a>

### KL-STM-04 — 상태 0x??? (그 밖의 SteamCMD 상태)

> 이 이미지에서는 내보내지 않습니다.

**증상**: `[KL-STM-04] SteamCMD Error 0x<hex> detected`

**의미**: SteamCMD 가 우리가 매핑하지 않은 상태 코드를 돌려줬습니다. 대부분 검증 실패나 네트워크 실패입니다.

**해결**: 코드 줄 위쪽의 SteamCMD 출력에서 진짜 원인을 찾으세요. `SRCDS_VALIDATE=1` 로 다시 시도해 볼 수 있습니다.

---

<a id="kl-stm-05"></a>

### KL-STM-05 — SteamCMD 다운로드 실패 (컨테이너 쪽)

**증상**: `[KL-STM-05] N 번 시도했지만 SteamCMD 를 내려받지 못했습니다`

**의미**: egg 가 `steamcdn-a.akamaihd.net` 에서 SteamCMD 설치 파일을 받지 못했습니다. 대개 네트워크 정책이나 DNS 문제입니다.

**해결**:
1. 컨테이너 안에서 외부 HTTPS 가 되는지 확인하세요. `curl -sI https://steamcdn-a.akamaihd.net/`
2. 노드의 방화벽·아웃바운드 규칙을 확인하세요.
3. 다시 시도하세요. 일시적인 CDN 실패는 금방 풀립니다.

---

<a id="kl-stm-06"></a>

### KL-STM-06 — SteamCMD 압축 해제 실패

**증상**: `[KL-STM-06] SteamCMD 압축을 풀지 못했습니다`

**의미**: 받은 tarball 이 깨졌거나 `tar` 가 실패했습니다.

**해결**:
1. 덜 받은 압축 파일을 지우세요. `rm -rf /home/container/steamcmd`
2. 다시 시작하면 egg 가 새로 내려받습니다.
3. 계속 난다면 디스크가 찼는지 확인하세요. `df -h`

---

<a id="kl-stm-07"></a>

### KL-STM-07 — steamcmd 디렉터리 없음

**증상**: `[KL-STM-07] steamcmd 디렉터리가 없습니다`

**의미**: 압축을 푼 뒤에도 `/home/container/steamcmd` 가 만들어지지 않았습니다. 아카이브가 잘못됐거나 설치 도중 다른 프로세스가 지운 것입니다.

**해결**: 강제로 다시 설치하세요. `/home/container/steamcmd` 를 지우고 재시작합니다. 계속 실패하면 컨테이너 볼륨을 건드리는 정리 스크립트나 백신이 없는지 확인하세요.

---

<a id="kl-srv"></a>

## KL-SRV — 서버 런타임

<a id="kl-srv-02"></a>

### KL-SRV-02 — Steam GSLT 토큰이 잘못됐거나 만료됨

**증상**: `[KL-SRV-02] Steam GSLT 토큰이 잘못됐거나 만료됐습니다` (바로 앞에 `Cert request for invalid failed with reason code 5005` 또는 `We're not logged into Steam` 이 나옵니다)

**의미**: 접속 시점에 Steam 이 게임 서버 로그인 토큰(`STEAM_ACC`)을 거부했습니다. 오래 안 써서 만료됐거나, Steam 이 회수했거나, 엉뚱한 App ID 로 발급된 경우입니다.

**자동 복구**: 없습니다. 올바른 토큰을 넣기 전까지 서버는 unranked 로 돌고 공개 목록에 오르지 않습니다.

**진단**:
1. 토큰을 가진 Steam 계정으로 로그인한 뒤 [게임 서버 계정 관리](https://steamcommunity.com/dev/managegameservers)를 여세요.
2. 목록에서 `STEAM_ACC` 의 토큰을 찾아 "Last Logon" 과 "Memo" 를 확인하세요.
3. 없거나 만료됐거나 회수됐다면 새로 발급하세요.

**해결**:
1. https://steamcommunity.com/dev/managegameservers 에서 App ID **730**(CS2)으로 새 토큰을 만듭니다.
2. Pterodactyl/Pelican 패널 → Startup → `STEAM_ACC` 를 새 토큰으로 바꿉니다.
3. 서버를 재시작합니다.

**임시 방편** (거의 쓸 일 없습니다): 시작 변수에 `ALLOW_TOKENLESS=1` 을 넣고 재시작하면 토큰 없이도 뜹니다. 다만 unranked 이고 공개 목록에 오르지 않습니다. 새 토큰을 발급하는 동안만 쓰세요.

---

<a id="kl-srv-01"></a>

### KL-SRV-01 — 서버 크래시

**증상**: `[KL-SRV-01] 서버 크래시를 감지했습니다` (`./game/cs2.sh: ... Aborted (core dumped)` 뒤에 나옵니다)

**의미**: CS2 프로세스가 예기치 않게 죽었습니다. 진짜 원인은 이 줄 **위쪽** 로그에 있습니다. 스택 트레이스, SIG 사유, 플러그인 에러 메시지를 보세요.

**흔한 원인**:

1. **플러그인 문제** — 최근에 설치하거나 갱신한 플러그인이 지금 CS2 버전과 맞지 않습니다. 하나씩 꺼 가며 범위를 좁히세요.
2. **애드온 호환성** — MetaMod / SwiftlyS2 / ModSharp 가 낡았습니다. egg 의 자동 업데이터로 전부 갱신하세요. `gameinfo.gi` 의 로드 순서도 확인하세요. **MetaMod 가 반드시 먼저** 와야 합니다.
3. **낡은 gamedata** — CS2 업데이트 뒤 플러그인의 gamedata(오프셋·시그니처)가 깨졌습니다. https://gdc.eternar.dev 에서 확인하세요.

**해결**:
1. 크래시 표시 위의 스택 트레이스를 읽으세요. 어느 모듈이 죽었는지 거기 적혀 있습니다.
2. 애드온을 전부 최신으로 올리세요.
3. 플러그인을 최소로 줄여도 재현된다면, 코어 덤프 정보와 전체 로그를 담아 [이슈](https://github.com/CS2KR/cs2-egg/issues/new)를 열어 주세요.

---

## 그래도 안 풀린다면

1. **[troubleshooting.md](troubleshooting.md)** 와 [debugging.md](debugging.md) 를 함께 보세요.
2. [이슈](https://github.com/CS2KR/cs2-egg/issues/new)를 열어 주세요. 다음을 함께 적어 주시면 좋습니다.
   - `KL-XXX-NN` 에러 코드
   - 전체 로그 (컨테이너 콘솔, 파일 로그를 켰다면 `/home/container/egg/logs/*.log`)
   - egg 버전 (`pterodactyl/cs2kr-cs2-egg.json` → `meta.version`)
   - Docker 이미지 태그 (`ghcr.io/cs2kr/cs2-egg:latest`)
   - 중앙 VPK 데몬과 관련된 문제라면 노드 관리자에게 `systemctl status cs2-vpk-daemon` 출력을 받아 첨부
