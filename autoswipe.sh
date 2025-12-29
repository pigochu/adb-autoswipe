#!/bin/bash

# 強制指定 ADB 設定目錄
export ADB_USER_CONFIG_DIR="$(pwd)/.android"
export HOME="$(pwd)" 

# 載入核心模組
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/core.sh"

DEVICES_FILE="devices.conf"

trap cleanup SIGINT SIGTERM

update_device_record() {
    local new_name="$1"; local new_ip="$2"; local temp_file="devices.conf.tmp"
    touch "$DEVICES_FILE"
    while IFS='|' read -r name ip; do
        if [[ -n "$name" && "$name" != "$new_name" ]]; then echo "$name|$ip" >> "$temp_file"; fi
    done < "$DEVICES_FILE"
    echo "$new_name|$new_ip" >> "$temp_file"
    mv "$temp_file" "$DEVICES_FILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        "--check-config") load_config; exit $? ;;
        *) load_config && adb_auto_connect "$DEVICES_FILE" && start_main_loop ;;
    esac
fi