#!/bin/bash

# Mock adb command
adb() {
    if [[ "$*" == "pair"* ]]; then
        echo "Successfully paired to 192.168.1.1:5555"
        return 0
    elif [[ "$*" == "connect"* ]]; then
        echo "connected to 192.168.1.1:5555"
        return 0
    fi
    command adb "$@"
}
export -f adb

test_adb_flow() {
    # We expect the script to call adb pair and adb connect
    # Since this is interactive, we will pipe the inputs
    echo -e "192.168.1.1:5555\n123456" | ./autoswipe.sh --test-connection > /tmp/connection_output 2>&1
    
    if ! grep -q "Successfully paired" /tmp/connection_output; then
        echo "FAIL: ADB pair not called or failed"
        return 1
    fi
    if ! grep -q "connected to" /tmp/connection_output; then
        echo "FAIL: ADB connect not called or failed"
        return 1
    fi
    echo "PASS: ADB pairing and connection flow verified (Mocked)"
    return 0
}

test_adb_flow
