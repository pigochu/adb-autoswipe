#!/bin/bash

# Test: Missing .env should fail
test_missing_env() {
    rm -f .env
    ./autoswipe.sh --check-config > /dev/null 2>&1
    if [ $? -ne 1 ]; then
        echo "FAIL: Should fail when .env is missing"
        return 1
    fi
    echo "PASS: Fails correctly when .env is missing"
    return 0
}

# Test: Existing .env should pass
test_existing_env() {
    cp .env.example .env
    ./autoswipe.sh --check-config > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "FAIL: Should pass when .env exists"
        return 1
    fi
    echo "PASS: Passes correctly when .env exists"
    return 0
}

# Run tests
test_missing_env && test_existing_env

# Test: Log format should include timestamp [YYYY-MM-DD HH:MM:SS]
test_log_format() {
    output=$(./autoswipe.sh --test-log 2>&1)
    if [[ ! $output =~ \[[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\] ]]; then
        echo "FAIL: Log output missing or has incorrect timestamp format"
        echo "Output: $output"
        return 1
    fi
    echo "PASS: Log output has correct timestamp format"
    return 0
}

# Run log test
test_log_format
