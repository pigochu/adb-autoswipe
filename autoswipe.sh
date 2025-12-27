#!/bin/bash

# Log a message with a timestamp
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2
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

# Entry points for testing
if [ "$1" == "--check-config" ]; then
    load_config
    exit $?
elif [ "$1" == "--test-log" ]; then
    log_info "Test log message"
    exit 0
fi
