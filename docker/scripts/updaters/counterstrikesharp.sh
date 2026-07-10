#!/bin/bash
# CounterStrikeSharp Auto-Update Script
# Downloads and installs CounterStrikeSharp from GitHub releases

source /utils/logging.sh
source /utils/updater_common.sh

update_counterstrikesharp() {
    local OUTPUT_DIR="./game/csgo/addons"
    local REPO="roflmuffin/CounterStrikeSharp"
    local temp_dir="$TEMP_DIR/css"

    mkdir -p "$OUTPUT_DIR" "$temp_dir"
    rm -rf "$temp_dir"/*

    local release_info
    release_info=$(get_github_release "$REPO" "-with-runtime-linux-.*\\.zip$")

    # Validate JSON response
    if [ -z "$release_info" ] || ! echo "$release_info" | jq -e . >/dev/null 2>&1; then
        log_message "$REPO 의 릴리스 정보를 가져오지 못했습니다" "error"
        return 1
    fi

    local new_version=$(echo "$release_info" | jq -r '.version // empty')
    local asset_url=$(echo "$release_info" | jq -r '.asset_url // empty')
    local current_version=$(get_current_version "CSS")

    if [ -z "$new_version" ]; then
        log_message "$REPO 의 버전을 읽지 못했습니다" "error"
        return 0
    fi

    # Check if update is needed
    if [ -n "$current_version" ]; then
        semver_compare "$new_version" "$current_version"
        case $? in
            0) # Equal
                log_message "CounterStrikeSharp 는 최신입니다 ($current_version)" "success"
                return 0
                ;;
            2) # new < current
                log_message "CounterStrikeSharp 가 최신 릴리스($new_version)보다 새 버전($current_version)입니다. 다운그레이드하지 않습니다." "info"
                return 0
                ;;
        esac
    fi

    if [ -z "$asset_url" ]; then
        log_message "$REPO 에서 알맞은 에셋을 찾지 못했습니다" "error"
        return 0
    fi

    log_message "CounterStrikeSharp 갱신: $new_version (현재: ${current_version:-없음})" "info"

    if handle_download_and_extract "$asset_url" "$temp_dir/download.zip" "$temp_dir" "zip"; then
        cp -r "$temp_dir/addons/." "$OUTPUT_DIR" && \
        update_version_file "CSS" "$new_version" && \
        log_message "CounterStrikeSharp 를 $new_version 으로 갱신했습니다" "success"
        return 0
    fi

    return 1
}

# Main function
main() {
    mkdir -p "$TEMP_DIR"
    update_counterstrikesharp
    return $?
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
