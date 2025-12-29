#!/bin/bash

# AutoSwipe 核心功能模組

# 輸出一般資訊日誌
log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"; }

# 輸出錯誤資訊日誌
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2; }

# 從環境設定檔 (.env) 載入滑動參數與座標資訊
load_config() {
    local env_file="${1:-.env}"
    [ ! -f "$env_file" ] && { log_error "$env_file 不存在"; return 1; }
    
    # 清除舊變數以防污染環境
    unset X1 Y1 X2 Y2 INTERVAL INTERVAL_JITTER TOTAL_DURATION COORD_X_JITTER COORD_Y_JITTER KILL_ADB_ON_EXIT
    source "$env_file"
    
    CONF_X1=${X1:-500}; CONF_Y1=${Y1:-1500}; CONF_X2=${X2:-500}; CONF_Y2=${Y2:-500}
    CONF_WAIT=${INTERVAL:-5}
    CONF_WAIT_JITTER=${INTERVAL_JITTER:-0}
    CONF_X_JITTER=${COORD_X_JITTER:-0}
    CONF_Y_JITTER=${COORD_Y_JITTER:-0}
    CONF_MAX_TIME=${TOTAL_DURATION:-0}
    [[ -z "$CONF_MAX_TIME" || ! "$CONF_MAX_TIME" =~ ^-?[0-9]+$ ]] && CONF_MAX_TIME=0
    
    # 導出 KILL_ADB_ON_EXIT 供 cleanup 流程參考
    export KILL_ADB_ON_EXIT=$KILL_ADB_ON_EXIT
    
    return 0
}

# 清理資源：中斷 ADB 連線並視設定關閉 ADB Server
cleanup() {
    echo ""
    log_info "正在清理資源..."
    
    # 僅在透過網路連線 (包含 IP) 且明確指定序號時才斷開，避免影響 USB 實體連線
    if [[ -n "$ANDROID_SERIAL" && "$ANDROID_SERIAL" =~ : ]]; then
        log_info "斷開裝置連線: $ANDROID_SERIAL"
        adb disconnect "$ANDROID_SERIAL" > /dev/null 2>&1
    fi
    
    [[ "$KILL_ADB_ON_EXIT" =~ ^[YyTt1] ]] && adb kill-server > /dev/null 2>&1
    log_info "已安全退出。"
    exit 0
}

# 檢查當前系統中已連線的 ADB 裝置 (例如透過 USB 或已建立的網路連線)
check_connected_devices() {
    # 使用 awk 精確過濾狀態為 'device' 的裝置，並取得其序號 (Serial Number)
    local devices=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')
    local count=$(echo "$devices" | grep -c .)
    
    if [ "$count" -ge 1 ]; then
        echo "$devices"
        return 0
    fi
    return 1
}

# 透過手動輸入 IP:Port 進行直接 ADB 連線
adb_direct_connect() {
    local target=""
    read -p "請輸入目前 IP:Port: " target
    [ -z "$target" ] && return 1
    
    log_info "嘗試直接連線: $target..."
    adb connect "$target"
    if adb devices | grep -q "$target.*device"; then
        log_info "連線成功!"
        export ANDROID_SERIAL=$target
        return 0
    fi
    log_error "連線失敗。"
    return 1
}

# 自動連線主流程：整合自動偵測、歷史紀錄與手動連線選項的智慧選單
adb_auto_connect() {
    local devices_file="$1"
    log_info "正在初始化 ADB 環境..."
    adb start-server > /dev/null 2>&1
    
    echo "================================================"
    echo " AutoSwipe 智慧連線選單"
    echo "================================================"

    local menu_idx=1
    
    # 1. 列出當前已在線的裝置 (例如 USBipd、實體 USB 或已連線的網路裝置)
    local online_devices=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')
    local online_array=()
    if [ -n "$online_devices" ]; then
        echo "--- 在線裝置 (Online) ---"
        while read -r serial; do
            [ -z "$serial" ] && continue
            local model=$(adb -s "$serial" shell getprop ro.product.model | tr -d '\r')
            echo "$menu_idx) [在線] $model ($serial)"
            online_array+=("$serial")
            ((menu_idx++))
        done <<< "$online_devices"
    fi

    # 2. 列出歷史紀錄中的裝置 (通常是先前透過 WiFi 配對成功的裝置)
    local saved_options=(); local saved_ips=()
    if [ -f "$devices_file" ]; then
        echo "--- 歷史紀錄 (WiFi 已配對) ---"
        while IFS='|' read -r name ip; do
            [ -z "$name" ] && continue
            echo "$menu_idx) [紀錄] $name (上次 IP: $ip)"
            saved_options+=("$name")
            saved_ips+=("$ip")
            ((menu_idx++))
        done < "$devices_file"
    fi

    echo "--- 其他連線方式 ---"
    local wifi_pair_opt=$menu_idx
    echo "$wifi_pair_opt) 使用 WiFi 配對碼連線 (新裝置)"
    ((menu_idx++))
    
    local direct_ip_opt=$menu_idx
    echo "$direct_ip_opt) 直接 IP 位址連線 (已開啟網路偵錯)"
    ((menu_idx++))
    
    echo "q) 退出"
    echo "================================================"
    
    read -p "請選擇: " choice
    
    if [[ "$choice" == "q" ]]; then exit 0; fi

    # 根據使用者選擇處理連線邏輯
    if [[ "$choice" -le "${#online_array[@]}" && "$choice" -gt 0 ]]; then
        # 選擇已在線裝置
        local selected_serial=${online_array[$((choice-1))]}
        log_info "使用裝置: $selected_serial"
        export ANDROID_SERIAL=$selected_serial
        return 0
    
    elif [[ "$choice" -lt "$wifi_pair_opt" && "$choice" -gt "${#online_array[@]}" ]]; then
        # 選擇歷史紀錄裝置
        local idx=$((choice - ${#online_array[@]} - 1))
        local target=""
        echo "提示: ${saved_options[idx]} 上次 IP 為 ${saved_ips[idx]}"
        read -p "請輸入目前 IP:Port: " target
        [ -z "$target" ] && return 1
        adb connect "$target"
        export ANDROID_SERIAL=$target

    elif [[ "$choice" -eq "$wifi_pair_opt" ]]; then
        # 執行 WiFi 配對碼流程
        read -p "配對 IP:Port: " p_addr; read -p "配對碼: " p_code
        adb pair "$p_addr" "$p_code" || return 1
        read -p "連線 IP:Port: " target
        adb connect "$target"
        export ANDROID_SERIAL=$target

    elif [[ "$choice" -eq "$direct_ip_opt" ]]; then
        # 執行直接 IP 連線流程
        adb_direct_connect
        return $?
        
    else
        log_error "無效的選擇"
        return 1
    fi

    # 最終驗證裝置是否成功連線並處於 device 狀態
    if adb devices | grep -q "device$"; then
        return 0
    fi
    return 1
}

# 啟動自動滑動主循環，包含隨機等待、隨機座標與隨機耗時機制
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
        
        # 1. 隨機等待時間計算
        local current_wait=$CONF_WAIT
        if [ "$CONF_WAIT_JITTER" -gt 0 ]; then
            current_wait=$((CONF_WAIT + RANDOM % (CONF_WAIT_JITTER + 1)))
        fi

        # 2. 隨機座標偏移計算
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
        
        # 執行帶有隨機耗時的滑動，使用 ANDROID_SERIAL 確保指令送往正確裝置
        adb -s "${ANDROID_SERIAL:-$(check_connected_devices | head -n1)}" shell input swipe "$cur_x1" "$cur_y1" "$cur_x2" "$cur_y2" "$cur_duration"
        
        sleep "$current_wait"
    done
    cleanup
}