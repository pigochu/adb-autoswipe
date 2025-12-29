#!/bin/bash

# 強制指定 ADB 設定目錄
export ADB_USER_CONFIG_DIR="$(pwd)/.android"
export HOME="$(pwd)" 

# 載入核心模組
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/core.sh"

DEVICES_FILE="devices.conf"

cleanup() {
    echo ""
    log_info "正在清理資源..."
    adb disconnect > /dev/null 2>&1
    [[ "$KILL_ADB_ON_EXIT" =~ ^[YyTt1] ]] && adb kill-server > /dev/null 2>&1
    log_info "已安全退出。"
    exit 0
}

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

start_main_loop() {
    echo ""; read -p ">>> 準備好後按 [Enter] 開始滑動 <<<"
    echo ""
    local start_time=$(date +%s); local count=0
    local d_msg="$CONF_MAX_TIME 秒"; [ "$CONF_MAX_TIME" -le 0 ] && d_msg="無限"
    
    log_info "啟動參數確認 (內建隨機化機制):"
    log_info "- 基礎座標: ($CONF_X1, $CONF_Y1) -> ($CONF_X2, $CONF_Y2)"
    log_info "- 座標抖動: X±$CONF_X_JITTER, Y±$CONF_Y_JITTER 像素"
    log_info "- 基礎間隔: $CONF_WAIT 秒 (+ 0~$CONF_WAIT_JITTER 秒隨機)"
    log_info "- 執行耗時: 200~700 毫秒隨機"
    log_info "- 總執行時間: $d_msg"
    
    while true; do
        local elapsed=$(($(date +%s) - start_time))
        [ "$CONF_MAX_TIME" -gt 0 ] && [ "$elapsed" -ge "$CONF_MAX_TIME" ] && break
        count=$((count + 1))
        
        # 1. 隨機等待時間
        local current_wait=$CONF_WAIT
        if [ "$CONF_WAIT_JITTER" -gt 0 ]; then
            current_wait=$((CONF_WAIT + RANDOM % (CONF_WAIT_JITTER + 1)))
        fi

        # 2. 隨機座標偏移
        local cur_x1=$CONF_X1; local cur_y1=$CONF_Y1; local cur_x2=$CONF_X2; local cur_y2=$CONF_Y2
        if [ "$CONF_X_JITTER" -gt 0 ]; then
            local rx=$((RANDOM % (CONF_X_JITTER + 1)))
            cur_x1=$((CONF_X1 + rx)); cur_x2=$((CONF_X2 + rx))
        fi
        if [ "$CONF_Y_JITTER" -gt 0 ]; then
            local ry=$((RANDOM % (CONF_Y_JITTER + 1)))
            cur_y1=$((CONF_Y1 + ry)); cur_y2=$((CONF_Y2 + ry))
        fi

        # 3. 隨機滑動耗時 (200ms ~ 700ms)
        local cur_duration=$((200 + RANDOM % 501))

        local timestamp="[$(date '+%Y-%m-%d %H:%M:%S')]"
        if [ "$CONF_MAX_TIME" -gt 0 ]; then
            echo -ne "$timestamp [進度] 次數: $count | 剩餘: $((CONF_MAX_TIME - elapsed)) 秒 | 下次等待: ${current_wait} 秒\033[K\r"
        else
            echo -ne "$timestamp [進度] 次數: $count | 剩餘: 無限 | 已用: ${elapsed} 秒 | 下次等待: ${current_wait} 秒\033[K\r"
        fi
        
        # 執行帶有隨機耗時的滑動
        adb shell input swipe "$cur_x1" "$cur_y1" "$cur_x2" "$cur_y2" "$cur_duration"
        
        sleep "$current_wait"
    done
    cleanup
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        "--check-config") load_config; exit $? ;; 
        *) load_config && adb_smart_connect && start_main_loop ;; 
    esac
fi