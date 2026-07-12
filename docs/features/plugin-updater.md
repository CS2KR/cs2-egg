# 서드파티 플러그인 자동업데이트

CS2.KR 이 원본 egg 에 더한 기능입니다. 컨테이너가 기동할 때, cs2 가 뜨기 전에 볼륨의
`egg/configs/plugins.json` 에 적힌 플러그인을 GitHub 최신 릴리스로 갱신합니다.

게임 서버가 아직 떠 있지 않은 시점이라 핫리로드나 재시작을 걱정할 필요가 없고 접속자도 없습니다.

네이티브 Metamod 애드온과 SwiftlyS2 플러그인을 다룹니다. Metamod:Source 와 SwiftlyS2 **본체**는
egg 가 이미 갱신하므로 여기서 다루지 않습니다 ([프레임워크 자동업데이트](auto-updaters.md) 참고).

## 원칙

중요한 순서대로 다음과 같습니다.

- **fail-open** — 실패·타임아웃·레이트리밋이면 아무것도 건드리지 않고 서버를 그대로 기동합니다.
  구버전 플러그인으로 도는 편이 서버가 못 뜨는 것보다 낫습니다.
- **새로 설치하지 않습니다** — 각 항목의 `detect` 경로가 볼륨에 없으면 건너뜁니다. 목록이 낡아도
  없던 플러그인이 깔리지 않습니다.
- **기존 설정 파일을 덮어쓰지 않습니다** — `preserve` 로 표시한 항목은 없는 파일만 채웁니다.
- **원자적 교체와 원복** — 임시 디렉터리에 받아 아카이브 구조가 목록과 맞는지 확인하고, 대상을
  백업한 뒤 교체합니다. 실패하면 이전 상태로 되돌리고 버전을 기록하지 않아 다음 기동에 다시 시도합니다.
- **목록에 적힌 것만** — 목록에 없는 디렉터리는 손대지 않습니다.

설치된 버전은 `egg/plugin-versions.txt` 에 기록됩니다. 원본 egg 가 쓰는 `egg/versions.txt` 와 섞지 않습니다.

## 목록 파일

서버 볼륨의 `egg/configs/plugins.json` 입니다.

```json
{
  "version": "1.0.0",
  "plugins": [
    {
      "name": "WeaponSkins",
      "detect": "addons/swiftlys2/plugins/WeaponSkins",
      "repo": "samyycX/WeaponSkins",
      "asset": "^WeaponSkins-v.*\\.zip$",
      "framework": "swiftly",
      "enabled": true,
      "map": [
        { "from": "WeaponSkins", "to": "addons/swiftlys2/plugins/WeaponSkins" }
      ]
    },
    {
      "name": "cs2kz",
      "detect": "addons/cs2kz",
      "repo": "KZGlobalTeam/cs2kz-metamod",
      "asset": "^cs2kz-linux-master-upgrade\\.tar\\.gz$",
      "framework": "metamod",
      "map": [
        { "from": "addons/cs2kz", "to": "addons/cs2kz" },
        { "from": "addons/metamod", "to": "addons/metamod" },
        { "from": "cfg", "to": "cfg", "preserve": true }
      ]
    }
  ]
}
```

| 항목 | 뜻 |
|---|---|
| `name` | `egg/plugin-versions.txt` 에 버전을 기록할 때 쓰는 키입니다. |
| `detect` | 설치 여부를 판정할 경로(`game/csgo` 기준)입니다. 필수입니다. |
| `repo` | GitHub `owner/repo`. `releases/latest` 만 읽습니다. |
| `asset` | 릴리스 에셋 이름에 대한 정규식(jq `test()`). 정확히 하나만 걸려야 합니다. |
| `framework` | `metamod` 또는 `swiftly`. 그 프레임워크가 꺼진 서버에서는 설치하지 않습니다. |
| `enabled` | `false` 면 건너뜁니다. |
| `map` | `from` 은 아카이브 안의 경로, `to` 는 `game/csgo` 기준 목적지입니다. `preserve: true` 면 없는 파일만 채웁니다. |

## 왜 경로를 일일이 적는가

릴리스 아카이브의 구조가 프로젝트마다 제각각입니다. `addons/…` 로 시작하는 것, 플러그인 디렉터리가
루트에 있는 것, 한 겹 감싸인 것, DLL 이 그냥 놓인 것이 모두 있습니다. 휴리스틱으로 추론하지 않고
`map` 에 명시합니다. 업스트림이 구조를 바꾸면 업데이터는 **아무것도 건드리지 않고 중단**하므로,
그때 목록을 고치면 됩니다.

압축 형식은 파일 이름이 아니라 **내용**으로 판별합니다. 이름이 `.tar.gz` 인데 실제로는 gzip 이 아닌
순수 tar 인 배포본이 있기 때문입니다.

버전 비교는 semver 가 아니라 **태그 문자열 비교**입니다. `build-423`, `CS2-CustomIO-v.1.DZ.16` 같은
태그가 실제로 쓰입니다.

## egg 변수

| 변수 | 기본값 | 설명 |
|---|---|---|
| `GITHUB_TOKEN` | *(비어 있음)* | GitHub API 한도를 IP 당 60회/시간에서 5000회/시간으로 올립니다. **권한을 하나도 주지 않은** fine-grained PAT 면 충분합니다. |
| `PLUGIN_UPDATE_ENABLED` | `1` | `0` 이면 이 기능을 통째로 건너뜁니다. |

플러그인 하나당 부팅마다 API 를 한 번 부릅니다. 토큰을 비워 두면 비인증 한도가 금방 소진되고,
특히 여러 서버가 공인 IP 를 공유하면 더 빨리 걸립니다. 처음 `403` 을 만나면 업데이터는 즉시 멈추고,
아무것도 바꾸지 않은 채 서버를 기동합니다.

## 구현

- `docker/scripts/plugin-update.sh` — 실제 로직
- `docker/scripts/updaters/thirdparty.sh` — 활성화 여부·타임아웃·fail-open 을 다루는 얇은 래퍼
- `docker/scripts/update.sh` 의 `update_addons` 끝에서 호출됩니다. Metamod 와 SwiftlyS2
  본체가 갱신된 **뒤에** 돌아야 하기 때문입니다.
