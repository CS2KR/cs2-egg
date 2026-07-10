#!/bin/bash

source /utils/logging.sh

# ! TODO: Remove SYNC_LOCATION fallback after 2026-10-01 (legacy sync deprecated)

# Priority: daemon > SYNC_LOCATION > SteamCMD
# Sets SRCDS_STOP_UPDATE=1 if daemon ready, else falls through.
detect_daemon_vpk() {
    # SRCDS_STOP_UPDATE=1 is a panel-level flag for disabling SteamCMD, NOT for
    # skipping daemon detection. Daemon path must always run.
    # entrypoint.sh deletes the marker at boot, so marker presence = fresh daemon push
    local marker="/home/container/egg/.daemon-managed"
    local wait_max_secs="${DAEMON_WAIT_MAX_SECS:-30}"
    local announce_after_secs="${DAEMON_WAIT_SECS:-2}"
    local announce_ticks=$((announce_after_secs * 10))

    _vpk_info() {
        local n s
        n=$(find -L /home/container/game/csgo -maxdepth 3 -name "*.vpk" -type f 2>/dev/null | wc -l)
        s=$(find -L /home/container/game/csgo -maxdepth 3 -name "*.vpk" -type f -printf "%s\n" 2>/dev/null \
            | awk '{s+=$1} END {printf "%.1f GB", s/1073741824}')
        echo "${n} files, ${s}"
    }

    # wait for daemon to touch marker (= push done)
    if [ ! -f "$marker" ]; then
        local t=0 max_t=$((wait_max_secs * 10)) announced=false
        while [ ! -f "$marker" ]; do
            [ "$t" -ge "$max_t" ] && break
            sleep 0.1
            ((t++)) || true
            if ! $announced && [ "$t" -ge "$announce_ticks" ]; then
                log_message "데몬이 푸시를 마칠 때까지 기다립니다..." "running"
                announced=true
            fi
        done
    fi

    if [ ! -f "$marker" ]; then
        if [ "${SYNC_LOCATION+defined}" = "defined" ]; then
            log_message "⚠️  더 이상 쓰이지 않는 설정입니다 ⚠️" "warning"
            log_message "SYNC_LOCATION 은 2026-10-01 이후 제거됩니다!" "warning"
            log_message "  → 최신 egg 를 import 하면 자동으로 정리됩니다." "warning"
            log_message "  → 데몬 설치: curl -fsSL https://raw.githubusercontent.com/CS2KR/cs2-egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh && sudo bash /tmp/install-cs2-update.sh" "warning"
        fi
        return 0
    fi

    export DAEMON_EVIDENCE_FOUND=1
    if [ "${SYNC_LOCATION+defined}" = "defined" ]; then
        log_message "데몬을 감지했습니다 — 폐기된 SYNC_LOCATION 변수를 무시합니다" "info"
        log_message "  → 이 안내를 없애려면 시작 변수에서 SYNC_LOCATION 을 지우세요" "info"
    fi

    log_message "데몬이 관리합니다 ($(_vpk_info))" "info"
    SRCDS_STOP_UPDATE=1
}

# Remove local SteamCMD artifacts when daemon is authoritative — saves ~200MB + cleans
# stale dirs left over from a previous non-daemon boot.
cleanup_daemon_mode() {
    [ "${SRCDS_STOP_UPDATE:-0}" -eq 1 ] || return 0

    # steamcmd/ is the big one (~200MB); Steam/ and steamapps/ are smaller leftovers
    # with no purpose in daemon mode (game files come from the shared CS2_DIR mount).
    local targets=(
        /home/container/steamcmd
        /home/container/Steam
        /home/container/steamapps
    )
    local existing=()
    for t in "${targets[@]}"; do
        if [ -e "$t" ]; then
            existing+=("$t")
        fi
    done

    if [ ${#existing[@]} -eq 0 ]; then
        return 0
    fi

    log_message "데몬 모드입니다 — 낡은 파일 ${#existing[@]} 개를 지웁니다" "info"
    rm -rf "${existing[@]}" 2>/dev/null || true
}

export -f detect_daemon_vpk cleanup_daemon_mode
