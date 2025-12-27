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
    adb shell input swipe "$X1" "$Y1" "$X2" "$Y2"
}

# 獲取手機型號
get_device_model() {
    local model=$(adb shell getprop ro.product.model | tr -d '\r')
    echo "${model:-未知裝置}"
}

# 更新紀錄檔
update_device_record() {
    local new_name="$1"; local new_ip="$2"; local temp_file="devices.conf.tmp"
    touch "$DEVICES_FILE"
    while IFS='|' read -r name ip; do
        if [ "$name" != "$new_name" ]; then echo "$name|$ip" >> "$temp_file"; fi
    done < "$DEVICES_FILE"
    echo "$new_name|$new_ip" >> "$temp_file"; mv "$temp_file" "$DEVICES_FILE"
}

# 智慧連線
adb_smart_connect() {
    echo "================================================"
    echo " Wireless ADB 智慧連線"
    echo "================================================"
    local options=(); local ips=()
    if [ -f "$DEVICES_FILE" ]; then
        while IFS='|' read -r name ip; do options+=("$name"); ips+=("$ip"); done < "$DEVICES_FILE"
    fi
    for i in "${!options[@]}"; do echo "$((i+1))) ${options[i]} (上次 IP: ${ips[i]})"; done
    echo "0) 新裝置配對"
    read -p "請選擇: " choice
    local target_full_addr=""
    if [ "$choice" == "0" ]; then
        read -p "配對 IP:Port: " p_addr; read -p "配對碼: " p_code
        adb pair "$p_addr" "$p_code" || return 1
        read -p "連線 IP:Port: " target_full_addr
    else
        local idx=$((choice-1)); echo "提示: 上次 IP 為 ${ips[idx]}"
        read -p "請輸入目前 IP:Port: " target_full_addr
    fi
    log_info "連線中: $target_full_addr..."
    adb connect "$target_full_addr"
    if adb devices | grep -q "$target_full_addr.*device"; then
        local model=$(get_device_model); update_device_record "$model" "${target_full_addr%:*}$"
        return 0
    fi
    return 1
}

# 主循環邏輯
start_main_loop() {
    local start_time=$(date +%s)
    local count=0
    log_info "開始自動滑動任務 (總時長: $TOTAL_DURATION 秒, 間隔: $INTERVAL 秒)"
    
    while true; do
        local now=$(date +%s)
        local elapsed=$((now - start_time))
        
        if [ $elapsed -ge $TOTAL_DURATION ]; then
            log_info "已達到設定時長 ($TOTAL_DURATION 秒)，任務結束。"
            break
        fi
        
        count=$((count + 1))
        local remaining=$((TOTAL_DURATION - elapsed))
        
        echo -ne "[$(date '+%Y-%m-%d %H:%M:%S')] [進度] 已滑動: $count 次 | 剩餘時間: $remaining 秒\r"
        
        perform_swipe
        sleep "$INTERVAL"
    done
    cleanup
}

# 載入設定
load_config() {
    if [ ! -f .env ]; then log_error ".env 不存在"; return 1; fi
    source .env
    X1=${X1:-500}; Y1=${Y1:-1500}; X2=${X2:-500}; Y2=${Y2:-500}
    INTERVAL=${INTERVAL:-5}; TOTAL_DURATION=${TOTAL_DURATION:-3600}
    return 0
}

# 入口
if [ "$1" == "--test-run" ]; then
    load_config && start_main_loop; exit 0
elif [ "$1" == "--test-log" ]; then
    log_info "Test log"; exit 0
elif [ "$1" == "--test-connection" ]; then
    adb_smart_connect; exit 0
elif [ "$1" == "--test-cleanup" ]; then
    while true; do sleep 1; done
elif [ "$1" == "--test-swipe" ]; then
    load_config && perform_swipe; exit 0
fi

# 正常啟動流程
load_config && adb_smart_connect && start_main_loop
