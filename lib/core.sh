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
