# 업데이트

egg, Docker 이미지, 게임 파일을 갱신하는 방법입니다.

## egg 갱신하기

egg 의 새 버전이 나오면 이렇게 합니다.

### 관리자가 할 일

1. GitHub 에서 최신 [egg JSON](https://raw.githubusercontent.com/CS2KR/cs2-egg/main/pterodactyl/cs2kr-cs2-egg.json) 을 내려받습니다.
2. **Admin** → **Nests** → 해당 Nest → **Eggs** 로 갑니다.
3. `CS2.KR CS2 Egg` 를 고릅니다.
4. 둘 중 하나를 합니다.
   - **A안**: **Import Egg** 로 새 JSON 을 올립니다.
     - **주의**: 모든 변수가 기본값으로 되돌아갑니다.
     - `GITHUB_TOKEN`, VPK 동기화 경로처럼 손으로 넣은 값을 다시 채워야 합니다.
   - **B안**: **Variables** 탭에서 바뀐 변수만 손으로 고칩니다.
     - 기존 설정이 그대로 남습니다.
     - 커밋 기록에 언급된 변수만 손대면 됩니다.

### 권장하는 방법

**운영 서버라면 B안**(수동 갱신)을 쓰세요. 재설정할 일이 없습니다.

1. [커밋 기록](https://github.com/CS2KR/cs2-egg/commits/main) 에서 새로 생기거나 바뀐 변수를 확인합니다.
2. **Variables** 탭에서 그 변수만 고칩니다.
3. 나머지 설정은 그대로 유지됩니다.

**새로 배포하거나 큰 버전을 올릴 때는 A안**(import)도 괜찮습니다.

1. import 전에 지금 변수 값들을 적어 둡니다.
2. 새 egg JSON 을 import 합니다.
3. 손으로 넣었던 변수를 다시 채웁니다 (`GITHUB_TOKEN`, `STEAM_ACC`, VPK 동기화 경로 등).

### 이미 있는 서버들

egg 를 갱신한 뒤에는 이렇게 합니다.

1. 그 egg 를 쓰는 서버마다 들어갑니다.
2. **Startup** 탭으로 갑니다.
3. A안으로 변수가 초기화됐다면 지금 다시 채웁니다.
4. 서버를 재시작해 반영합니다.

## Docker 이미지 갱신하기

egg 에 적힌 이미지는 서버가 뜰 때 자동으로 당겨집니다.

이 egg 의 이미지는 하나입니다.

- `ghcr.io/cs2kr/cs2-egg:latest`

`main` 브랜치의 `docker/` 가 바뀌면 GitHub Actions 가 이 태그를 다시 빌드해 밀어 올립니다. 서버는 **다음 기동 때** 새 이미지를 받습니다. 즉시 받고 싶으면 서버를 재시작하세요.

## 자동 갱신되는 것들

### CS2 게임 파일

기본으로 기동할 때마다 갱신합니다. 끄려면 이렇게 합니다.

1. **Startup** 탭으로 갑니다.
2. **게임 파일 업데이트 중지**(`SRCDS_STOP_UPDATE`) 를 찾습니다.
3. `1` 로 둡니다.
4. 저장합니다.

### 프레임워크

세 가지를 각각 켜고 끌 수 있습니다.

| 변수 | 프레임워크 |
| --- | --- |
| `INSTALL_METAMOD` | MetaMod:Source |
| `INSTALL_SWIFTLY` | SwiftlyS2 |
| `INSTALL_MODSHARP` | ModSharp |

**설정 방법**

1. **Startup** 탭으로 갑니다.
2. 원하는 프레임워크를 켭니다.
3. 저장하고 서버를 재시작합니다.
4. 켜진 프레임워크는 기동할 때마다 자동으로 갱신됩니다.

**의존 관계**

- MetaMod 는 네이티브 애드온(cs2kz, cs2fixes, cs2bhop …)의 전제 조건입니다.
- SwiftlyS2 와 ModSharp 는 단독으로 돕니다 (MetaMod 불필요).

자세한 내용은 [프레임워크 자동업데이트](../features/auto-updaters.md) 를 보세요.

### 서드파티 플러그인

`egg/configs/plugins.json` 에 적힌 플러그인을 기동할 때 최신 릴리스로 갱신합니다. CS2.KR 이 더한 기능입니다.
[서드파티 플러그인 자동업데이트](../features/plugin-updater.md) 를 보세요.

## CS2 업데이트 시 자동 재시작

CS2 가 갱신되면 서버를 자동으로 다시 띄울 수 있습니다. [VPK 동기화와 중앙 업데이트](../features/vpk-sync.md) 를 보세요.

> **서버를 여러 대 돌린다면** 서버마다 따로 받지 말고 [VPK 동기화](../features/vpk-sync.md) 와 중앙 업데이트 스크립트를 쓰세요. 한 번만 내려받아 모든 서버를 함께 재시작하므로 대역폭과 시간을 아낍니다.

## 버전 확인

### 설치된 프레임워크

`/home/container/egg/versions.txt` 에 기록됩니다.

```
Metamod=2.x-dev1245
Swiftly=v0.2.38
ModSharp=git70
DotNet=9.0.0
```

### 서드파티 플러그인

`/home/container/egg/plugin-versions.txt` 에 기록됩니다. 위 파일과 섞지 않습니다.

```
WeaponPaints=build-423
cs2kz=v0.0.147
```

**보는 방법**

- FTP: `/egg/versions.txt`
- 콘솔: `cat /home/container/egg/versions.txt`
- 로그: 기동 로그에 버전이 찍힙니다

**참고**

- 켜 둔 프레임워크만 `versions.txt` 에 나타납니다.
- 켜져 있는 동안에는 재시작할 때마다 버전이 갱신됩니다.
- 강제로 다시 받게 하려면 `versions.txt` 를 지우고 재시작하세요. 플러그인은 `plugin-versions.txt` 를 지우면 됩니다.

## 되돌리기

업데이트 뒤 문제가 생겼다면 이렇게 합니다.

### Docker 이미지

1. 서버를 정지합니다.
2. **Startup** 탭으로 갑니다.
3. Docker Image 를 이전 커밋 SHA 태그로 바꿉니다 (`ghcr.io/cs2kr/cs2-egg:<sha>`). 빌드마다 SHA 태그가 함께 올라갑니다.
4. 서버를 시작합니다.

### CS2 게임 파일

이 egg 는 CS2 버전 되돌리기를 지원하지 않습니다. 필요하다면 egg 의 자동 갱신 밖에서 SteamCMD 를 직접 써야 합니다.

## 권장 사항

1. 운영 서버에서는 **변수를 손으로 갱신(B안)** 해서 설정을 지키세요.
2. 큰 업데이트 전에는 **항상 백업**하세요.
3. 먼저 **테스트 서버에서** 시험하세요.
4. **커밋 기록**에서 호환성이 깨지는 변경을 확인하세요.
5. egg 를 import 하기 전에 **손으로 넣은 변수를 적어 두세요** (`GITHUB_TOKEN`, `STEAM_ACC`, VPK 경로 등).
6. **egg 를 최신으로 유지**해 새 기능과 수정을 받으세요.
7. **자동 재시작**을 켜서 CS2 업데이트 중 정지 시간을 줄이세요.

## 도움 요청

- [이슈 열기](https://github.com/CS2KR/cs2-egg/issues/new)
- [문제 해결](../advanced/troubleshooting.md)
