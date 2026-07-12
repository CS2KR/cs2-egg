#!/bin/bash
# CS2.KR: 서드파티 플러그인을 cs2 기동 전에 갱신하는 얇은 래퍼
#
# 실제 로직은 /scripts/plugin-update.sh 에 있다. 목록은 이미지에 구운 카탈로그를 쓰고
# 무엇을 켤지는 egg 변수(PLUGIN_<NAME>)로 정한다. 여기서는 활성화 여부·타임아웃·fail-open 만 다룬다.
# 업데이터가 실패하든 멈추든 서버는 반드시 뜬다 — 구버전 플러그인으로 도는 편이 못 뜨는 것보다 낫다.

update_thirdparty_plugins() {
    if [ "${PLUGIN_UPDATE_ENABLED:-1}" != "1" ]; then
        log_message "서드파티 플러그인 자동업데이트가 꺼져 있습니다 (PLUGIN_UPDATE_ENABLED=0)" "debug"
        return 0
    fi

    log_message "서드파티 플러그인을 갱신합니다..." "info"

    if ! timeout "${PLUGIN_UPDATE_TIMEOUT:-300}" bash /scripts/plugin-update.sh; then
        log_message "서드파티 플러그인 갱신이 실패했거나 시간을 초과했습니다 — 기존 플러그인으로 서버를 시작합니다" "warning"
    fi

    return 0
}
