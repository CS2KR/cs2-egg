#!/bin/bash
# MetaMod Auto-Update Script
# Downloads from GitHub releases only

source /utils/logging.sh
source /utils/updater_common.sh

update_metamod() {
    local OUTPUT_DIR="./game/csgo/addons"

    if [ ! -d "$OUTPUT_DIR/metamod" ]; then
        log_message "Metamod 를 설치합니다..." "info"
    fi

    # MetaMod CS2 builds are prerelease on GitHub - always use prerelease channel
    local release
    release=$(PRERELEASE=1 get_github_release "alliedmodders/metamod-source" "linux\.tar\.gz$")
    if [ -z "$release" ]; then
        log_message "GitHub 에서 Metamod 릴리스 정보를 가져오지 못했습니다" "error"
        return 1
    fi

    local asset_url asset_name new_version
    asset_url=$(echo "$release" | jq -r '.asset_url')
    asset_name=$(echo "$release" | jq -r '.asset_name')

    if [ -z "$asset_url" ] || [ "$asset_url" = "null" ]; then
        log_message "Metamod 릴리스에 리눅스 에셋이 없습니다" "error"
        return 1
    fi

    # Extract git build number from asset filename (e.g. mmsource-2.0.0-git1391-linux.tar.gz)
    new_version=$(echo "$asset_name" | grep -o 'git[0-9]\+')
    if [ -z "$new_version" ]; then
        log_message "에셋 이름에서 Metamod 버전을 읽지 못했습니다: $asset_name" "error"
        return 1
    fi

    local current_version
    current_version=$(get_current_version "Metamod")

    if [ -n "$current_version" ]; then
        semver_compare "$new_version" "$current_version"
        case $? in
            0)
                log_message "Metamod 는 최신입니다 ($current_version)" "success"
                return 0
                ;;
            2)
                log_message "Metamod 가 최신 릴리스($new_version)보다 새 버전($current_version)입니다. 다운그레이드하지 않습니다." "info"
                return 0
                ;;
        esac
    fi

    log_message "Metamod 갱신: $new_version (현재: ${current_version:-없음})" "info"

    if handle_download_and_extract "$asset_url" "$TEMP_DIR/metamod.tar.gz" "$TEMP_DIR/metamod" "tar.gz"; then
        cp -rf "$TEMP_DIR/metamod/addons/." "$OUTPUT_DIR/" && \
        update_version_file "Metamod" "$new_version" && \
        log_message "Metamod 를 $new_version 으로 갱신했습니다" "success"
        return 0
    fi

    return 1
}

main() {
    mkdir -p "$TEMP_DIR"
    update_metamod
    return $?
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
