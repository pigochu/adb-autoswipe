#!/bin/bash

# Log functions
log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2; }

# Interactive ADB pairing and connection
adb_pair_and_connect() {
    read -p "請輸入手機的 IP:Port (例如 192.168.1.1:5555): " ADB_TARGET
    read -p "請輸入配對碼 (Pairing Code): " PAIR_CODE
    
    log_info "正在配對 $ADB_TARGET..."
    adb pair "$ADB_TARGET" "$PAIR_CODE"
    
    log_info "正在連線 $ADB_TARGET..."
    adb connect "$ADB_TARGET"
}

# Load configurations from .env
load_config() {
    if [ ! -f .env ]; then
        log_error ".env file not found."
        return 1
    fi
    source .env
    INTERVAL=${INTERVAL:-5}
    return 0
}

# Entry points
if [ "$1" == "--check-config" ]; then
    load_config
    exit $?
elif [ "$1" == "--test-log" ]; then
    log_info "Test log message"
    exit 0
elif [ "$1" == "--test-connection" ]; then
    adb_pair_and_connect
    exit 0
fi
