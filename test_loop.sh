#!/bin/bash

test_loop_timeout() {
    # Create a minimal .env for testing
    printf "X1=0\nY1=0\nX2=0\nY2=0\nINTERVAL=1\nTOTAL_DURATION=2\n" > .env
    
    start_time=$(date +%s)
    ./autoswipe.sh --test-run > /dev/null 2>&1
    end_time=$(date +%s)
    
    duration=$((end_time - start_time))
    if [ $duration -ge 2 ] && [ $duration -le 5 ]; then
        echo "PASS: Loop terminated correctly after $duration seconds"
        return 0
    else
        echo "FAIL: Loop terminated too early or too late ($duration seconds)"
        return 1
    fi
}

test_loop_timeout
