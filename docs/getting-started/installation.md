# 설치 안내

Pterodactyl 에 CS2.KR CS2 Egg 를 넣고 설정하는 과정을 안내합니다.

## 준비물

- 동작하는 Pterodactyl 패널
- 패널 관리자 권한
- 노드에 Docker 가 설치되어 있을 것

## egg 넣기

### 1단계: egg 파일 내려받기

- **[egg 파일 내려받기](https://raw.githubusercontent.com/CS2KR/cs2-egg/main/pterodactyl/cs2kr-cs2-egg.json)** (main 브랜치)

### 2단계: import

1. **관리자** 계정으로 Pterodactyl 패널에 로그인합니다.
2. **Admin** → **Nests** (Service Management 아래) 로 갑니다.
3. egg 를 넣을 Nest 를 고릅니다 (없으면 새로 만듭니다).
4. **Import Egg** 를 누릅니다.
5. 내려받은 JSON 파일을 올립니다.
6. **Import** 를 누릅니다.

## 이미 있는 서버에 적용하기

이미 돌고 있는 CS2 서버를 이 egg 로 바꾸려면 다음과 같이 합니다.

### 먼저 백업하세요

egg 를 바꾸기 전에는 항상 서버 파일을 백업하세요.

### 순서

1. **Admin** → **Servers** 로 갑니다.
2. 서버를 고릅니다.
3. **Startup** 탭으로 갑니다.
4. **Nest** 를 이 egg 가 들어 있는 것으로 바꿉니다.
5. **Egg** 를 `CS2.KR CS2 Egg` 로 바꿉니다.
6. **Skip Egg Install Script** 를 **체크합니다.** 체크하지 않으면 기존 파일이 지워질 수 있습니다.
7. **Docker Image** 를 `ghcr.io/cs2kr/cs2-egg:latest` 로 지정합니다.
8. **Save Modifications** 를 누릅니다.
9. 서버를 재시작합니다.

## 새 서버 만들기

1. **Admin** → **Servers** 로 갑니다.
2. **Create New** 를 누릅니다.
3. 이름·소유자 같은 기본 정보를 채웁니다.
4. **Nest Configuration** 까지 내립니다.
5. 이 egg 가 들어 있는 Nest 를 고릅니다.
6. egg 로 `CS2.KR CS2 Egg` 를 고릅니다.
7. **Docker Image** 를 `ghcr.io/cs2kr/cs2-egg:latest` 로 지정합니다.
8. 포트를 할당합니다.
9. 자원 제한(CPU·RAM·디스크)을 정합니다.
10. **Create Server** 를 누릅니다.

## 첫 기동

서버를 처음 켜면 이런 일이 일어납니다.

1. 컨테이너가 SteamCMD 를 내려받아 설치합니다.
2. CS2 서버 파일(약 30GB)을 내려받습니다.
3. 회선 속도에 따라 10~30분쯤 걸립니다.
4. 진행 상황은 콘솔에서 볼 수 있습니다.

## 그다음에 볼 것

- [설정 파일](../configuration/configuration-files.md) — 기능을 켜고 값을 바꾸기
- [서드파티 플러그인 자동업데이트](../features/plugin-updater.md) — 기동 시 플러그인을 최신 릴리스로
- [VPK 동기화와 중앙 업데이트](../features/vpk-sync.md) — 여러 서버가 게임 파일을 공유하기
- [프레임워크 자동업데이트](../features/auto-updaters.md) — MetaMod·CounterStrikeSharp 등 자동 갱신
- [문제 해결](../advanced/troubleshooting.md) — 흔한 문제와 해법

## Docker 이미지

이 egg 의 이미지는 GitHub Container Registry 한 곳에서 받습니다.

- `ghcr.io/cs2kr/cs2-egg:latest`

공개 이미지라 인증 없이 무제한으로 받을 수 있습니다. Docker Hub 처럼 [pull 횟수 제한](https://docs.docker.com/docker-hub/usage/pulls/)에 걸릴 일이 없습니다. 한 IP 에서 서버를 여러 대 돌리거나 자주 재시작하는 환경에서 특히 중요합니다.

## 설치 중 문제가 생기면

- [문제 해결](../advanced/troubleshooting.md) 을 보세요.
- 노드에 디스크 여유가 충분한지 확인하세요 (40GB 이상 권장).
- 노드에서 Docker 가 정상 동작하는지 확인하세요.
- 콘솔에 에러 메시지가 없는지 확인하세요. `KL-XXX-NN` 코드가 보이면 [에러 코드](../advanced/error-codes.md) 를 찾아보세요.

## 도움 요청

- [이슈 열기](https://github.com/CS2KR/cs2-egg/issues/new)
