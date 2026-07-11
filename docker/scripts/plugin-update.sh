#!/bin/bash
# CS2 기동 직전에 서드파티 플러그인을 GitHub 최신 릴리스로 갱신·설치한다.
# 플러그인 목록은 이미지에 구운 카탈로그(/scripts/plugins-catalog.json)를 쓰고,
# 무엇을 켤지는 egg 변수로 정한다 — 각 플러그인의 PLUGIN_<NAME>(0/1) + 프레임워크
# 게이팅(metamod=INSTALL_METAMOD, css=INSTALL_CSS, swiftly=INSTALL_SWIFTLY 가 1일 때만).
# Metamod:Source 본체와 CSS/SwiftlyS2 본체는 egg 가 따로 갱신한다.

set -uo pipefail

CONTAINER_DIR="${CONTAINER_DIR:-/home/container}"
GAME_DIR="$CONTAINER_DIR/game/csgo"
EGG_DIR="$CONTAINER_DIR/egg"
CATALOG="${PLUGIN_CATALOG:-/scripts/plugins-catalog.json}"
VERSION_FILE="$EGG_DIR/plugin-versions.txt"
DRY_RUN="${PLUGIN_UPDATE_DRY_RUN:-0}"
API="${GITHUB_API:-https://api.github.com}"

log() { printf '[plugin-update] %s\n' "$*"; }

[ -f "$CATALOG" ] || { log "카탈로그 없음 ($CATALOG) — 건너뜁니다"; exit 0; }
for t in jq curl unzip tar rsync; do
    command -v "$t" >/dev/null || { log "$t 없음 — 건너뜁니다"; exit 0; }
done

# /tmp 은 컨테이너에서 작은 tmpfs(100MB)라, WeaponSkins 같은 큰 zip(33MB+압축해제)이 누적되면
# 넘쳐 curl 23(쓰기 실패)이 난다. 넉넉한 볼륨(/home/container)에 임시 디렉터리를 만든다.
mkdir -p "$EGG_DIR" 2>/dev/null
TMP=$(mktemp -d "$EGG_DIR/.plugin-update.XXXXXX" 2>/dev/null) || TMP=$(mktemp -d) \
    || { log "임시 디렉터리 생성 실패 — 건너뜁니다"; exit 0; }
trap 'rm -rf "$TMP"' EXIT

# 응답 본문을 $2 에 쓰고 HTTP 상태 코드를 찍는다.
# GITHUB_TOKEN 이 있으면 시간당 5000회, 없으면 IP당 60회로 제한된다.
# 한 노드에서 서버 여러 대가 동시에 재기동하면 60회는 쉽게 넘는다 → egg 변수로 토큰을 넣을 것.
curl_gh() {
    local auth=()
    [ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
    curl -sS -m 30 -o "$2" -w '%{http_code}' \
        -H "Accept: application/vnd.github+json" "${auth[@]}" "$1" 2>/dev/null
}

installed_version() { [ -f "$VERSION_FILE" ] && grep "^$1=" "$VERSION_FILE" | head -1 | cut -d= -f2-; }

record_version() {
    touch "$VERSION_FILE"
    if grep -q "^$1=" "$VERSION_FILE"; then
        sed -i "s|^$1=.*|$1=$2|" "$VERSION_FILE"
    else
        printf '%s=%s\n' "$1" "$2" >>"$VERSION_FILE"
    fi
}

# map 항목을 "from<TAB>to<TAB>preserve" 줄로 펼친다.
# jq 의 `//` 는 좌변이 false 여도 우변을 쓴다. 불리언에는 절대 쓰지 말 것.
map_rows() { jq -r '.map[] | [.from, .to, (.preserve == true | tostring)] | @tsv' <<<"$1"; }

# 확장자가 아니라 내용으로 압축 형식을 판별한다.
# zer0k-z/sql_mm 의 'package-linux.tar.gz' 는 이름과 달리 gzip 이 아닌 순수 tar 다.
extract() {
    local archive=$1 dest=$2
    if unzip -tqq "$archive" >/dev/null 2>&1; then
        unzip -qq -o "$archive" -d "$dest"
    elif tar -tf "$archive" >/dev/null 2>&1; then
        tar -xf "$archive" -C "$dest"   # GNU tar 는 gzip 여부를 알아서 판별한다
    else
        return 1
    fi
}

# 다운로드 → 검증 → 백업 → 교체. 실패하면 원복하고 1을 반환한다.
apply_plugin() {
    local name=$1 url=$2 spec=$3
    local work="$TMP/$name" stage="$TMP/$name/stage" bak="$TMP/$name/backup"
    local from to preserve

    mkdir -p "$stage" "$bak"
    curl -fsSL -m 300 -A "Mozilla/5.0" -o "$work/pkg" "$url" || { log "$name: 다운로드 실패"; return 1; }
    [ -s "$work/pkg" ] || { log "$name: 받은 파일이 비어 있음"; return 1; }
    extract "$work/pkg" "$stage" || { log "$name: 압축 해제 실패"; return 1; }

    # zip 구조가 manifest와 어긋나면 아무것도 건드리지 않고 중단한다
    while IFS=$'\t' read -r from to preserve; do
        [ -e "$stage/$from" ] || { log "$name: zip에 '$from' 이 없음 — 중단"; return 1; }
    done < <(map_rows "$spec")

    while IFS=$'\t' read -r from to preserve; do
        if [ -e "$GAME_DIR/$to" ]; then
            mkdir -p "$bak/$(dirname "$to")"
            cp -a "$GAME_DIR/$to" "$bak/$to" || { log "$name: 백업 실패 — 중단"; return 1; }
        fi
    done < <(map_rows "$spec")

    local ok=1
    while IFS=$'\t' read -r from to preserve; do
        mkdir -p "$GAME_DIR/$to"
        if [ "$preserve" = "true" ]; then
            # 설정 트리 — 없는 파일만 채우고 기존 파일은 그대로 둔다
            rsync -a --ignore-existing "$stage/$from/" "$GAME_DIR/$to/" || { ok=0; break; }
        else
            rsync -a "$stage/$from/" "$GAME_DIR/$to/" || { ok=0; break; }
        fi
    done < <(map_rows "$spec")

    if [ "$ok" -ne 1 ]; then
        log "$name: 적용 실패 — 원복합니다"
        while IFS=$'\t' read -r from to preserve; do
            if [ -e "$bak/$to" ]; then
                rm -rf "${GAME_DIR:?}/$to"
                cp -a "$bak/$to" "$GAME_DIR/$to"
            fi
        done < <(map_rows "$spec")
        return 1
    fi
    return 0
}

updated=0 skipped=0 failed=0 ratelimited=0

while IFS= read -r spec; do
    name=$(jq -r '.name' <<<"$spec")

    # 카탈로그 레벨 킬 스위치 (`.enabled // true` 는 false 를 true 로 뒤집으니 != false 로).
    if [ "$(jq -r '.enabled != false' <<<"$spec")" != "true" ]; then
        log "$name: 카탈로그에서 비활성"
        continue
    fi

    # 프레임워크 게이팅 — 해당 프레임워크가 꺼져 있으면 이 플러그인은 설치하지 않는다.
    framework=$(jq -r '.framework // "css"' <<<"$spec")
    case "$framework" in
        metamod) fw_on="${INSTALL_METAMOD:-0}" ;;
        css)     fw_on="${INSTALL_CSS:-0}" ;;
        swiftly) fw_on="${INSTALL_SWIFTLY:-0}" ;;
        *)       fw_on=0 ;;
    esac
    if [ "$fw_on" != "1" ]; then
        log "$name: $framework 프레임워크 꺼짐 — 건너뜁니다"
        continue
    fi

    # 플러그인별 egg 변수(PLUGIN_<NAME>)로 서버별 on/off. 1 이 아니면 설치·갱신 안 함.
    env=$(jq -r '.env // empty' <<<"$spec")
    plugin_on=0
    [ -n "$env" ] && plugin_on="${!env:-0}"
    if [ "$plugin_on" != "1" ]; then
        log "$name: 꺼짐 (${env:-env없음}=$plugin_on) — 건너뜁니다"
        continue
    fi

    # 여기까지 왔으면 이 서버에서 켠 플러그인. 없으면 새로 설치하고 있으면 안전 갱신한다.
    # apply_plugin 이 map 대상에 rsync 병합하므로 설치와 갱신은 같은 경로다.
    detect=$(jq -r '.detect // ("addons/counterstrikesharp/plugins/" + .name)' <<<"$spec")
    if [ ! -e "$GAME_DIR/$detect" ]; then
        log "$name: 미설치 — 새로 설치합니다"
    fi

    repo=$(jq -r '.repo' <<<"$spec")
    asset_re=$(jq -r '.asset' <<<"$spec")

    status=$(curl_gh "$API/repos/$repo/releases/latest" "$TMP/release.json")
    case "$status" in
        200) ;;
        403 | 429)
            # 한 번 걸리면 남은 것도 전부 막힌다. 이번 부팅은 여기서 접는다.
            log "$name: GitHub API 레이트리밋 (HTTP $status) — 이번 부팅의 갱신을 중단합니다"
            log "  → GITHUB_TOKEN 을 설정하면 시간당 5000회로 늘어납니다"
            ratelimited=1
            break
            ;;
        *)
            log "$name: 릴리스 조회 실패 (HTTP $status, $repo) — 현재 버전 유지"
            failed=$((failed + 1))
            continue
            ;;
    esac

    release=$(cat "$TMP/release.json")
    tag=$(jq -r '.tag_name // empty' <<<"$release")
    url=$(jq -r --arg re "$asset_re" \
        '[.assets[] | select(.name | test($re))][0].browser_download_url // empty' <<<"$release")

    if [ -z "$tag" ] || [ -z "$url" ]; then
        log "$name: 태그 또는 에셋($asset_re)을 찾지 못함 — 현재 버전 유지"
        failed=$((failed + 1))
        continue
    fi

    current=$(installed_version "$name")
    if [ "$current" = "$tag" ]; then
        log "$name: 최신 ($tag)"
        skipped=$((skipped + 1))
        continue
    fi

    log "$name: ${current:-미기록} → $tag"
    if [ "$DRY_RUN" = "1" ]; then
        updated=$((updated + 1))
        continue
    fi

    if apply_plugin "$name" "$url" "$spec"; then
        record_version "$name" "$tag"
        log "$name: 갱신 완료 ($tag)"
        updated=$((updated + 1))
    else
        failed=$((failed + 1))
    fi
done < <(jq -c '.plugins[]' "$CATALOG")

log "갱신 $updated · 최신 $skipped · 실패 $failed"
[ "$failed" -eq 0 ] && [ "$ratelimited" -eq 0 ]
