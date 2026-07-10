#!/bin/bash

source /utils/logging.sh

# 설정 파일 버전. 필드나 설명을 바꾸면 올린다.
# 올리면 기존 파일을 다시 만들고 apply_smart_merge 가 사용자가 바꾼 '값' 만 되살린다.
CONFIG_VERSION="1.2.0"

# Use organized egg directory structure
CONFIG_DIR="${EGG_CONFIGS_DIR:-/home/container/egg/configs}"

# Check if any config needs migration
check_config_versions() {
    local needs_migration=false
    local old_version=""

    # Check all config files
    for config_file in "$CONFIG_DIR/console-filter.json" "$CONFIG_DIR/cleanup.json" "$CONFIG_DIR/logging.json"; do
        if [ -f "$config_file" ]; then
            local current_version=$(jq -r '.version // "0.0.0"' "$config_file" 2>/dev/null)
            if [ "$current_version" != "$CONFIG_VERSION" ]; then
                needs_migration=true
                old_version="$current_version"
                break
            fi
        fi
    done

    # Log once if migration is needed
    if [ "$needs_migration" = true ]; then
        log_message "Migrating configs from v$old_version to v$CONFIG_VERSION" "info"
    fi
}

# Migrate old config to new version (no logging, just migration)
migrate_config() {
    local config_file="$1"
    local config_name="$2"

    if [ ! -f "$config_file" ]; then
        return 0
    fi

  # Check if version field exists and matches
  local current_version=$(jq -r '.version // "0.0.0"' "$config_file" 2>/dev/null)

    if [ "$current_version" == "$CONFIG_VERSION" ]; then
        return 0
    fi

    # Extract old values
    local old_values=$(jq -r 'del(._description) | del(.version)' "$config_file" 2>/dev/null)

    # Remove old config
    rm "$config_file"

    # Return the old values so we can merge them
    echo "$old_values"
}

# Apply smart merge to config file (centralized jq logic)
apply_smart_merge() {
    local config_file="$1"
    local old_values="$2"

    if [ -z "$old_values" ] || [ "$old_values" = "null" ]; then
        return 0
    fi

    log_message "Merging previous settings..." "debug"
    local temp_file="${config_file}.tmp"

    jq --argjson old "$old_values" '
        def smart_merge($old):
            . as $new |
            if ($new | type) == "object" then
                $new | to_entries | map(
                    .key as $k |
                    if ($new[$k] | type) == "object" then
                        {key: $k, value: ($new[$k] | smart_merge($old[$k] // {}))}
                    else
                        {key: $k, value: ($old[$k] // $new[$k])}
                    end
                ) | from_entries
            else
                $old // $new
            end;
        smart_merge($old) | .version = "'"$CONFIG_VERSION"'"
    ' "$config_file" > "$temp_file"

    mv "$temp_file" "$config_file"
}

init_configs() {
  # Initialize egg directories (from logging.sh)
    init_egg_directories

    mkdir -p "$CONFIG_DIR"

    # Check if migration is needed (logs once if yes)
    check_config_versions

    create_console_filter_config
    create_cleanup_config
    create_logging_config
}

create_console_filter_config() {
    local config_file="$CONFIG_DIR/console-filter.json"
    local old_values=""

  # Migrate if needed
    if [ -f "$config_file" ]; then
        old_values=$(migrate_config "$config_file" "console-filter")
    fi

    if [ ! -f "$config_file" ]; then
        cat > "$config_file" << EOF
{
  "version": "$CONFIG_VERSION",
  "_description": [
    "콘솔 필터 설정",
    "",
    "CS2 서버가 콘솔에 쏟아내는 메시지 중 보고 싶지 않은 것을 걸러냅니다.",
    "",
    "항목",
    "  - preview_mode: 걸러낸 메시지를 디버그 로그에 남길지 여부입니다 (true/false).",
    "  - patterns: 필터 패턴 목록입니다.",
    "",
    "패턴 규칙",
    "  - 앞에 @ 를 붙이면 줄 전체가 똑같을 때만 막습니다. 예) \"@Server is hibernating\"",
    "  - @ 없이 쓰면 그 문구가 들어간 줄을 모두 막습니다. 예) \"edicts used\"",
    "",
    "STEAM_ACC 토큰은 설정되어 있으면 자동으로 가려집니다.",
    "",
    "이 기능은 Pterodactyl egg 변수 ENABLE_FILTER=1 로 켭니다.",
    "",
    "설정 파일 위치는 /home/container/egg/configs/console-filter.json 입니다."
  ],
  "preview_mode": false,
  "patterns": [
    "Certificate expires"
  ]
}
EOF

        # Merge old values if migration happened
        apply_smart_merge "$config_file" "$old_values"
    fi
}

create_cleanup_config() {
    local config_file="$CONFIG_DIR/cleanup.json"
    local old_values=""

  # Migrate if needed
    if [ -f "$config_file" ]; then
        old_values=$(migrate_config "$config_file" "cleanup")
    fi

    if [ ! -f "$config_file" ]; then
        cat > "$config_file" << EOF
{
  "version": "$CONFIG_VERSION",
  "_description": [
    "자동 정리 설정 — 규칙 기반",
    "",
    "'rules' 의 각 항목은 독립적인 정리 대상입니다. 코드를 건드리지 않고",
    "규칙을 고치거나 끄거나 더하거나 지울 수 있습니다.",
    "",
    "규칙 항목",
    "  - name: 로그에 표시되는 분류 이름입니다. 예) 'demos', 'backup_rounds'",
    "  - description: 사람이 읽는 설명입니다. 동작에는 영향을 주지 않습니다.",
    "  - directories: 찾아볼 경로 목록입니다. /home/container 기준 상대경로 또는 절대경로입니다.",
    "  - patterns: 파일 이름 패턴 목록입니다. 예) '*.dem', 'core.[0-9]*'",
    "  - hours: 이 시간보다 오래된 파일만 지웁니다. 0 이면 실행할 때마다 지웁니다.",
    "  - recursive: true 면 하위 디렉터리까지, false 면 해당 디렉터리만 봅니다.",
    "  - enabled: false 로 두면 규칙을 지우지 않고 끌 수 있습니다.",
    "",
    "이 기능은 Pterodactyl egg 변수 CLEANUP_ENABLED=1 로 켭니다.",
    "",
    "설정 파일 위치는 /home/container/egg/configs/cleanup.json 입니다."
  ],
  "rules": [
    {
      "name": "backup_rounds",
      "description": "CS2 경기 라운드 백업 스냅샷입니다.",
      "directories": ["./game/csgo"],
      "patterns": ["backup_round*.txt"],
      "hours": 24,
      "recursive": true,
      "enabled": true
    },
    {
      "name": "demos",
      "description": "SourceTV 데모 녹화 파일입니다.",
      "directories": ["./game/csgo"],
      "patterns": ["*.dem"],
      "hours": 168,
      "recursive": true,
      "enabled": true
    },
    {
      "name": "css_logs",
      "description": "CounterStrikeSharp 로그 파일입니다.",
      "directories": ["./game/csgo/addons/counterstrikesharp/logs"],
      "patterns": ["*.txt"],
      "hours": 72,
      "recursive": true,
      "enabled": true
    },
    {
      "name": "swiftly_logs",
      "description": "SwiftlyS2 로그 파일입니다.",
      "directories": ["./game/csgo/addons/swiftlys2/logs"],
      "patterns": ["*.log"],
      "hours": 72,
      "recursive": true,
      "enabled": true
    },
    {
      "name": "accelerator_dumps",
      "description": "AcceleratorCS2 크래시 덤프와 리포트입니다.",
      "directories": ["./game/csgo/addons/AcceleratorCS2/dumps"],
      "patterns": ["*.dmp", "*.dmp.txt"],
      "hours": 168,
      "recursive": true,
      "enabled": true
    },
    {
      "name": "core_dumps",
      "description": "리눅스 코어 덤프입니다. 실행할 때마다 지웁니다.",
      "directories": ["./game/bin/linuxsteamrt64", "/home/container"],
      "patterns": ["core", "core.[0-9]*"],
      "hours": 0,
      "recursive": false,
      "enabled": true
    }
  ]
}
EOF

        # Merge old values if migration happened
        apply_smart_merge "$config_file" "$old_values"
    fi
}

create_logging_config() {
    local config_file="$CONFIG_DIR/logging.json"
    local old_values=""

  # Migrate if needed
    if [ -f "$config_file" ]; then
        old_values=$(migrate_config "$config_file" "logging")
    fi

    if [ ! -f "$config_file" ]; then
        cat > "$config_file" << EOF
{
  "version": "$CONFIG_VERSION",
  "_description": [
    "로그 설정",
    "",
    "콘솔에 찍히는 로그 수준과 파일 로그를 조절합니다.",
    "",
    "콘솔",
    "  - logging.console_level: 콘솔에 찍을 최소 로그 수준입니다.",
    "    쓸 수 있는 값은 DEBUG, INFO, WARNING, ERROR 입니다.",
    "",
    "파일 로그",
    "  - logging.file_enabled: 날짜별 로그 파일을 남길지 여부입니다 (true/false).",
    "  - logging.max_size_mb: 로그 디렉터리 전체 크기 상한입니다 (MB).",
    "  - logging.max_files: 보관할 로그 파일 개수 상한입니다.",
    "  - logging.max_days: 로그 파일을 보관할 최대 일수입니다.",
    "",
    "로그 파일은 /home/container/egg/logs/YYYY-MM-DD.log 에 쌓입니다.",
    "크기·개수·기간 중 하나라도 상한에 닿으면 오래된 것부터 지웁니다.",
    "",
    "이 설정은 항상 읽히며 별도의 egg 변수가 필요하지 않습니다.",
    "",
    "설정 파일 위치는 /home/container/egg/configs/logging.json 입니다."
  ],
  "logging": {
    "console_level": "INFO",
    "file_enabled": false,
    "max_size_mb": 100,
    "max_files": 30,
    "max_days": 7
  }
}
EOF

        # Merge old values if migration happened
        apply_smart_merge "$config_file" "$old_values"
    fi
}

get_config_value() {
    local config_file="$1"
    local json_path="$2"
    local default_value="$3"
    local full_path="$CONFIG_DIR/$config_file"

    if [ ! -f "$full_path" ]; then
        echo "$default_value"
        return
    fi

  local value=$(jq -r "$json_path // \"$default_value\"" "$full_path" 2>/dev/null)

    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

load_configs() {
    # Load console filter config if enabled via environment variable
    if [ "${ENABLE_FILTER:-0}" -eq 1 ]; then
        export FILTER_PREVIEW_MODE=$(get_config_value "console-filter.json" ".preview_mode" "false")
    fi

    # Load logging config (always available, not feature-gated)
    export CONSOLE_LOG_LEVEL=$(get_config_value "logging.json" ".logging.console_level" "INFO")
    export LOG_FILE_ENABLED=$(get_config_value "logging.json" ".logging.file_enabled" "false")
    export LOG_MAX_SIZE_MB=$(get_config_value "logging.json" ".logging.max_size_mb" "100")
    export LOG_MAX_FILES=$(get_config_value "logging.json" ".logging.max_files" "30")
    export LOG_MAX_DAYS=$(get_config_value "logging.json" ".logging.max_days" "7")
}