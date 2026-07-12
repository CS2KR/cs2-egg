# 자동 정리

데모·로그·백업·크래시 덤프를 규칙에 따라 지웁니다. 규칙은 코드가 아니라 JSON 설정으로 선언합니다.

## 켜기

Pterodactyl egg 의 시작 변수에서 `CLEANUP_ENABLED=1` 로 둡니다. 정리는 기동 시의 업데이트 흐름 안에서 함께 돕니다.

## 설정 위치

```
/home/container/egg/configs/cleanup.json
```

첫 기동 때 무난한 기본값으로 자동 생성됩니다. 패널 파일 관리자, SFTP, `nano` 로 고친 뒤 저장하고 서버를 재시작하면 반영됩니다.

## 기본 규칙

기본으로 여섯 개가 들어 있고, 흔히 용량을 잡아먹는 것들을 덮습니다.

| 규칙 | 대상 | 기본 보관 기간 |
|------|------|-------------|
| `backup_rounds` | CS2 경기 라운드 백업 `backup_round*.txt` | 24시간 |
| `demos` | SourceTV `.dem` 녹화 | 168시간 (7일) |
| `swiftly_logs` | SwiftlyS2 `logs/*.log` | 72시간 (3일) |
| `accelerator_dumps` | AcceleratorCS2 `*.dmp` · `*.dmp.txt` | 168시간 (7일) |
| `core_dumps` | 리눅스 코어 덤프 (`core`, `core.NNNN`) | 0시간 (실행할 때마다) |

## 규칙 형식

`rules` 의 각 항목은 이렇게 생겼습니다.

```json
{
  "name": "demos",
  "description": "SourceTV 데모 녹화 파일입니다.",
  "directories": ["./game/csgo"],
  "patterns": ["*.dem"],
  "hours": 168,
  "recursive": true,
  "enabled": true
}
```

| 항목 | 형식 | 뜻 |
|-------|------|---------|
| `name` | 문자열 | 로그에 표시되는 분류 이름입니다. 짧게 쓰세요. |
| `description` | 문자열 | 사람이 읽는 설명입니다. 동작에는 영향을 주지 않습니다. |
| `directories` | 문자열 배열 | 찾아볼 경로입니다. 상대경로는 컨테이너 작업 디렉터리(`/home/container`) 기준입니다. 절대경로도 됩니다. |
| `patterns` | 문자열 배열 | 파일 이름 글롭입니다. 전체 경로가 아니라 **파일 이름**과만 비교합니다. `*.dem`, `core`, `core.[0-9]*`, `backup_round*.txt` 모두 됩니다. |
| `hours` | 숫자 | 수정 시각이 이 시간보다 오래된 파일을 지웁니다. `0` 이면 나이와 무관하게 매번 지웁니다. |
| `recursive` | 참/거짓 | `true` 면 하위 디렉터리까지, `false` 면 해당 디렉터리만 봅니다 (`-maxdepth 1`). |
| `enabled` | 참/거짓 | `false` 면 항목을 지우지 않고 그 규칙만 끕니다. |

## 자주 바꾸는 것들

### 데모를 더 오래 보관하기

```json
{
  "name": "demos",
  "directories": ["./game/csgo"],
  "patterns": ["*.dem"],
  "hours": 720,
  "recursive": true,
  "enabled": true
}
```
720시간이면 30일입니다.

### 데모를 아예 지우지 않기

```json
{
  "name": "demos",
  "directories": ["./game/csgo"],
  "patterns": ["*.dem"],
  "hours": 168,
  "recursive": true,
  "enabled": false
}
```
`enabled: false` 는 항목을 남긴 채 규칙만 끕니다. 나중에 되돌리기 쉽습니다.

### 특정 플러그인의 로그 지우기

```json
{
  "name": "my_plugin_logs",
  "description": "MyPlugin 로그를 2일 뒤 지웁니다",
  "directories": ["./game/csgo/addons/myplugin/logs"],
  "patterns": ["*.log"],
  "hours": 48,
  "recursive": false,
  "enabled": true
}
```

### 임시 파일 쓸어내기

```json
{
  "name": "temp_maps",
  "directories": ["./game/csgo/maps/workshop"],
  "patterns": ["*.tmp", "*.cache"],
  "hours": 1,
  "recursive": true,
  "enabled": true
}
```

### 한 규칙에 여러 디렉터리

```json
{
  "name": "core_dumps",
  "directories": ["./game/bin/linuxsteamrt64", "/home/container"],
  "patterns": ["core", "core.[0-9]*"],
  "hours": 0,
  "recursive": false,
  "enabled": true
}
```
기본 `core_dumps` 규칙이 이미 이렇게 되어 있습니다.

## 어떻게 도는가

1. `CLEANUP_ENABLED=1` 이면 entrypoint 의 업데이트 흐름 안에서 정리가 돕니다.
2. **켜진** 규칙마다 `find` 명령을 만듭니다.
   - `find <directories> [-maxdepth 1] -type f \( -name <p1> -o -name <p2> ... \) [-mmin +<hours*60>]`
3. 걸린 파일을 지우고, 확보한 용량과 규칙별 개수를 셉니다.
4. 마지막에 한 줄로 요약합니다.
   ```
   CS2.KR | 완료   | 17 개 파일을 정리해 1.23 GB 를 확보했습니다 (2초)
   CS2.KR | 디버그 |   demos: 14 개
   CS2.KR | 디버그 |   core_dumps: 3 개
   ```
5. 지운 게 없으면 아무 로그도 남기지 않습니다.

## 주의할 점

- **글롭은 파일 이름만 봅니다.** `"patterns": ["*.dem"]` 은 그 디렉터리 아래 어디에 있든 `.dem` 파일을 잡습니다. `demos/backup.dem` 처럼 경로를 적을 수는 없습니다. 범위는 `directories` 로 좁히세요.
- **심볼릭 링크는 따라가지 않습니다** (`find` 의 기본 동작). 링크된 대상을 지우려면 실제 경로를 적으세요.
- **경로는 정리 시점에 해석됩니다.** 상대경로는 `cleanup.sh` 가 있는 곳이 아니라 컨테이너 작업 디렉터리(`/home/container`) 기준입니다.
- **정규식은 지원하지 않습니다.** 셸 글롭(`*`, `?`, `[...]`)만 됩니다. 복잡한 조건이 필요하면 패턴이나 규칙을 여러 개로 나누세요.
- **설정 버전이 오르면 파일이 다시 만들어집니다.** egg 가 `CONFIG_VERSION` 을 올리면 `cleanup.json` 을 새로 쓰고, 사용자가 바꾼 **값**만 되살립니다. 다만 `rules` 는 배열이라 통째로 옛 값이 유지됩니다. 새로 추가된 기본 규칙을 쓰고 싶다면 파일을 지우고 재기동해 새로 만드세요.

## 잘 안 될 때

정리가 조용한데 파일이 그대로라면 다음을 확인하세요.

1. **`CLEANUP_ENABLED=1` 인가요?** Pterodactyl 시작 변수입니다.
2. **그 규칙의 `enabled` 가 `true` 인가요?**
3. **`hours` 가 현실과 맞나요?** `hours: 168` 은 7일보다 오래된 파일만 지웁니다. 갓 만들어진 파일은 남습니다.
4. **디렉터리가 실제로 있나요?** 없는 디렉터리는 조용히 건너뜁니다.
5. **`logging.json` 에서 로그 수준을 `DEBUG` 로 올리세요.** 걸린 파일이 0개여도 규칙별 개수가 보입니다.

## 함께 보기

- 설정 형식 자세히 → [configuration/configuration-files.md](../configuration/configuration-files.md)
- 정리가 낼 수 있는 에러 코드 → [advanced/error-codes.md](../advanced/error-codes.md)
