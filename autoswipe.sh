#!/bin/bash
export ADB_USER_CONFIG_DIR="$(pwd)/.android"

DEVICES_FILE="devices.conf"

# 日誌函數
log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2; }

# 清理資源
cleanup() {
    echo ""
    log_info "正在清理資源並關閉 ADB 連線..."
    adb disconnect > /dev/null 2>&1
    log_info "已安全退出。"
    exit 0
}

trap cleanup SIGINT SIGTERM

# 執行滑動動作
perform_swipe() {
    log_info "正在執行滑動: ($X1, $Y1) -> ($X2, $Y2)"
    adb shell input swipe "$X1" "$Y1" "$X2" "$Y2"
}

# 獲取手機型號
get_device_model() {
    local model=$(adb shell getprop ro.product.model | tr -d '\r')
    if [ -z "$model" ]; then
        model="未知裝置"
    fi
    echo "$model"
}

# 更新或新增裝置紀錄
update_device_record() {
    local new_name="$1"
    local new_ip="$2"
    local temp_file="devices.conf.tmp"
    local found=0
    touch "$DEVICES_FILE"
    while IFS='|' read -r name ip; do
        if [ "$name" == "$new_name" ]; then
            echo "$new_name|$new_ip" >> "$temp_file"
            found=1
        else
            echo "$name|$ip" >> "$temp_file"
        fi
    done < "$DEVICES_FILE"
    if [ $found -eq 0 ]; then echo "$new_name|$new_ip" >> "$temp_file"; fi
    mv "$temp_file" "$DEVICES_FILE"
}

# 智慧連線管理
adb_smart_connect() {
    echo "================================================"
    echo " Wireless ADB 智慧連線 (支援動態 IP)"
    echo "================================================"
    local options=(); local ips=()
    if [ -f "$DEVICES_FILE" ]; then
        while IFS='|' read -r name ip; do options+=("$name"); ips+=("$ip"); done < "$DEVICES_FILE"
    fi
    echo "請選擇連線對象:"
    echo "0) 新裝置配對 (New Pairing)"
    for i in "${!options[@]}"; do echo "$((i+1))) ${options[i]} (上次 IP: ${ips[i]})"; done
    read -p "請選擇 (0-${#options[@]}): " choice
    local target_full_addr=""
    if [ "$choice" == "0" ]; then
        read -p "請輸入配對視窗顯示的 IP:Port : " pair_addr
        read -p "請輸入 6 位數配對碼 : " pair_code
        log_info "執行配對中..."
        adb pair "$pair_addr" "$pair_code"
        if [ $? -ne 0 ]; then log_error "配對失敗。"; return 1; fi
        echo ""; read -p "請輸入目前的連線 IP:Port (主畫面顯示): " target_full_addr
    else
        local idx=$((choice-1)); local last_name="${options[idx]}"; local last_ip="${ips[idx]}"
        echo "--- 正在連線到 $last_name ---"
        echo "提示: 上次使用的 IP 為 $last_ip"
        read -p "請輸入目前手機顯示的 IP:Port : " target_full_addr
    fi
    local target_ip="${target_full_addr%:*}$"
    log_info "正在連線到 $target_full_addr..."
    adb connect "$target_full_addr"
    if adb devices | grep -q "$target_full_addr.*device"; then
        local current_model=$(get_device_model)
        log_info "連線成功！裝置型號: $current_model"
        update_device_record "$current_model" "$target_ip"
        log_info "紀錄檔已更新。"
    else
        log_error "連線失敗，請檢查資訊是否正確。"
        return 1
    fi
}

# 載入設定
load_config() {
    if [ ! -f .env ]; then log_error ".env 檔案不存在。"; return 1; fi
    source .env
    INTERVAL=${INTERVAL:-5}
    return 0
}

if [ "$1" == "--check-config" ]; then
    load_config; exit $?
elif [ "$1" == "--test-log" ]; then
    log_info "Test log message"; exit 0
elif [ "$1" == "--test-connection" ]; then
    adb_smart_connect; exit 0
elif [ "$1" == "--test-cleanup" ]; then
    log_info "測試模式：請按 Ctrl+C"; while true; do sleep 1; done
elif [ "$1" == "--test-swipe" ]; then
    perform_swipe; exit 0
fi
