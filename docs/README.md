# CS2.KR CS2 Egg 문서

[CS2.KR](https://cs2.kr) 이 쓰는 Pterodactyl CS2 egg 문서입니다. 설치·설정·기능을 모두 다룹니다.

[K4ryuu/CS2-Egg](https://github.com/K4ryuu/CS2-Egg) (GPL-3.0) 를 기반으로 합니다. 원본과의 차이는 저장소 [README](../README.md) 를 보세요.

## 처음이라면

1. **[설치 안내](getting-started/installation.md)** — Pterodactyl 에 egg 를 넣습니다
2. **[빠른 시작](getting-started/quickstart.md)** — 서버를 띄웁니다
3. **[업데이트](getting-started/updating.md)** — egg·이미지·게임 파일을 최신으로 유지합니다

## 목차

### 시작하기

- [설치](getting-started/installation.md) — egg 를 넣고 서버에 적용하는 법
- [빠른 시작](getting-started/quickstart.md) — 서버를 빨리 띄우기
- [업데이트](getting-started/updating.md) — egg, Docker 이미지, 게임 파일 갱신

### 기능

- [서드파티 플러그인 자동업데이트](features/plugin-updater.md) — 기동 시 플러그인을 최신 릴리스로 (CS2.KR 이 더한 기능)
- [VPK 동기화와 중앙 업데이트](features/vpk-sync.md) — 저장 공간 80% 절약 + CS2 자동 갱신
- [프레임워크 자동업데이트](features/auto-updaters.md) — MetaMod·SwiftlyS2·ModSharp
- [자동 정리](features/cleanup.md) — 오래된 로그·데모·덤프 지우기

### 설정

- [설정 파일](configuration/configuration-files.md) — JSON 기반 설정 체계

### 심화

- [소스에서 빌드하기](advanced/building.md) — Docker 이미지 직접 만들기
- [GDB 디버깅](advanced/debugging.md) — GDB·IDA Pro 로 원격 디버깅
- [에러 코드](advanced/error-codes.md) — 로그의 `KL-XXX-NN` 코드 풀이
- [문제 해결](advanced/troubleshooting.md) — 흔한 문제와 해법

## 주요 기능

- **서드파티 플러그인 자동업데이트** — 기동 시 `egg/configs/plugins.json` 에 적힌 플러그인만 최신 릴리스로 (CS2.KR 이 더한 것)
- **프레임워크 자동업데이트** — MetaMod, SwiftlyS2, ModSharp
- **자동 재시작** — CS2 업데이트를 감지해 서버를 다시 띄움
- **VPK 동기화** — 게임 파일을 한곳에 두어 서버당 약 52GB 절약
- **자동 정리** — JSON 규칙으로 오래된 파일 삭제
- **색이 붙은 로그** — 회전(rotation) 지원
- **콘솔 필터** — 패턴으로 원치 않는 메시지 차단
- **토큰 없는 서버** — GSLT 없이도 기동
- **유연함** — Pterodactyl 없이 Docker 단독으로도 동작

## 자주 하는 일

### 새 서버 만들기

1. [egg 파일 내려받기](https://github.com/CS2KR/cs2-egg/blob/main/pterodactyl/cs2kr-cs2-egg.json)
2. Pterodactyl 에 import
3. 그 egg 로 새 서버 생성
4. 시작

[설치 안내 →](getting-started/installation.md)

### 자동 재시작 켜기

1. 중앙 CS2 파일을 위해 VPK 동기화를 설정합니다
2. 중앙 업데이트 스크립트를 설정합니다
3. cron 에 등록해 주기적으로 확인하게 합니다
4. CS2 가 업데이트되면 서버가 알아서 다시 뜹니다

[VPK 동기화와 중앙 업데이트 →](features/vpk-sync.md)

### 직접 이미지 빌드하기

```bash
git clone https://github.com/CS2KR/cs2-egg.git
cd cs2-egg
./build.sh my-tag
docker push your-registry/your-image:my-tag
```

[빌드 안내 →](advanced/building.md)

## 바로가기

- **[egg 파일 내려받기](https://github.com/CS2KR/cs2-egg/blob/main/pterodactyl/cs2kr-cs2-egg.json)**
- **[이슈 열기](https://github.com/CS2KR/cs2-egg/issues/new)**

## 도움이 필요하다면

1. [문제 해결](advanced/troubleshooting.md) 을 먼저 보세요.
2. [에러 코드](advanced/error-codes.md) 에서 로그의 `KL-XXX-NN` 을 찾아보세요.
3. 그래도 안 되면 [이슈](https://github.com/CS2KR/cs2-egg/issues/new)를 열어 주세요.

## 라이선스

원본을 따라 GPL-3.0 입니다. [LICENSE.md](../LICENSE.md) 를 보세요.

## 만든 사람들

- **[K4ryuu](https://github.com/K4ryuu) @ KitsuneLab** — 이 egg 의 원저작자 ([K4ryuu/CS2-Egg](https://github.com/K4ryuu/CS2-Egg))
- **[1zc](https://github.com/1zc)** — 바탕이 된 [CS2-Pterodactyl](https://github.com/1zc/CS2-Pterodactyl) 이미지
- **[Poggu](https://github.com/Poggicek)** — [CleanerCS2](https://github.com/Source2ZE/CleanerCS2) 에서 가져온 콘솔 필터 아이디어
