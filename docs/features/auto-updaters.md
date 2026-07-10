# 프레임워크 자동업데이트

서버가 기동할 때 MetaMod, CounterStrikeSharp, SwiftlyS2, ModSharp 를 각각 최신으로 갱신합니다.

서드파티 **플러그인**(WeaponPaints, cs2kz 등)은 이것과 별개입니다.
[서드파티 플러그인 자동업데이트](plugin-updater.md) 를 보세요.

## 개요

- **MetaMod:Source** — 플러그인 프레임워크의 토대 (CSS 의 전제 조건)
- **CounterStrikeSharp (CSS)** — C# 플러그인 프레임워크
- **SwiftlyS2** — 단독으로 도는 C# 프레임워크 (MetaMod 불필요)
- **ModSharp** — .NET 런타임을 품은 단독 C# 플랫폼

갱신은 서버가 뜰 때 자동으로 일어납니다. 설치된 버전은 `/home/container/egg/versions.txt` 에 기록됩니다.

## 설정

### 프레임워크 고르기

각각 독립적으로 켜고 끕니다.

| 변수 | 설명 |
| --- | --- |
| `INSTALL_METAMOD` | MetaMod:Source (CSS 의 전제 조건) |
| `INSTALL_CSS` | CounterStrikeSharp (켜면 MetaMod 가 자동으로 함께 켜짐) |
| `INSTALL_SWIFTLY` | SwiftlyS2 (단독) |
| `INSTALL_MODSHARP` | ModSharp (단독) |

### 켜는 법

**패널에서**

1. **Startup** 탭으로 갑니다.
2. 원하는 프레임워크를 켭니다.
3. 저장하고 서버를 재시작합니다.

**환경변수로**

```bash
INSTALL_METAMOD=1
INSTALL_CSS=1
INSTALL_SWIFTLY=0
INSTALL_MODSHARP=0
```

### 의존 관계

CSS 를 켰는데 MetaMod 가 꺼져 있으면 egg 가 알아서 켭니다.

```
CS2.KR | 경고   | CounterStrikeSharp 는 MetaMod:Source 가 필요합니다. 자동으로 켭니다...
```

### 함께 쓰면 충돌할 수 있는 조합

ModSharp 는 다른 C# 프레임워크와 잘 맞지 않습니다. 함께 켜져 있으면 egg 가 **경고만** 합니다.
자동으로 꺼 주지는 않습니다. 하나만 쓰세요.

```
CS2.KR | 경고   | ModSharp 와 CounterStrikeSharp 가 함께 있습니다. 서로 충돌할 수 있으니 하나만 쓰기를 권합니다.
CS2.KR | 경고   | ModSharp 와 SwiftlyS2 가 함께 있습니다. 서로 충돌할 수 있으니 하나만 쓰기를 권합니다.
```

| 조합 | 상태 |
| --- | --- |
| MetaMod + CSS | 권장 |
| MetaMod + CSS + SwiftlyS2 | 함께 쓸 수 있음 |
| MetaMod + ModSharp | 함께 쓸 수 있음 |
| ModSharp + CSS | 충돌 가능 (경고만 나옴) |
| ModSharp + SwiftlyS2 | 충돌 가능 (경고만 나옴) |

### 로드 순서

**MetaMod 는 항상 `Game_LowViolence` 바로 뒤에 옵니다.** 초기화 순서상 반드시 그래야 합니다.
egg 가 `ensure_metamod_first()` 로 알아서 맞춥니다.

```
Game_LowViolence    csgo_lv
            Game    csgo/addons/metamod        ← 항상 첫 번째
            Game    csgo/addons/counterstrikesharp
            Game    csgo/addons/swiftlys2
            Game    sharp                       ← ModSharp

            Game    csgo
```

## MetaMod:Source

- metamodsource.net 에서 최신 안정판을 받습니다.
- `game/csgo/addons/metamod/` 에 풉니다.
- `gameinfo.gi` 를 자동으로 손봅니다 (항상 첫 번째 자리).
- 버전을 `versions.txt` 에 기록합니다.

```
CS2.KR | 정보   | Metamod 갱신: 2.x-dev1245 (현재: 2.x-dev1234)
CS2.KR | 완료   | Metamod 를 2.x-dev1245 으로 갱신했습니다
```

## CounterStrikeSharp

- GitHub 릴리스(`roflmuffin/CounterStrikeSharp`)에서 최신본을 받습니다.
- `game/csgo/addons/counterstrikesharp/` 에 풉니다.
- .NET 런타임이 포함된 빌드를 씁니다.
- MetaMod 가 꺼져 있으면 자동으로 켭니다.

```
CS2.KR | 경고   | CounterStrikeSharp 는 MetaMod:Source 가 필요합니다. 자동으로 켭니다...
CS2.KR | 완료   | CounterStrikeSharp 는 최신입니다 (v1.0.370)
```

**플러그인 호환성**: CSS 를 올리면 플러그인이 깨질 수 있습니다. 테스트 서버에서 먼저 확인하고,
플러그인의 변경 기록을 살펴보세요.

## SwiftlyS2

- GitHub 릴리스(`swiftly-solution/swiftlys2`)에서 받습니다.
- `game/csgo/addons/swiftlys2/` 에 풉니다.
- `gameinfo.gi` 를 자동으로 손봅니다.
- **MetaMod 가 필요 없습니다.**
- 예전에 남은 `metamod/swiftlys2.vdf` 가 있으면 지웁니다.

```
CS2.KR | 정보   | SwiftlyS2 갱신: v0.2.38 (현재: v0.2.37)
CS2.KR | 완료   | SwiftlyS2 를 v0.2.38 으로 갱신했습니다 (bin + gamedata)
```

## ModSharp

- .NET 런타임을 먼저 설치합니다.
- GitHub 릴리스(`Kxnrl/modsharp-public`)에서 core 와 extensions 를 받습니다.
- `game/sharp/` 에 풉니다.
- `gameinfo.gi` 를 자동으로 손봅니다.
- 기존 설정(`core.json`, `admins.jsonc`)은 백업했다가 되돌립니다.

```
CS2.KR | 실행   | .NET 9.0.0 런타임을 설치합니다...
CS2.KR | 완료   | .NET 9.0.0 런타임을 설치했습니다
CS2.KR | 정보   | 갱신 가능: git70 (현재: git69)
CS2.KR | 완료   | ModSharp 를 git70 으로 갱신했습니다
```

## 버전 기록

`/home/container/egg/versions.txt` 에 이렇게 남습니다.

```
Metamod=2.x-dev1245
CSS=v1.1.0
Swiftly=v0.2.38
ModSharp=git70
DotNet=9.0.0
```

FTP 로 볼 수 있고 서버 백업에도 함께 들어갑니다.

업데이터는 새 버전이 있을 때만 내려받습니다. 이미 최신이면 건너뛰므로 대역폭과 기동 시간을 아낍니다.
설치된 것이 최신 릴리스보다 **새 버전**이면 다운그레이드하지 않습니다.

## 언제 갱신되는가

- **서버가 뜰 때마다** 확인합니다.
- **돌고 있는 중에는** 갱신하지 않습니다. 재시작해야 합니다.

### 강제로 다시 받기

1. `rm /home/container/egg/versions.txt`
2. 서버 재시작

### 특정 프레임워크만 안 받기

패널에서 그 프레임워크를 끄거나 환경변수를 `0` 으로 둡니다 (`INSTALL_CSS=0`).

### 프리릴리스 받기

`PRERELEASE=1` 로 두면 프레임워크의 프리릴리스·베타도 내려받습니다. 불안정할 수 있습니다.

## 자동 재시작과 함께 쓰기

```
CS2 업데이트 감지
       ↓
서버 재시작
       ↓
게임 파일 갱신 (SteamCMD)
       ↓
프레임워크 갱신 (이 문서)
       ↓
서드파티 플러그인 갱신 (plugin-updater.md)
       ↓
gameinfo.gi 로드 순서 확인
       ↓
전부 최신인 상태로 서버 기동
```

## 잘 안 될 때

### MetaMod 가 설치되지 않을 때

- metamodsource.net 에 닿는지 확인하세요.
- 디스크 여유가 있는지 확인하세요.
- `game/csgo/addons/` 에 쓸 수 있는지 확인하세요.

```bash
curl -I https://www.metamodsource.net/downloads.php?branch=dev
```

### CSS 가 설치되지 않을 때

- MetaMod 가 자동으로 켜졌는지 로그의 경고를 확인하세요.
- GitHub API 한도에 걸리지 않았는지 확인하세요.
- 디스크 여유를 확인하세요.

흔한 오류입니다.

```
CS2.KR | 오류   | roflmuffin/CounterStrikeSharp 에서 알맞은 에셋을 찾지 못했습니다
```

대개 GitHub API 한도입니다. 한 시간 기다리거나 네트워크를 확인하세요.

### ModSharp 가 설치되지 않을 때

- .NET 런타임 설치가 성공했는지 확인하세요 (Microsoft CDN 접근).
- core 와 extensions 두 에셋이 모두 받아졌는지 확인하세요.
- .NET 런타임을 담을 디스크 여유를 확인하세요.

### 버전이 갱신되지 않을 때

같은 버전을 매번 다시 설치한다면 버전 파일이 제대로 쓰이지 않는 것입니다.

1. `/home/container/egg/versions.txt` 가 있고 읽히는지 확인하세요.
2. `/home/container/egg/` 에 쓸 수 있는지 확인하세요.
3. 갱신 중 콘솔에 에러가 없는지 확인하세요.
4. 버전 파일을 지우고 재시작해 다시 만들게 하세요.

### 로드 순서 문제

플러그인이 제대로 로드되지 않으면 `gameinfo.gi` 순서를 확인하세요.

```bash
cat game/csgo/gameinfo.gi | grep -A 10 "Game_LowViolence"
```

MetaMod 가 `Game_LowViolence` 바로 뒤에 와야 합니다.

### GitHub API 한도

```
API rate limit exceeded  /  403 Forbidden
```

비인증 요청은 IP 당 시간당 60회입니다. 한 시간 기다리거나, 재시작을 줄이거나,
[GitHub 상태](https://www.githubstatus.com/)를 확인하세요.

서드파티 플러그인 자동업데이트는 `GITHUB_TOKEN` 을 넣으면 5000회/시간으로 늘어납니다.
프레임워크 업데이터도 같은 토큰의 영향을 받습니다.

## 옛 `ADDON_SELECTION` 변수

예전 드롭다운을 쓰고 있다면 아래처럼 옮기세요. 당분간은 호환 처리가 남아 있습니다.

| 옛 값 | 새 설정 |
| --- | --- |
| `Metamod Only` | `INSTALL_METAMOD=1` |
| `Metamod + CounterStrikeSharp` | `INSTALL_METAMOD=1` + `INSTALL_CSS=1` |
| `SwiftlyS2` | `INSTALL_SWIFTLY=1` |
| `ModSharp` | `INSTALL_MODSHARP=1` |

## 자주 묻는 것

**CSS 와 SwiftlyS2 를 함께 쓸 수 있나요?**
네. 서로 호환됩니다.

**CSS 와 ModSharp 를 함께 쓸 수 있나요?**
권하지 않습니다. 충돌할 수 있고, egg 는 경고만 하고 자동으로 끄지는 않습니다.

**ModSharp 와 함께 쓸 수 있는 것은?**
MetaMod 뿐입니다.

**업데이트가 플러그인을 깨뜨릴 수 있나요?**
그렇습니다. 큰 업데이트에는 호환성이 깨지는 변경이 있습니다. 테스트 서버에서 먼저 확인하세요.

**되돌릴 수 있나요?**
직접 옛 버전을 설치하고 그 프레임워크의 자동업데이트를 끄면 됩니다.

**MetaMod 만 갱신하고 CSS 는 그대로 두려면?**
CSS 를 끄고 MetaMod 만 켜 두세요.

**베타도 받을 수 있나요?**
`PRERELEASE=1` 로 두면 받습니다.

**GitHub 이 죽으면요?**
갱신은 실패하지만 서버는 그대로 뜹니다. 다음 재시작에 다시 시도합니다.

**내가 쓰는 플러그인도 자동으로 갱신할 수 있나요?**
됩니다. [서드파티 플러그인 자동업데이트](plugin-updater.md) 를 보세요.

**버전은 어디에 기록되나요?**
프레임워크는 `/home/container/egg/versions.txt`, 서드파티 플러그인은 `/home/container/egg/plugin-versions.txt` 입니다.

**SwiftlyS2 에 MetaMod 가 필요한가요?**
아니요. 단독으로 돕니다.

## 함께 보기

- [서드파티 플러그인 자동업데이트](plugin-updater.md)
- [VPK 동기화와 중앙 업데이트](vpk-sync.md)
- [설정 파일](../configuration/configuration-files.md)
- [소스에서 빌드하기](../advanced/building.md)

## 도움 요청

- [이슈 열기](https://github.com/CS2KR/cs2-egg/issues/new)
- [문제 해결](../advanced/troubleshooting.md)
