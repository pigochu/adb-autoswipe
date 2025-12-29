#!/bin/bash

# 強制指定 ADB 設定目錄
export ADB_USER_CONFIG_DIR="$(pwd)/.android"
export HOME="$(pwd)" 

# 載入核心模組
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/core.sh"

DEVICES_FILE="devices.conf"

trap cleanup SIGINT SIGTERM

get_device_model() {
    local model=$(adb shell getprop ro.product.model | tr -d '\r')
    echo "${model:-未知裝置}"
}

update_device_record() {
    local new_name="$1"; local new_ip="$2"; local temp_file="devices.conf.tmp"
    touch "$DEVICES_FILE"
    while IFS='|' read -r name ip; do
        if [[ -n "$name" && "$name" != "$new_name" ]]; then echo "$name|$ip" >> "$temp_file"; fi
    done < "$DEVICES_FILE"
    echo "$new_name|$new_ip" >> "$temp_file"
    mv "$temp_file" "$DEVICES_FILE"
}

adb_smart_connect() {
    log_info "正在初始化 ADB 環境..."
    adb kill-server > /dev/null 2>&1; adb start-server > /dev/null 2>&1
    echo "================================================"
    echo " Wireless ADB 智慧連線 (路徑: .android/)"
    echo "================================================"
    local options=(); local ips=()
    [ -f "$DEVICES_FILE" ] && while IFS='|' read -r name ip; do options+=("$name"); ips+=("$ip"); done < "$DEVICES_FILE"
    for i in "${!options[@]}"; do echo "$((i+1))) ${options[i]} (上次 IP: ${ips[i]})"; done
    echo "0) 新裝置配對"
    read -p "請選擇: " choice
    local target=""
    if [ "$choice" == "0" ]; then
        read -p "配對 IP:Port: " p_addr; read -p "配對碼: " p_code
        adb pair "$p_addr" "$p_code" || return 1
        read -p "連線 IP:Port: " target
    else
        local idx=$((choice-1)); echo "提示: 上次 IP 為 ${ips[idx]}"
        read -p "請輸入目前 IP:Port: " target
    fi
    log_info "連線中: $target..."
    adb connect "$target"
    if adb devices | grep -q "$target.*device"; then
        update_device_record "$(get_device_model)" "$(echo "$target" | cut -d':' -f1)"
        return 0
    fi
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        "--check-config") load_config; exit $? ;; 
        *) load_config && adb_smart_connect && start_main_loop ;; 
    esac
fi