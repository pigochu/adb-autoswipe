#!/bin/bash

# Core utilities for AutoSwipe

log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2; }

load_config() {
    local env_file="${1:-.env}"
    [ ! -f "$env_file" ] && { log_error "$env_file 不存在"; return 1; }
    
    # 清除舊變數以防污染
    unset X1 Y1 X2 Y2 INTERVAL INTERVAL_JITTER TOTAL_DURATION COORD_X_JITTER COORD_Y_JITTER KILL_ADB_ON_EXIT
    source "$env_file"
    
    CONF_X1=${X1:-500}; CONF_Y1=${Y1:-1500}; CONF_X2=${X2:-500}; CONF_Y2=${Y2:-500}
    CONF_WAIT=${INTERVAL:-5}
    CONF_WAIT_JITTER=${INTERVAL_JITTER:-0}
    CONF_X_JITTER=${COORD_X_JITTER:-0}
    CONF_Y_JITTER=${COORD_Y_JITTER:-0}
    CONF_MAX_TIME=${TOTAL_DURATION:-0}
    [[ -z "$CONF_MAX_TIME" || ! "$CONF_MAX_TIME" =~ ^-?[0-9]+$ ]] && CONF_MAX_TIME=0
    
    # 導出 KILL_ADB_ON_EXIT 供 cleanup 使用
    export KILL_ADB_ON_EXIT=$KILL_ADB_ON_EXIT
    
    return 0
}

cleanup() {
    echo ""
    log_info "正在清理資源..."
    # 僅在有連線時才嘗試斷開
    adb disconnect > /dev/null 2>&1
    [[ "$KILL_ADB_ON_EXIT" =~ ^[YyTt1] ]] && adb kill-server > /dev/null 2>&1
    log_info "已安全退出。"
    exit 0
}

check_connected_devices() {
    # 取得狀態為 device 的裝置列表 (排除 header)
    local devices=$(adb devices | grep -v "List of devices attached" | grep "device$" | cut -f1)
    local count=$(echo "$devices" | grep -c .)
    
    if [ "$count" -eq 1 ]; then
        echo "$devices"
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
