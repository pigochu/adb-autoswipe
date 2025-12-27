#!/bin/bash
export PATH="$(pwd)/test_bin:$PATH"
mkdir -p test_bin
printf "#!/bin/bash\nif [[ \"\$*\" == *\"shell input swipe\"* ]]; then\n    echo \"SWIPE_CALLED: \$*\"\n    exit 0\nfi\n" > test_bin/adb
chmod +x test_bin/adb

test_swipe_params() {
    export X1=100 Y1=200 X2=300 Y2=400
    output=$(./autoswipe.sh --test-swipe 2>&1)
    if [[ "$output" == *"SWIPE_CALLED: shell input swipe 100 200 300 400"* ]]; then
        echo "PASS: Swipe command parameters are correct"
        return 0
    else
        echo "FAIL: Swipe command parameters are incorrect"
        echo "Output: $output"
        return 1
    fi
}

test_swipe_params
