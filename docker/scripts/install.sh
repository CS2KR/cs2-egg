#!/bin/bash
source /utils/logging.sh

install_steamcmd() {
    if [ -f "./steamcmd/steamcmd.sh" ]; then
        log_message "SteamCMD 가 이미 설치돼 있습니다" "debug"
        return 0
    fi

    log_message "SteamCMD 를 설치합니다..." "info"
    local STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
    local max_retries=3
    local retry=0

    # Create necessary directories
    mkdir -p ./steamcmd
    mkdir -p ./steamapps

    # Download with retry
    while [ $retry -lt $max_retries ]; do
        if curl -sSL --connect-timeout 30 --max-time 300 -o steamcmd.tar.gz "$STEAMCMD_URL"; then
            break
        fi
        ((retry++))
        log_message "다운로드 실패 ($retry/$max_retries 번째 시도)" "warning"
        sleep 5
    done

    if [ $retry -eq $max_retries ]; then
        log_error_code "KL-STM-05" "$max_retries 번 시도했지만 SteamCMD 를 내려받지 못했습니다"
        return 1
    fi

    # Extract steamcmd
    if ! tar -xzvf steamcmd.tar.gz -C ./steamcmd; then
        log_error_code "KL-STM-06" "SteamCMD 압축을 풀지 못했습니다"
        return 1
    fi
    rm steamcmd.tar.gz
    # Set up required environment
    if [ ! -d "./steamcmd" ]; then
        log_error_code "KL-STM-07" "steamcmd 디렉터리가 없습니다"
        return 1
    fi

    # Initialize steamcmd
    ./steamcmd/steamcmd.sh +quit

    # Set up 32-bit libraries
    mkdir -p ./.steam/sdk32
    cp -v ./steamcmd/linux32/steamclient.so ./.steam/sdk32/steamclient.so || {
        log_message "32비트 라이브러리를 복사하지 못했습니다" "warning"
    }

    # Set up 64-bit libraries
    mkdir -p ./.steam/sdk64
    cp -v ./steamcmd/linux64/steamclient.so ./.steam/sdk64/steamclient.so || {
        log_message "64비트 라이브러리를 복사하지 못했습니다" "warning"
    }

    log_message "SteamCMD 를 설치했습니다" "success"
    return 0
}