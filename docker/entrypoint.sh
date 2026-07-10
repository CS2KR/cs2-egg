#!/bin/bash

# wipe stale marker first thing — must happen before daemon's start event lands
rm -f /home/container/egg/.daemon-managed 2>/dev/null || true

source /utils/logging.sh
source /utils/config.sh
source /scripts/install.sh
source /scripts/sync.sh
source /scripts/cleanup.sh
source /scripts/update.sh
source /scripts/filter.sh
source /scripts/update_helper.sh

# Enhanced error handling
trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR

cd /home/container

# Initialize and load configurations
init_configs
load_configs

# Get internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $NF;exit}')

detect_daemon_vpk
cleanup_daemon_mode

# Legacy VPK sync (SYNC_LOCATION mode) - runs before daemon detection result check
if [ ${SRCDS_STOP_UPDATE:-0} -eq 0 ]; then
    sync_files
    sync_cfg_files
fi

# SteamCMD install and cleanup (skip if VPKs managed externally)
if [ ${SRCDS_STOP_UPDATE:-0} -eq 0 ]; then
    install_steamcmd
fi

rotate_logs

# Server update process
if [ -n "${SRCDS_APPID}" ] && [ "${SRCDS_STOP_UPDATE:-0}" -eq 0 ]; then
    # Build SteamCMD command from optional parts — login, beta, validate.
    STEAMCMD="./steamcmd/steamcmd.sh"

    if [ -n "${SRCDS_LOGIN}" ]; then
        STEAMCMD+=" +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS}"
    else
        STEAMCMD+=" +login anonymous"
    fi

    STEAMCMD+=" +force_install_dir /home/container +app_update ${SRCDS_APPID}"

    if [ -n "${SRCDS_BETAID}" ]; then
        STEAMCMD+=" -beta ${SRCDS_BETAID}"
        if [ -n "${SRCDS_BETAPASS}" ]; then
            STEAMCMD+=" -betapassword ${SRCDS_BETAPASS}"
        fi
    fi

    if [ "${SRCDS_VALIDATE}" -eq 1 ]; then
        STEAMCMD+=" validate"
        log_message "!!! 검증이 켜져 있습니다. 커스텀 설정이 지워질 수 있습니다!" "warning"
        log_message "  → 5초 뒤 시작합니다. 중단하려면 지금 서버를 정지하세요." "warning"
        sleep 5
    fi

    STEAMCMD+=" +quit"

    log_message "SteamCMD 명령: $(echo "$STEAMCMD" | sed -E 's/(\+login [^ ]+ )[^ ]+/\1****/')" "debug"

    trap - ERR
    eval ${STEAMCMD}
    STEAM_EXIT_CODE=$?
    trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR

    if [ $STEAM_EXIT_CODE -eq 8 ]; then
        log_error_code "KL-STM-01" "SteamCMD 접속 오류입니다 (종료 코드 8)"
    elif [ $STEAM_EXIT_CODE -ne 0 ]; then
        log_error_code "KL-STM-02" "SteamCMD 가 종료 코드 $STEAM_EXIT_CODE 로 실패했습니다"
    fi

    # Update steamclient.so files
    cp -f ./steamcmd/linux32/steamclient.so ./.steam/sdk32/steamclient.so
    cp -f ./steamcmd/linux64/steamclient.so ./.steam/sdk64/steamclient.so
fi

# Handle the addon installations based on the selection
update_addons

# Set up console filter
setup_message_filter

# Build the actual startup command from template
MODIFIED_STARTUP=$(eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g'))

log_message "서버를 시작합니다: ${MODIFIED_STARTUP}" "info"

# GDB mode: use Valve's built-in GAME_DEBUGGER support (cs2.sh line 106)
# gdbserver launches cs2 as parent process, so no SYS_PTRACE capability needed
if [ -n "${GDB_DEBUG_PORT}" ] && [ "${GDB_DEBUG_PORT}" != "0" ]; then
    export GAME_DEBUGGER="gdbserver --no-disable-randomization :${GDB_DEBUG_PORT}"
    log_message "GDB 모드: 서버가 포트 ${GDB_DEBUG_PORT} 의 gdbserver 아래에서 시작합니다" "info"
    log_message "디버거가 접속할 때까지 서버가 기다립니다" "warning"
fi

# Actually start the server and handle its output
START_CMD="script -qfc \"$MODIFIED_STARTUP\" /dev/null 2>&1"

eval "$START_CMD" | while IFS= read -r line; do
    line="${line%[[:space:]]}"
    [[ "$line" =~ Segmentation\ fault.*"${GAMEEXE}" ]] && continue

    # Detect crash via cs2.sh crash message pattern
    if [[ "$line" =~ \./game/cs2\.sh:.*Aborted.*\(core\ dumped\) ]]; then
        handle_server_output "$line"
        log_warn_code "KL-SRV-01" "서버 크래시를 감지했습니다" \
            "위 스택 트레이스에서 어느 모듈이 죽었는지 확인하세요" \
            "흔한 원인은 오래된 애드온, 플러그인 충돌, 낡은 gamedata 입니다"
        continue
    fi

    # GSLT token rejection — CS2 spams these lines, append our hint after each so it
    # pairs up visually in the log regardless of where the user scrolls.
    if [[ "$line" == *"Cert request for invalid failed"* ]] || \
       [[ "$line" == *"We're not logged into Steam"* ]]; then
        handle_server_output "$line"
        log_warn_code "KL-SRV-02" "Steam GSLT 토큰이 잘못됐거나 만료됐습니다" \
            "https://steamcommunity.com/dev/managegameservers 에서 App ID 730 으로 재발급하세요" \
            "패널의 시작 변수 STEAM_ACC 를 바꾼 뒤 서버를 다시 시작하세요"
        continue
    fi

    handle_server_output "$line"
done

# Clean up any background processes we started
pkill -P $$ 2>/dev/null || true

log_message "서버가 정지했습니다" "info"