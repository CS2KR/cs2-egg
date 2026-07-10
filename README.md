# CS2.KR CS2 Egg

**[K4ryuu/CS2-Egg](https://github.com/K4ryuu/CS2-Egg) 를 기반으로 합니다 (GPL-3.0).** 원저작자 K4ryuu @ KitsuneLab.
포크가 아닌 독립 저장소입니다. 원본의 이슈 템플릿·후원 링크·CHANGELOG 는 가져오지 않았고,
라이선스(`LICENSE.md`, GPL-3.0)와 소스의 저작권 표기는 그대로 둡니다.

CS2.KR 운영을 위해 더한 것.

- **서드파티 플러그인 자동업데이트** — 컨테이너 기동 시 `egg/configs/plugins.json` 에 적힌 플러그인만
  GitHub 최신 릴리스로 갱신한다. CS2 가 아직 안 떠 있는 시점이라 핫리로드·재시작 문제가 없다.
  - 이미 설치된 것만 갱신한다(`detect` 경로 검사). 없던 플러그인을 새로 깔지 않는다.
  - 기존 설정 파일은 덮어쓰지 않는다(`preserve`).
  - 실패·타임아웃·레이트리밋이면 아무것도 건드리지 않고 서버를 그대로 기동한다(fail-open).
  - 구현: `docker/scripts/plugin-update.sh`, `docker/scripts/updaters/thirdparty.sh`
- egg 변수 `GITHUB_TOKEN`(레이트리밋 회피), `PLUGIN_UPDATE_ENABLED`
- 이미지: `ghcr.io/cs2kr/cs2-egg:latest`
- egg JSON: `pterodactyl/cs2kr-cs2-egg.json`

Metamod:Source 와 CounterStrikeSharp 본체는 원본 egg 가 이미 갱신하므로 manifest 에 넣지 않는다.

## 원본과의 차이

- `docker/scripts/plugin-update.sh` · `docker/scripts/updaters/thirdparty.sh` 추가
- `docker/scripts/update.sh` 의 `update_addons` 끝에서 위 업데이터를 호출
- `.github/workflows/build-image.yml` 로 `ghcr.io/cs2kr/cs2-egg` 빌드
- `pterodactyl/cs2kr-cs2-egg.json` (egg 정의)
- `docker/KitsuneLab-Dockerfile` → `docker/Dockerfile` 로 이름 변경
- 원본의 `pterodactyl/kitsunelab-cs2-egg.json`, 이슈 템플릿, `FUNDING.yml`, `CHANGELOG` 는 제거

업스트림 변경을 가져오려면 `K4ryuu/CS2-Egg` 를 remote 로 추가해 `docker/` 만 골라서 병합한다.
