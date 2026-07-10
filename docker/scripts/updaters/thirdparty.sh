#!/bin/bash
# CS2.KR: egg/configs/plugins.json 에 적힌 서드파티 플러그인을 cs2 기동 전에 갱신하는 얇은 래퍼
#
# 실제 로직은 /scripts/plugin-update.sh 에 있다. 여기서는 활성화 여부·타임아웃·fail-open 만 다룬다.
# 업데이터가 실패하든 멈추든 서버는 반드시 뜬다 — 구버전 플러그인으로 도는 편이 못 뜨는 것보다 낫다.

update_thirdparty_plugins() {
    local manifest="/home/container/egg/configs/plugins.json"

    if [ "${PLUGIN_UPDATE_ENABLED:-1}" != "1" ]; then
        log_message "Third-party plugin updater disabled (PLUGIN_UPDATE_ENABLED=0)" "debug"
        return 0
    fi

    if [ ! -f "$manifest" ]; then
        log_message "No third-party plugin manifest at $manifest, skipping" "debug"
        return 0
    fi

    log_message "Updating third-party plugins..." "info"

    if ! timeout "${PLUGIN_UPDATE_TIMEOUT:-300}" bash /scripts/plugin-update.sh; then
        log_message "Third-party plugin update failed or timed out — starting with existing plugins" "warning"
    fi

    return 0
}
