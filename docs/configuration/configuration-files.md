# 설정 파일

이 egg 는 JSON 설정 파일로 동작을 조절합니다. 서버 재시작과 업데이트를 거쳐도 남습니다.

## 위치

모든 설정 파일은 여기 있습니다.

```
/home/container/egg/configs/
```

첫 기동 때 기본값과 설명이 담긴 채로 자동 생성됩니다.

## 어떻게 동작하는가

1. **기능을 켭니다** — Pterodactyl egg 변수로 (예: `ENABLE_FILTER=1`)
2. **세부를 정합니다** — JSON 파일로 (패턴, 주기, 규칙 등)
3. **FTP 로 고칩니다** — 모든 설정은 SFTP/FTP 로 접근할 수 있습니다
4. **재시작하면 반영됩니다**

각 파일에는 `_description` 배열이 들어 있어 항목의 뜻을 파일 안에서 바로 볼 수 있습니다.

## 설정 파일들

### `plugins.json`

**하는 일**: 기동할 때 갱신할 서드파티 플러그인 목록입니다. CS2.KR 이 더한 기능입니다.

**켜기**: egg 변수 `PLUGIN_UPDATE_ENABLED=1` (기본값)

여기 적히지 않은 플러그인은 손대지 않습니다. 자세한 형식과 원칙은
[서드파티 플러그인 자동업데이트](../features/plugin-updater.md) 를 보세요.

---

### `console-filter.json`

**하는 일**: 원치 않는 콘솔 메시지를 걸러냅니다.

**켜기**: egg 변수 `ENABLE_FILTER=1`

```json
{
  "preview_mode": false,
  "patterns": ["Certificate expires"]
}
```

**항목**

- `preview_mode` — 무엇이 걸러졌는지 디버그 로그에 남깁니다 (시험용)
- `patterns` — 필터 패턴 목록
  - `"@정확히 이 줄"` — 줄 전체가 똑같을 때만 막습니다
  - `"이 문구 포함"` — 그 문구가 들어간 줄을 모두 막습니다 (기본)

**예**

```json
{
  "patterns": ["@Server is hibernating", "edicts used", "ConVarRef", "Fontconfig error"]
}
```

패턴은 CS2 가 실제로 뱉는 영문 줄과 비교하므로 번역하면 안 됩니다.

**참고**: `STEAM_ACC`(GSLT 토큰)는 설정과 무관하게 항상 가려집니다.

---

### `cleanup.json`

**하는 일**: 오래된 파일을 규칙에 따라 지웁니다.

**켜기**: egg 변수 `CLEANUP_ENABLED=1`

```json
{
  "version": "1.2.0",
  "rules": [
    {
      "name": "demos",
      "description": "SourceTV 데모 녹화 파일입니다.",
      "directories": ["./game/csgo"],
      "patterns": ["*.dem"],
      "hours": 168,
      "recursive": true,
      "enabled": true
    }
  ]
}
```

**규칙 항목**

- `name` — 로그에 표시되는 분류 이름
- `directories` — 찾아볼 경로 (`/home/container` 기준 상대경로 또는 절대경로)
- `patterns` — 파일 이름 글롭 (예: `*.dem`, `core.[0-9]*`)
- `hours` — 이 시간보다 오래된 파일을 지웁니다 (`0` 이면 매번)
- `recursive` — `true` 면 하위 디렉터리까지
- `enabled` — `false` 면 규칙을 지우지 않고 끕니다

기본 규칙: `backup_rounds`, `demos`, `css_logs`, `swiftly_logs`, `accelerator_dumps`, `core_dumps`.

예시가 더 필요하면 → [features/cleanup.md](../features/cleanup.md)

---

### `logging.json`

**하는 일**: 콘솔 출력 수준과 파일 로그 회전을 정합니다.

**참고**: 항상 읽히며 별도의 egg 변수가 필요 없습니다.

```json
{
  "logging": {
    "console_level": "INFO",
    "file_enabled": false,
    "max_size_mb": 100,
    "max_files": 30,
    "max_days": 7
  }
}
```

**항목**

- `console_level` — 콘솔에 찍을 최소 수준. `DEBUG`, `INFO`, `WARNING`, `ERROR` (대문자 그대로 씁니다)
- `file_enabled` — `/home/container/egg/logs/` 에 파일로도 남길지
- `max_size_mb` — 로그 디렉터리 전체 크기 상한 (MB)
- `max_files` — 보관할 로그 파일 개수 상한
- `max_days` — 로그 파일을 보관할 최대 일수

**로그 회전**

- 하루에 한 파일: `YYYY-MM-DD.log`
- 크기·개수·기간 중 하나라도 상한에 닿으면 오래된 것부터 지웁니다
- 위치: `/home/container/egg/logs/`

---

## 패널에 보이지 않는 egg 변수

패널 UI 에 노출되지 않지만 egg JSON 을 고쳐 바꿀 수 있는 변수입니다.

### `PREFIX_TEXT`

**하는 일**: 로그 앞에 붙는 이름을 바꿉니다.

**기본값**: `CS2.KR`

**바꾸는 법**

1. Pterodactyl 에서 **Admin → Nests → CS2.KR CS2 Egg** 로 갑니다.
2. **Variables** 탭에서 `PREFIX_TEXT` 를 찾습니다.
3. `Default Value` 를 바꿉니다.
4. 저장합니다.
5. 이 egg 를 쓰는 모든 서버가 재시작 뒤 새 접두어를 씁니다.

**출력 예**

- 기본: `CS2.KR | 정보   | 서버를 시작합니다: ./game/cs2.sh`
- 변경: `MyServer | 정보   | 서버를 시작합니다: ./game/cs2.sh`

색과 서식은 그대로이고 맨 앞의 이름만 바뀝니다.

---

### `GITHUB_TOKEN`

**하는 일**: 서드파티 플러그인 자동업데이트가 GitHub 릴리스를 조회할 때 씁니다.

**기본값**: 비어 있음

비워 두면 IP 당 시간당 60회로 제한됩니다. 여러 서버가 공인 IP 를 공유하면 기동할 때 갱신이 실패합니다.
**권한을 하나도 주지 않은** fine-grained PAT 면 충분합니다.

---

### `ALLOW_TOKENLESS`

**하는 일**: GSLT(Steam 게임 서버 로그인 토큰) 없이도 서버가 뜨게 합니다.

**기본값**: `0` (끔)

**주의**: 토큰 없이 공개 서버를 돌리는 것은 Steam 약관에 어긋날 수 있습니다. 다음 용도로만 쓰세요.

- 비공개 테스트 환경
- LAN 서버
- 개발용

**GSLT 를 쓰면 좋은 이유**

토큰을 쓰는 서버는 IP 가 바뀌어도 며칠 안에 Steam 이 플레이어의 즐겨찾기를 자동으로 갱신해 줍니다.

1. `192.168.1.100` 에서 토큰을 달고 서버를 돌립니다.
2. 플레이어가 즐겨찾기에 추가합니다.
3. 같은 토큰으로 `10.0.0.50` 으로 옮깁니다.
4. 2~5일 안에 플레이어의 즐겨찾기가 새 IP 로 갱신됩니다.

**토큰 없이 돌리는 법**

*서버 하나만* (권장)

1. 관리자 화면에서 서버로 들어갑니다.
2. **Startup** 탭에서 `ALLOW_TOKENLESS` 를 찾습니다.
3. `0` 에서 `1` 로 바꿉니다.
4. 서버를 재시작합니다.

*모든 서버* (egg 기본값)

1. **Admin → Nests → CS2.KR CS2 Egg** → **Variables** 로 갑니다.
2. `ALLOW_TOKENLESS` 의 `Default Value` 를 `1` 로 바꿉니다.
3. 저장합니다.

이 설정은 `gameinfo.gi` 의 `RequireLoginForDedicatedServers` 를 우회합니다. 운영 서버라면
[Steam 게임 서버 계정 관리](https://steamcommunity.com/dev/managegameservers)에서 정상 토큰을 발급받아 쓰세요.

---

## 설정 파일에 접근하기

### FTP/SFTP

1. FTP 로 서버에 접속합니다.
2. `/egg/configs/` 로 갑니다.
3. 아무 편집기로 JSON 을 고칩니다.
4. 저장하고 서버를 재시작합니다.

### Pterodactyl 파일 관리자

1. 패널에서 서버로 들어갑니다.
2. **Files** 를 누릅니다.
3. `egg/configs/` 로 갑니다.
4. 파일을 눌러 고칩니다.
5. 저장하고 서버를 재시작합니다.

### 콘솔

```bash
# 내용 보기
cat egg/configs/console-filter.json

# nano 로 고치기
nano egg/configs/console-filter.json
```

## 첫 기동 때

1. `/home/container/egg/configs/` 디렉터리가 만들어집니다.
2. 기본값이 담긴 JSON 파일들이 생깁니다.
3. 각 파일에는 설명이 담긴 `_description` 배열이 들어 있습니다.
4. 기능은 대부분 꺼진 상태입니다.
5. 파일을 고쳐 원하는 기능을 켭니다.

## 설정 순서

### 1단계: 기능 켜기

Pterodactyl egg 변수를 `1` 로 둡니다.

- `ENABLE_FILTER` — 콘솔 필터
- `CLEANUP_ENABLED` — 자동 정리
- `PLUGIN_UPDATE_ENABLED` — 서드파티 플러그인 자동업데이트 (기본 켜짐)

CS2 업데이트 시 자동 재시작은 [VPK 동기화와 중앙 업데이트](../features/vpk-sync.md) 를 보세요.

### 2단계: 세부 설정

`/egg/configs/` 의 해당 JSON 파일을 고칩니다.

### 3단계: 서버 재시작

다음 기동 때 반영됩니다.

## 예시

### 콘솔 필터 켜기

1. egg 변수 `ENABLE_FILTER=1`
2. `egg/configs/console-filter.json` 을 고칩니다.

```json
{
  "preview_mode": false,
  "patterns": ["HostStateTransition", "edicts used", "@Server is hibernating"]
}
```

3. 서버를 재시작합니다.

### 날짜별 로그 파일 남기기

1. `egg/configs/logging.json` 을 고칩니다.

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

2. 서버를 재시작합니다.
3. `/egg/logs/YYYY-MM-DD.log` 에 쌓입니다.

## 잘 안 될 때

### 설정이 안 읽힐 때

- 파일이 `/home/container/egg/configs/` 에 있나요?
- JSON 문법이 올바른가요? (`jq -e . 파일` 로 확인)
- 해당 기능을 egg 변수로 켰나요?
- 고친 뒤 서버를 재시작했나요?

### 기능이 동작하지 않을 때

- egg 변수가 `1` 인가요?
- 필요한 값(토큰 등)을 채웠나요?
- 콘솔 로그에 에러가 없나요? `KL-XXX-NN` 코드가 보이면 [에러 코드](../advanced/error-codes.md) 를 보세요.

### 기본값으로 되돌리기

파일을 지우고 서버를 재시작하면 다시 만들어집니다.

```bash
rm /home/container/egg/configs/console-filter.json
# 재시작하면 기본 설정이 새로 생긴다
```

전부 되돌리려면 이렇게 합니다. `plugins.json` 은 우리가 배포한 목록이라 함께 사라지니 주의하세요.

```bash
rm -rf /home/container/egg/configs/
```

## 백업과 복원

### 백업

FTP 로 `/egg/` 디렉터리를 통째로 내려받습니다. 설정·로그·버전 기록이 모두 들어 있습니다.

콘솔에서는 이렇게 합니다.

```bash
cd /home/container
tar -czf egg-backup.tar.gz egg/
```

### 복원

```bash
cd /home/container
tar -xzf egg-backup.tar.gz
# 서버 재시작
```

## 함께 보기

- [서드파티 플러그인 자동업데이트](../features/plugin-updater.md)
- [프레임워크 자동업데이트](../features/auto-updaters.md)
- [VPK 동기화와 중앙 업데이트](../features/vpk-sync.md)
- [자동 정리](../features/cleanup.md)
- [빠른 시작](../getting-started/quickstart.md)

## 도움 요청

- [이슈 열기](https://github.com/CS2KR/cs2-egg/issues/new)
