# CS2.KR CS2 Egg

A Pterodactyl/Pelican egg and container image for Counter-Strike 2 servers, running in production at
[CS2.KR](https://cs2.kr).

Based on **[K4ryuu/CS2-Egg](https://github.com/K4ryuu/CS2-Egg)** (GPL-3.0) by K4ryuu @ KitsuneLab.
This is a standalone repository, not a fork. `LICENSE.md` and the upstream copyright notices are kept intact.

Image: `ghcr.io/cs2kr/cs2-egg:latest` · Egg: [`pterodactyl/cs2kr-cs2-egg.json`](pterodactyl/cs2kr-cs2-egg.json)

### Quick install — centralized game files (VPK sync)

Run once as root on each game node. One 55GB copy of CS2 per node instead of one per server, and new
servers boot in ~5s instead of waiting on SteamCMD.

```bash
curl -fsSL https://raw.githubusercontent.com/CS2KR/cs2-egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh \
  && sudo bash /tmp/install-cs2-update.sh
```

Re-running it is safe — it reads your current settings and offers them as defaults, so it doubles as the
repair path. Details: [Centralized game files](#centralized-game-files-vpk-sync) ·
[한국어 설명은 아래에 있습니다.](#한국어)

---

## English

### What this adds on top of upstream

**A third-party plugin auto-updater.** On container start — before `cs2` launches — the egg installs and
updates the plugins this server has enabled (`PLUGIN_<NAME>=1`) to their latest GitHub release, using the
catalog baked into the image. The game server is not running yet, so there is no hot-reload to worry about
and no players are online.

It covers native Metamod addons and SwiftlyS2 plugins. Metamod:Source and SwiftlyS2 themselves are
already kept up to date by the egg's framework updaters, so they are not managed here.
CounterStrikeSharp support was dropped on 2026-07-12.

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

### Catalog

`docker/scripts/plugins-catalog.json`, baked into the image:

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

| Field | Meaning |
|---|---|
| `name` | Key used to record the installed version in `egg/plugin-versions.txt`. |
| `detect` | Path relative to `game/csgo` that must exist for the plugin to be updated. Required. |
| `repo` | GitHub `owner/repo`. Only `releases/latest` is read. |
| `asset` | Regex matched against release asset names (jq `test()`). Must match exactly one asset. |
| `framework` | `metamod` or `swiftly`. Skipped on servers where that framework is disabled. |
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

### Centralized game files (VPK sync)

Every CS2 server on a node normally carries its own 55GB copy of the game. The centralized updater keeps
**one** copy on the host and pushes it into each server volume, so ten servers cost ~85GB instead of ~550GB
and a brand-new server boots in about five seconds instead of waiting 10–30 minutes for SteamCMD.

Two moving parts, both installed on the **host** (not in the container):

| Component | Path | Job |
|---|---|---|
| Update script | `/usr/local/bin/update-cs2-centralized.sh` | Run by cron. Updates the central copy via SteamCMD, pushes it into every existing container, optionally restarts them. |
| VPK daemon | `cs2-vpk-daemon` (systemd) | Watches Docker events. When a container starts, it pushes the files in *before* the entrypoint runs, so the new server never downloads anything. |

Nothing needs to change in the panel. No Pterodactyl mount config, no egg variable, no patched Wings —
the scripts drive Docker directly.

#### Install

Run as root on each game node:

```bash
curl -fsSL https://raw.githubusercontent.com/CS2KR/cs2-egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh \
  && sudo bash /tmp/install-cs2-update.sh
```

The installer downloads the update script, walks you through a short wizard, registers
`/etc/cron.d/cs2-update` (fires every minute; `UPDATE_CHECK_INTERVAL` decides whether a run actually does
work), installs and starts the `cs2-vpk-daemon` service, and creates `/var/log/cs2-update.log`.

It is safe to re-run: existing values are read back out of the installed script and offered as the defaults,
which makes it the fastest way to repair a broken configuration.

#### Configuration

The wizard asks for these. Everything lives at the top of `/usr/local/bin/update-cs2-centralized.sh` and can
be edited afterwards — a self-update preserves your values.

| Variable | Default | Meaning |
|---|---|---|
| `CS2_DIR` | `/srv/cs2-shared` | The one central CS2 installation. Needs ~56GB. |
| `STEAMCMD_DIR` | `/root/steamcmd` | SteamCMD location. Installed automatically if missing. |
| `VPK_PUSH_METHOD` | `symlink` | How files reach each volume. See below. |
| `AUTO_RESTART_SERVERS` | `true` | Restart matching containers after a CS2 update. |
| `VALIDATE_INSTALL` | `false` | Pass `validate` to SteamCMD every run. Slow; for repair only. |
| `AUTO_UPDATE_SCRIPT` | `true` | Self-update from this repo, keeping 3 backups in `.script-backups/`. |
| `UPDATE_CHECK_INTERVAL` | `*` | `*` = check on every cron tick. A number = minimum seconds between checks. |

**`SERVER_IMAGE` is not asked for by the wizard.** It defaults to `ghcr.io/cs2kr/cs2-egg` and decides which
containers get files pushed and restarted. If you run a different image, edit it by hand — a container whose
image is not listed is invisible to both the script and the daemon.

#### Push methods

| Method | Disk seen by panel | Writable | Requirement |
|---|---|---|---|
| `symlink` *(default)* | ~0 per server | no | Kernel 5.2+, `python3` on host. `CS2_DIR` is bind-mounted read-only into each container. |
| `hardlink` | ~53GB per server | no | `CS2_DIR` must be on the same filesystem as the panel volumes, else it falls back to `copy`. |
| `copy` | ~52GB per server | yes | none |
| `off` | — | — | Disables pushing entirely. |

`hardlink` uses no extra real disk, but Pterodactyl's quota counts the full size against every server.

#### Operating it

```bash
# One manual run. Errors with a lock message if cron is mid-run — just wait.
/usr/local/bin/update-cs2-centralized.sh

# Exercise the push/restart logic without a SteamCMD download
/usr/local/bin/update-cs2-centralized.sh --simulate

# Force a one-shot file validation for this run only
/usr/local/bin/update-cs2-centralized.sh --validate

systemctl status cs2-vpk-daemon
journalctl -u cs2-vpk-daemon -f      # daemon log
tail -f /var/log/cs2-update.log      # cron log
```

The lock is `/var/lock/cs2-update.lock`. Lock contention is normal and simply means a run is already in
flight; only remove it if a run has been dead for 30+ minutes.

Full documentation: [`docs/features/vpk-sync.md`](docs/features/vpk-sync.md). Sources:
[`misc/install-cs2-update.sh`](misc/install-cs2-update.sh),
[`misc/update-cs2-centralized.sh`](misc/update-cs2-centralized.sh).

### Differences from upstream

- Added `docker/scripts/plugin-update.sh` and `docker/scripts/updaters/thirdparty.sh`
- `misc/*.sh` now target `CS2KR/cs2-egg` and `ghcr.io/cs2kr/cs2-egg` for self-update and image matching
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

### 빠른 설치 — 게임 파일 중앙화 (VPK 동기화)

게임 노드마다 root 로 한 번만 실행하면 됩니다. 서버마다 55GB 를 갖는 대신 노드에 사본 하나만 두고,
새 서버는 SteamCMD 를 기다리지 않고 5초 만에 뜹니다.

```bash
curl -fsSL https://raw.githubusercontent.com/CS2KR/cs2-egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh \
  && sudo bash /tmp/install-cs2-update.sh
```

다시 실행해도 안전합니다. 현재 설정을 읽어 기본값으로 보여 주므로 복구용으로도 씁니다.
자세한 설명은 [게임 파일 중앙화](#게임-파일-중앙화-vpk-동기화) 에 있습니다.

### 원본에 더한 것

**서드파티 플러그인 자동업데이트** 하나입니다. 컨테이너가 기동할 때 cs2 가 뜨기 전에, 이미지에 구운
카탈로그에서 이 서버가 켠 플러그인(`PLUGIN_<NAME>=1`)을 GitHub 최신 릴리스로 설치·갱신합니다. 게임 서버가
아직 떠 있지 않은 시점이라 핫리로드나 재시작을 걱정할 필요가 없고 접속자도 없습니다.

네이티브 Metamod 애드온과 SwiftlyS2 플러그인을 다룹니다. Metamod:Source 와 SwiftlyS2 본체는
egg 가 이미 갱신하므로 여기서 다루지 않습니다. CounterStrikeSharp 지원은 2026-07-12 에 걷어냈습니다.

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

### 게임 파일 중앙화 (VPK 동기화)

한 노드의 CS2 서버는 보통 각자 55GB 짜리 게임 파일을 따로 갖습니다. 중앙 업데이트 스크립트는 호스트에
**사본 하나만** 두고 그것을 각 서버 볼륨으로 밀어 넣습니다. 서버 10대면 550GB 가 아니라 85GB 쯤 쓰고,
새 서버는 SteamCMD 다운로드로 10~30분을 기다리는 대신 5초 만에 뜹니다.

구성 요소는 둘이고, 컨테이너가 아니라 **호스트**에 설치합니다.

| 구성 요소 | 경로 | 하는 일 |
|---|---|---|
| 업데이트 스크립트 | `/usr/local/bin/update-cs2-centralized.sh` | cron 이 실행합니다. SteamCMD 로 중앙 사본을 갱신하고, 이미 있는 컨테이너마다 밀어 넣고, 필요하면 재시작합니다. |
| VPK 데몬 | `cs2-vpk-daemon` (systemd) | Docker 이벤트를 지켜봅니다. 컨테이너가 뜨면 entrypoint 가 돌기 **전에** 파일을 밀어 넣어, 새 서버가 아무것도 내려받지 않게 합니다. |

패널은 손댈 필요가 없습니다. Pterodactyl Mount 설정도, egg 변수도, Wings 패치도 필요 없습니다.
스크립트가 Docker 를 직접 다룹니다.

#### 설치

게임 노드마다 root 로 실행합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/CS2KR/cs2-egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh \
  && sudo bash /tmp/install-cs2-update.sh
```

설치 스크립트는 업데이트 스크립트를 내려받고, 짧은 마법사로 설정을 묻고, `/etc/cron.d/cs2-update` 를
등록하고(매분 실행되지만 실제로 일을 할지는 `UPDATE_CHECK_INTERVAL` 이 정합니다), `cs2-vpk-daemon`
서비스를 설치·기동하고, `/var/log/cs2-update.log` 를 만듭니다.

다시 실행해도 안전합니다. 이미 설치된 스크립트에서 현재 값을 읽어 기본값으로 보여 주므로, 설정이
망가졌을 때 되돌리는 가장 빠른 방법이기도 합니다.

#### 설정 값

마법사가 묻는 항목입니다. 전부 `/usr/local/bin/update-cs2-centralized.sh` 상단에 있고 나중에 직접 고쳐도
됩니다. 스크립트가 자기 자신을 갱신할 때 이 값들은 보존합니다.

| 변수 | 기본값 | 뜻 |
|---|---|---|
| `CS2_DIR` | `/srv/cs2-shared` | 중앙 CS2 설치본. 약 56GB 가 필요합니다. |
| `STEAMCMD_DIR` | `/root/steamcmd` | SteamCMD 위치. 없으면 알아서 설치합니다. |
| `VPK_PUSH_METHOD` | `symlink` | 볼륨으로 밀어 넣는 방식. 아래를 보세요. |
| `AUTO_RESTART_SERVERS` | `true` | CS2 갱신 뒤 해당 컨테이너를 재시작합니다. |
| `VALIDATE_INSTALL` | `false` | 매 실행마다 SteamCMD `validate` 를 겁니다. 느리므로 복구용입니다. |
| `AUTO_UPDATE_SCRIPT` | `true` | 이 저장소에서 자기 자신을 갱신하고 `.script-backups/` 에 백업 3개를 남깁니다. |
| `UPDATE_CHECK_INTERVAL` | `*` | `*` 는 cron 이 돌 때마다 확인. 숫자면 최소 간격(초). |

**`SERVER_IMAGE` 은 마법사가 묻지 않습니다.** 기본값은 `ghcr.io/cs2kr/cs2-egg` 이고, 어떤 컨테이너에
파일을 밀어 넣고 재시작할지를 이 값이 정합니다. 다른 이미지를 쓴다면 직접 고쳐야 합니다. 목록에 없는
이미지의 컨테이너는 스크립트에도 데몬에도 보이지 않습니다.

#### 밀어 넣는 방식

| 방식 | 패널이 보는 용량 | 쓰기 | 조건 |
|---|---|---|---|
| `symlink` *(기본)* | 서버당 거의 0 | 불가 | 커널 5.2+, 호스트에 `python3`. `CS2_DIR` 이 읽기 전용으로 바인드 마운트됩니다. |
| `hardlink` | 서버당 약 53GB | 불가 | `CS2_DIR` 이 패널 볼륨과 같은 파일시스템이어야 합니다. 아니면 `copy` 로 물러납니다. |
| `copy` | 서버당 약 52GB | 가능 | 없음 |
| `off` | — | — | 밀어 넣기를 끕니다. |

`hardlink` 는 실제 디스크를 더 쓰지는 않지만, Pterodactyl 의 디스크 쿼터는 서버마다 전체 용량으로 셉니다.

#### 운영

```bash
# 수동으로 한 번 실행. cron 이 도는 중이면 잠금 메시지가 납니다. 기다렸다 다시 하세요.
/usr/local/bin/update-cs2-centralized.sh

# SteamCMD 다운로드 없이 밀어 넣기·재시작 로직만 시험
/usr/local/bin/update-cs2-centralized.sh --simulate

# 이번 실행에만 파일 무결성 검사를 겁니다
/usr/local/bin/update-cs2-centralized.sh --validate

systemctl status cs2-vpk-daemon
journalctl -u cs2-vpk-daemon -f      # 데몬 로그
tail -f /var/log/cs2-update.log      # cron 로그
```

잠금 파일은 `/var/lock/cs2-update.lock` 입니다. 잠금 충돌은 정상이며 이미 실행 중이라는 뜻입니다.
30분 넘게 멈춰 있는 게 확실할 때만 지우세요.

자세한 설명은 [`docs/features/vpk-sync.md`](docs/features/vpk-sync.md) 에 있습니다. 소스는
[`misc/install-cs2-update.sh`](misc/install-cs2-update.sh),
[`misc/update-cs2-centralized.sh`](misc/update-cs2-centralized.sh) 입니다.

### 라이선스

원본을 따라 GPL-3.0 입니다. [`LICENSE.md`](LICENSE.md) 를 보세요.
