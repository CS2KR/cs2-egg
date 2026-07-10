#!/bin/bash
# SwiftlyS2 Auto-Update Script
# Downloads and installs SwiftlyS2 from GitHub releases

source /utils/logging.sh
source /utils/updater_common.sh

# Update Swiftly
update_swiftly() {
    local OUTPUT_DIR="./game/csgo/addons"
    local REPO="swiftly-solution/swiftlys2"
    local temp_dir="$TEMP_DIR/swiftly"

    mkdir -p "$OUTPUT_DIR" "$temp_dir"
    rm -rf "$temp_dir"/*

    local release_info
    release_info=$(get_github_release "$REPO" "linux.*with-runtimes\\.zip")

    # Validate JSON response
    if [ -z "$release_info" ] || ! echo "$release_info" | jq -e . >/dev/null 2>&1; then
        log_message "$REPO 의 릴리스 정보를 가져오지 못했습니다" "error"
        return 1
    fi

    local new_version=$(echo "$release_info" | jq -r '.version // empty')
    local asset_url=$(echo "$release_info" | jq -r '.asset_url // empty')
    local current_version=$(get_current_version "Swiftly")

    if [ -z "$new_version" ]; then
        log_message "$REPO 의 버전을 읽지 못했습니다" "error"
        return 0
    fi

    # Check if update is needed
    if [ -n "$current_version" ]; then
        semver_compare "$new_version" "$current_version"
        case $? in
            0) # Equal
                log_message "SwiftlyS2 는 최신입니다 ($current_version)" "success"
                return 0
                ;;
            2) # new < current
                log_message "SwiftlyS2 가 최신 릴리스($new_version)보다 새 버전($current_version)입니다. 다운그레이드하지 않습니다." "info"
                return 0
                ;;
        esac
    fi

    if [ -z "$asset_url" ]; then
        log_message "$REPO 에서 알맞은 에셋을 찾지 못했습니다" "error"
        return 0
    fi

    log_message "SwiftlyS2 갱신: $new_version (현재: ${current_version:-없음})" "info"

    if handle_download_and_extract "$asset_url" "$temp_dir/download.zip" "$temp_dir" "zip"; then
        # Find swiftlys2 directory (handles versioned top-level folders)
        local swiftly_dir=$(find "$temp_dir" -type d -name "swiftlys2" -path "*/addons/swiftlys2" | head -n1)

        if [ -n "$swiftly_dir" ] && [ -d "$swiftly_dir" ]; then
            local target_dir="$OUTPUT_DIR/swiftlys2"

            if [ -d "$target_dir" ]; then
                # Update: only overwrite bin/ and gamedata/ (preserve user configs and plugins)
                cp -rf "$swiftly_dir/bin" "$target_dir/" && \
                cp -rf "$swiftly_dir/gamedata" "$target_dir/" && \
                log_message "SwiftlyS2 를 $new_version 으로 갱신했습니다 (bin + gamedata)" "success"
            else
                # Fresh install: copy everything
                cp -rn "$swiftly_dir" "$OUTPUT_DIR/" && \
                log_message "SwiftlyS2 $new_version 을(를) 설치했습니다" "success"
            fi

            update_version_file "Swiftly" "$new_version"
            return 0
        else
            log_message "아카이브에 SwiftlyS2 디렉터리가 없습니다" "error"
            return 1
        fi
    fi

    return 1
}

# Main function
main() {
    mkdir -p "$TEMP_DIR"
    update_swiftly
    return $?
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
