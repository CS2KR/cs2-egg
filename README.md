# CS2.KR CS2 Egg

A Pterodactyl/Pelican egg and container image for Counter-Strike 2 servers, running in production at
[CS2.KR](https://cs2.kr).

Based on **[K4ryuu/CS2-Egg](https://github.com/K4ryuu/CS2-Egg)** (GPL-3.0) by K4ryuu @ KitsuneLab.
This is a standalone repository, not a fork. `LICENSE.md` and the upstream copyright notices are kept intact.

Image: `ghcr.io/cs2kr/cs2-egg:latest` · Egg: [`pterodactyl/cs2kr-cs2-egg.json`](pterodactyl/cs2kr-cs2-egg.json)

[한국어 설명은 아래에 있습니다.](#한국어)

---

## English

### What this adds on top of upstream

**A third-party plugin auto-updater.** On container start — before `cs2` launches — the egg updates the
plugins listed in the server's `egg/configs/plugins.json` to their latest GitHub release. The game server
is not running yet, so there is no hot-reload to worry about and no players are online.

It covers both CounterStrikeSharp plugins and native Metamod addons. Metamod:Source and CounterStrikeSharp
themselves are already kept up to date by the upstream egg, so they are not managed here.

Design rules, in order of importance:

- **Fail-open.** If the update fails, times out, or hits a GitHub rate limit, nothing is touched and the
  server starts with the plugins it already has. A stale plugin beats a server that will not boot.
- **Never install anything new.** Each entry declares a `detect` path. If it does not exist on the volume,
  the plugin is skipped. A stale manifest cannot introduce plugins you never installed.
- **Never overwrite existing config.** Map entries marked `preserve` only fill in missing files.
- **Atomic replace with rollback.** Download to a temp dir, verify the archive layout matches the manifest,
  back up the targets, then swap. Any failure restores the previous state and does not record the version,
  so the next boot retries.
- **Only what the manifest names.** Directories absent from the manifest are never touched.

Implementation: [`docker/scripts/plugin-update.sh`](docker/scripts/plugin-update.sh) and
[`docker/scripts/updaters/thirdparty.sh`](docker/scripts/updaters/thirdparty.sh), called at the end of
`update_addons` in [`docker/scripts/update.sh`](docker/scripts/update.sh).

### Manifest

`egg/configs/plugins.json`, inside the server volume:

```json
{
  "version": "1.0.0",
  "plugins": [
    {
      "name": "WeaponPaints",
      "repo": "Nereziel/cs2-WeaponPaints",
      "asset": "^WeaponPaints\\.zip$",
      "enabled": true,
      "map": [
        { "from": "WeaponPaints", "to": "addons/counterstrikesharp/plugins/WeaponPaints" },
        { "from": "gamedata", "to": "addons/counterstrikesharp/gamedata" }
      ]
    },
    {
      "name": "cs2kz",
      "detect": "addons/cs2kz",
      "repo": "KZGlobalTeam/cs2kz-metamod",
      "asset": "^cs2kz-linux-master-upgrade\\.tar\\.gz$",
      "map": [
        { "from": "addons/cs2kz", "to": "addons/cs2kz" },
        { "from": "addons/metamod", "to": "addons/metamod" },
        { "from": "cfg", "to": "cfg", "preserve": true }
      ]
    }
  ]
}
```

| Field | Meaning |
|---|---|
| `name` | Key used to record the installed version in `egg/plugin-versions.txt`. |
| `detect` | Path relative to `game/csgo` that must exist for the plugin to be updated. Defaults to `addons/counterstrikesharp/plugins/<name>`. |
| `repo` | GitHub `owner/repo`. Only `releases/latest` is read. |
| `asset` | Regex matched against release asset names (jq `test()`). Must match exactly one asset. |
| `enabled` | `false` skips the entry. |
| `map` | `from` is a path inside the release archive, `to` is the destination relative to `game/csgo`. `preserve: true` creates missing files only. |

Release archives differ wildly in layout — some ship `addons/…`, some a bare plugin directory, some a
wrapper directory, some loose DLLs. Rather than guessing, the mapping is declared explicitly. If an upstream
project changes its archive layout, the updater aborts before touching anything and you fix the manifest.

Archive type is detected from content, not from the filename: at least one project ships a plain tar named
`.tar.gz`. Version comparison is plain tag-string inequality against `releases/latest`, not semver — real
tags in the wild include `build-423` and `CS2-CustomIO-v.1.DZ.16`.

### Egg variables

Added on top of the upstream set:

| Variable | Default | Purpose |
|---|---|---|
| `GITHUB_TOKEN` | *(empty)* | Raises the GitHub API rate limit from 60/hour per IP to 5000/hour. A fine-grained PAT with **no permissions** is enough. |
| `PLUGIN_UPDATE_ENABLED` | `1` | Set to `0` to skip the third-party updater entirely. |

Each plugin costs one API call per boot. Without a token the unauthenticated budget runs out quickly,
especially when several servers share one public IP. On the first `403` the updater stops, changes nothing,
and lets the server start.

Egg variable names and descriptions, and the generated `egg/configs/*.json` files, are written in Korean.

### Differences from upstream

- Added `docker/scripts/plugin-update.sh` and `docker/scripts/updaters/thirdparty.sh`
- `update_addons` in `docker/scripts/update.sh` calls the updater last
- `.github/workflows/build-image.yml` builds and pushes `ghcr.io/cs2kr/cs2-egg`
- `pterodactyl/cs2kr-cs2-egg.json` replaces the upstream egg definition
- `docker/KitsuneLab-Dockerfile` renamed to `docker/Dockerfile`
- Upstream issue templates, `FUNDING.yml`, `CHANGELOG` and `CODEOWNERS` were not carried over

To pull upstream changes, add `K4ryuu/CS2-Egg` as a remote and merge `docker/` selectively.

### License

GPL-3.0, inherited from the upstream project. See [`LICENSE.md`](LICENSE.md).

---

## 한국어

CS2.KR 게임 서버가 쓰는 Pterodactyl egg 입니다.
[K4ryuu/CS2-Egg](https://github.com/K4ryuu/CS2-Egg) (GPL-3.0) 를 기반으로 하되 포크가 아닌 독립
저장소이며, 라이선스(`LICENSE.md`)와 원저작자 표기는 그대로 둡니다.

### 원본에 더한 것

**서드파티 플러그인 자동업데이트** 하나입니다. 컨테이너가 기동할 때 cs2 가 뜨기 전에, 볼륨의
`egg/configs/plugins.json` 에 적힌 플러그인을 GitHub 최신 릴리스로 갱신합니다. 게임 서버가 아직
떠 있지 않은 시점이라 핫리로드나 재시작을 걱정할 필요가 없고 접속자도 없습니다.

CounterStrikeSharp 플러그인과 네이티브 Metamod 애드온을 모두 다룹니다. Metamod:Source 와
CounterStrikeSharp 본체는 원본 egg 가 이미 갱신하므로 여기서 다루지 않습니다.

원칙은 중요한 순서대로 다음과 같습니다.

- **fail-open.** 실패·타임아웃·레이트리밋이면 아무것도 건드리지 않고 서버를 그대로 기동합니다.
  구버전 플러그인으로 도는 편이 서버가 못 뜨는 것보다 낫습니다.
- **새로 설치하지 않습니다.** 각 항목의 `detect` 경로가 볼륨에 없으면 건너뜁니다. manifest 가
  낡아도 없던 플러그인이 깔리지 않습니다.
- **기존 설정 파일을 덮어쓰지 않습니다.** `preserve` 로 표시한 항목은 없는 파일만 채웁니다.
- **원자적 교체와 원복.** 임시 디렉터리에 받아 아카이브 구조가 manifest 와 맞는지 확인하고,
  대상을 백업한 뒤 교체합니다. 실패하면 이전 상태로 되돌리고 버전을 기록하지 않아 다음 기동에
  다시 시도합니다.
- **manifest 에 적힌 것만.** 목록에 없는 디렉터리는 손대지 않습니다.

### manifest 와 egg 변수

형식은 위 영문 절의 표를 참고하세요. 릴리스 아카이브 구조가 프로젝트마다 제각각이라
(`addons/…` 로 시작하는 것, 플러그인 디렉터리가 루트에 있는 것, 한 겹 감싸인 것, DLL 이 그냥 놓인 것)
휴리스틱으로 추론하지 않고 `map` 에 명시합니다. 업스트림이 구조를 바꾸면 업데이터는 아무것도
건드리지 않고 중단하므로, 그때 manifest 를 고치면 됩니다.

압축 형식은 파일 이름이 아니라 내용으로 판별합니다. 이름이 `.tar.gz` 인데 실제로는 gzip 이 아닌
순수 tar 인 배포본이 있기 때문입니다. 버전 비교는 semver 가 아니라 태그 문자열 비교입니다.
`build-423`, `CS2-CustomIO-v.1.DZ.16` 같은 태그가 실제로 쓰입니다.

`GITHUB_TOKEN` 을 비워 두면 비인증 한도(IP 당 시간당 60회)에 걸려 갱신이 끊깁니다. 플러그인 하나당
부팅마다 API 를 한 번 부르고, 여러 서버가 공인 IP 를 공유하면 금방 소진됩니다. 권한을 하나도 주지
않은 fine-grained PAT 면 충분합니다. `PLUGIN_UPDATE_ENABLED=0` 으로 기능 전체를 끌 수 있습니다.

egg 변수 이름·설명과 볼륨에 생성되는 `egg/configs/*.json` 은 한국어로 되어 있습니다.

### 라이선스

원본을 따라 GPL-3.0 입니다. [`LICENSE.md`](LICENSE.md) 를 보세요.
