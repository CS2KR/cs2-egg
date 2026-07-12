# 문제 해결

자주 겪는 문제와 해결 방법입니다.

## 설치

### 설치 뒤 서버가 뜨지 않을 때

**증상**: 시작하자마자 멈추거나 콘솔에 에러가 납니다.

1. 디스크 여유를 확인하세요 (40GB 이상 권장).
2. Docker 이미지를 제대로 받았는지 확인하세요.
3. 콘솔에 SteamCMD 에러가 없는지 보세요.
4. 포트가 이미 쓰이고 있지 않은지 확인하세요.

### SteamCMD 다운로드 실패

**오류**: `Failed to download SteamCMD` 또는 `Connection timeout`

1. 노드의 인터넷 연결을 확인하세요.
2. 방화벽이 Steam CDN 을 막고 있지 않은지 확인하세요.
3. Steam 상태를 확인하세요 — https://steamstat.us/
4. 서버를 다시 시작해 보세요.

### 종료 코드 8 — 연결 오류

**오류**: `SteamCMD failed with exit code 8` ([KL-STM-01](error-codes.md#kl-stm-01))

1. Steam 서버까지 네트워크가 닿는지 확인하세요.
2. DNS 가 제대로 도는지 확인하세요.
3. 디스크 여유를 확인하세요 (30~40GB 필요).
4. VPN·프록시를 쓰고 있다면 끄세요.
5. 몇 분 뒤 다시 시도하세요 (Steam 쪽 일시적 문제일 수 있습니다).

## 중앙 업데이트 스크립트

### 스크립트가 돌지 않을 때

- [ ] 실행 권한이 있나요? `chmod +x /usr/local/bin/update-cs2-centralized.sh`
- [ ] Docker 데몬이 돌고 있고 접근되나요?
- [ ] cron 이 등록되어 있나요? `cat /etc/cron.d/cs2-update`
- [ ] 스크립트 상단의 `CS2_DIR` 경로가 맞나요?

**수동으로 시험**

```bash
/usr/local/bin/update-cs2-centralized.sh --simulate
```

**로그 보기**

```bash
tail -f /var/log/cs2-update.log
journalctl -u cs2-vpk-daemon -f
```

### 잠금 파일 충돌

**오류**: `Another instance is running (lockfile exists)`

**정상 동작입니다.** cron 이 겹쳐 도는 것을 막습니다.

1. 지금 도는 업데이트가 끝나기를 기다리세요.
2. 30분 넘게 멈춰 있는 게 확실할 때만 지우세요.
   ```bash
   rm /var/lock/cs2-update.lock
   ```
3. 멈춘 Docker 작업이 없는지 확인하세요. `docker ps -a`

### 컨테이너가 재시작되지 않을 때

**증상**: CS2 업데이트는 끝났는데 서버가 재시작되지 않습니다.

가장 흔한 원인은 **`SERVER_IMAGE` 가 실제 컨테이너 이미지와 다른 것**입니다. 목록에 없는 이미지의
컨테이너는 스크립트에도 데몬에도 보이지 않아, 파일도 밀어 넣지 않고 재시작도 하지 않습니다.
설치 마법사는 이 값을 묻지 않으므로 직접 확인해야 합니다.

- [ ] `AUTO_RESTART_SERVERS="true"` 인가요?
- [ ] `SERVER_IMAGE` 가 돌고 있는 컨테이너의 이미지와 일치하나요?
- [ ] Docker 데몬에 컨테이너를 재시작할 권한이 있나요?

**확인**

```bash
# 지금 돌고 있는 컨테이너의 이미지
docker ps --format "{{.Names}}\t{{.Image}}"

# 스크립트가 찾는 이미지
grep '^SERVER_IMAGE=' /usr/local/bin/update-cs2-centralized.sh

# 둘이 다르면 스크립트를 고친다
nano /usr/local/bin/update-cs2-centralized.sh
```

> 이 egg 의 이미지는 `ghcr.io/cs2kr/cs2-egg` 입니다. `ghcr.io/cs2kr/csgo-egg` (CS:GO 서버용)와는
> 다른 이미지이니 섞지 마세요.

### SteamCMD 업데이트 실패

1. 평소에는 `VALIDATE_INSTALL="false"` 로 두세요 (빠릅니다).
2. 문제를 고칠 때만 검사를 켜세요. 이번 실행에만 켜려면 `--validate` 를 붙입니다.
   ```bash
   /usr/local/bin/update-cs2-centralized.sh --validate
   ```
3. 디스크 여유를 확인하세요 (60~70GB 필요).
4. Steam CDN 까지 네트워크가 닿는지 확인하세요.

### 스크립트가 엉뚱한 버전으로 바뀔 때

`AUTO_UPDATE_SCRIPT="true"` 면 스크립트가 `GITHUB_REPO` 에서 자신을 갱신합니다. 이 값이 다른 저장소를
가리키면 남의 스크립트로 덮어씁니다. `CS2KR/cs2-egg` 인지 확인하세요.

```bash
grep '^GITHUB_REPO=' /usr/local/bin/update-cs2-centralized.sh
```

백업은 스크립트 옆의 `.script-backups/` 에 3개까지 남습니다.

## 프레임워크 자동업데이트

### MetaMod 가 갱신되지 않을 때

1. **Startup** 탭에서 `INSTALL_METAMOD` 가 `1` 인지 확인하세요.
2. 인터넷 연결을 확인하세요.
3. metamodsource.net 에 닿는지 확인하세요.
4. `game/csgo/addons/metamod/` 가 있는지 확인하세요.
5. 콘솔에 다운로드 에러가 없는지 보세요.
6. `egg/versions.txt` 를 지우고 재시작해 강제로 다시 받게 하세요.

### SwiftlyS2 가 설치되지 않을 때

1. **Startup** 탭에서 `INSTALL_SWIFTLY` 를 `1` 로 두세요.
2. SwiftlyS2 는 단독으로 돕니다 (MetaMod 불필요).
3. GitHub 릴리스에 닿는지 확인하세요 (`swiftly-solution/swiftlys2`).
4. 기동 로그의 에러를 보세요.
5. `game/csgo/addons/swiftlys2/` 가 있는지 확인하세요.

### ModSharp 가 설치되지 않을 때

1. **Startup** 탭에서 `INSTALL_MODSHARP` 를 `1` 로 두세요.
2. .NET 런타임 설치가 성공했는지 로그로 확인하세요.
3. GitHub 릴리스에 닿는지 확인하세요 (`Kxnrl/modsharp-public`).
4. `game/sharp/` 가 있는지 확인하세요.
5. 콘솔의 다운로드·압축 해제 에러를 보세요.

> ModSharp 와 SwiftlyS2 를 함께 켜면 egg 는 **경고만** 하고 자동으로 꺼 주지 않습니다.
> 플러그인이 이상하게 동작하면 하나만 켜세요.

## 서드파티 플러그인 자동업데이트

### 플러그인이 갱신되지 않을 때

1. `PLUGIN_UPDATE_ENABLED` 가 `1` 인지 확인하세요.
2. `egg/configs/plugins.json` 에 그 플러그인이 있는지 확인하세요.
3. `detect` 경로가 볼륨에 실제로 있는지 확인하세요. 없으면 **일부러 건너뜁니다** (없던 플러그인을
   새로 깔지 않습니다).
4. `enabled` 가 `false` 가 아닌지 확인하세요.
5. 기동 로그에서 그 플러그인 이름이 찍힌 줄을 찾으세요.

### GitHub 한도에 걸릴 때

**오류**: `403` / `rate limit`

비인증 요청은 IP 당 시간당 60회입니다. 여러 서버가 공인 IP 를 공유하면 금방 소진됩니다.
`GITHUB_TOKEN` (권한 없는 fine-grained PAT) 을 넣으면 5000회/시간이 됩니다.

한도에 걸리면 업데이터는 **아무것도 건드리지 않고 멈춥니다.** 서버는 기존 플러그인으로 그대로 뜹니다.

자세한 내용은 [서드파티 플러그인 자동업데이트](../features/plugin-updater.md) 를 보세요.

## 콘솔 필터

### 필터가 동작하지 않을 때

1. `ENABLE_FILTER` 가 `1` 인지 확인하세요.
2. `egg/configs/console-filter.json` 이 있는지 확인하세요.
3. 패턴이 맞는지 확인하세요. 패턴은 CS2 가 뱉는 **영문 원문**과 비교합니다. 번역하면 안 됩니다.
4. `preview_mode` 를 켜서 무엇이 걸러지는지 확인하세요.

### 너무 많이 걸러질 때

1. `egg/configs/console-filter.json` 을 고칩니다.
2. `patterns` 를 다시 보세요.
3. 더 구체적으로 쓰세요. `@` 를 앞에 붙이면 줄 전체가 똑같을 때만 막습니다.
4. 지나치게 넓은 패턴을 지우세요.
5. 재시작해 확인하세요.

### 설정이 반영되지 않을 때

1. JSON 문법을 확인하세요. `jq -e . egg/configs/console-filter.json`
2. 파일 권한을 확인하세요.
3. 고친 뒤 재시작했나요?

## 자동 정리

### 파일이 지워지지 않을 때

1. `CLEANUP_ENABLED` 가 `1` 인지 확인하세요.
2. `egg/configs/cleanup.json` 이 있는지 확인하세요.
3. 규칙의 `enabled` 가 `true` 인지 확인하세요.
4. `hours` 값이 파일 나이보다 작은지 확인하세요.
5. 기동 로그의 정리 메시지를 보세요.

### 지우면 안 될 파일이 지워졌을 때

1. `egg/configs/cleanup.json` 을 고칩니다.
2. `hours` 를 늘리세요 (예: `168` = 7일).
3. 해당 규칙의 `enabled` 를 `false` 로 두세요.
4. 아예 끄려면 `CLEANUP_ENABLED=0`.
5. 필요하면 백업에서 되살리세요.

## 로그

### 로그 파일이 생기지 않을 때

1. `egg/configs/logging.json` 에 `"file_enabled": true` 가 있는지 확인하세요.
2. `egg/logs/` 에 쓸 수 있는지 확인하세요.
3. 기동 로그의 에러를 보세요.
4. 첫 기록이 있을 때 만들어지므로 조금 늦을 수 있습니다.
5. 로깅은 항상 읽히며 별도의 egg 변수가 필요 없습니다.

### 로그 회전이 안 될 때

`egg/configs/logging.json` 의 값을 확인하세요. 항목은 모두 `logging` 아래에 평평하게 놓입니다.

```json
{
  "logging": {
    "console_level": "INFO",
    "file_enabled": true,
    "max_size_mb": 100,
    "max_files": 30,
    "max_days": 7
  }
}
```

크기·개수·기간 중 **하나라도** 상한에 닿으면 오래된 것부터 지웁니다.

### 콘솔에 아무것도 안 나올 때

1. 필터가 너무 많이 걸러내고 있지 않은지 보세요. 잠시 `ENABLE_FILTER=0` 으로 두고 확인하세요.
2. `logging.json` 의 `console_level` 을 확인하세요. `DEBUG`, `INFO`, `WARNING`, `ERROR` 를 대문자로 씁니다.
3. Docker 로그가 나오는지 확인하세요.

### 로그가 너무 많을 때

`console_level` 을 `DEBUG` 에서 `INFO` 나 `WARNING` 으로 올리고, 필요 없으면 `file_enabled` 를 끄세요.

## 성능

### CPU 사용량이 높을 때

원인은 대개 하드웨어, 접속자 수, 무거운 플러그인입니다.

1. 안 쓰는 기능을 끄세요.
2. 서버 자원을 늘리세요.
3. 플러그인을 점검하세요.

### 메모리 사용량이 높을 때

1. Pterodactyl 에서 할당 RAM 을 늘리세요.
2. 플러그인의 메모리 누수를 확인하세요.
3. `docker stats` 로 관찰하세요.

## Docker

### 컨테이너가 계속 재시작될 때

1. `docker logs <container_id>` 를 보세요.
2. 포트 충돌이 없는지 확인하세요.
3. entrypoint 스크립트의 에러를 보세요.
4. 필요한 환경변수가 모두 채워졌는지 확인하세요.

### 권한 오류

1. 컨테이너 사용자의 권한을 확인하세요.
2. Pterodactyl 노드 설정을 확인하세요.
3. `egg/` 디렉터리 권한을 확인하세요.
4. SELinux·AppArmor 가 막고 있지 않은지 확인하세요.

## 네트워크

### 서버에 접속되지 않을 때

- [ ] 포트(UDP)가 할당되고 열려 있나요?
- [ ] 방화벽이 UDP 를 허용하나요?
- [ ] GSLT 토큰이 유효한가요?
- [ ] 서버가 실제로 돌고 있나요?
- [ ] IP:포트 조합이 맞나요?

### 서버 브라우저에 안 보일 때

1. `STEAM_ACC` (GSLT 토큰) 를 넣으세요.
2. 토큰 발급 — https://steamcommunity.com/dev/managegameservers
3. LAN 전용이 아닌지 확인하세요.
4. Steam 계정 상태를 확인하세요.

## 자주 보는 메시지

### `Segmentation fault`

대개 CS2 서버가 죽은 것이고 egg 와는 무관합니다. CS2 로그와 플러그인을 보세요.

### `Connection to Steam servers successful`

정상입니다. 서버가 잘 떴다는 뜻입니다.

### `Failed to load plugin`

플러그인이 지금의 CS2 버전, 그리고 설치된 의존 항목과 맞는지 확인하세요.

### `Rate limit exceeded`

GitHub 또는 Steam API 한도입니다. `GITHUB_TOKEN` 을 넣거나 기다렸다 다시 하세요.

`KL-XXX-NN` 형태의 코드가 보이면 [에러 코드](error-codes.md) 를 보세요.

## 긴급 복구

### 서버가 완전히 망가졌을 때

1. 서버를 정지합니다.
2. 지금 파일을 백업합니다.
3. `SRCDS_VALIDATE=1` 로 검사를 강제합니다.
4. 재시작합니다 (게임 파일을 다시 받습니다).
5. 검사가 끝나면 커스텀 설정을 되돌립니다.

### 중앙 업데이트가 망가졌을 때

설치 스크립트를 다시 돌리세요. 현재 값을 기본값으로 보여 주면서 동작하는 상태로 되돌립니다.

```bash
curl -fsSL https://raw.githubusercontent.com/CS2KR/cs2-egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh \
  && sudo bash /tmp/install-cs2-update.sh
```

### 처음부터 다시

1. 서버를 정지합니다.
2. 중요한 파일(설정, DB)을 백업합니다.
3. 서버 파일을 지웁니다.
4. 패널에서 다시 설치합니다.
5. 백업을 되돌립니다.

## 도움 요청

### 물어보기 전에

1. 이 문서를 확인하세요.
2. 이미 올라온 이슈를 검색하세요.
3. 콘솔 로그의 에러를 확인하세요.
4. 설정을 다시 보세요.
5. 기본 설정으로 시험해 보세요.

### 이슈를 올릴 때 함께 적을 것

- [ ] egg 버전 / Docker 이미지 태그
- [ ] 콘솔의 전체 에러 메시지
- [ ] 관련 환경변수 (**토큰·비밀번호는 가리세요**)
- [ ] 재현 방법
- [ ] 서버 사양

### 어디에

- [이슈 열기](https://github.com/CS2KR/cs2-egg/issues/new)
- [에러 코드](error-codes.md)
