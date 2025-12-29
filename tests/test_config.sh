#!/bin/bash

# Test for load_config function - 安全測試版 (不更動 .env)

# 建立臨時測試設定檔
TEST_ENV=".env.test"
cat <<EOF > "$TEST_ENV"
X1=100
Y1=200
X2=300
Y2=400
INTERVAL=10
INTERVAL_JITTER=2
COORD_X_JITTER=5
COORD_Y_JITTER=5
TOTAL_DURATION=60
EOF

# 載入 autoswipe.sh (僅載入函數)
source ./autoswipe.sh --check-config > /dev/null 2>&1

# 測試指定檔案載入
load_config "$TEST_ENV"

result=0

# 驗證變數
[ "$CONF_X1" == "100" ] || { echo "X1 failed: expected 100, got $CONF_X1"; result=1; }
[ "$CONF_Y1" == "200" ] || { echo "Y1 failed: expected 200, got $CONF_Y1"; result=1; }
[ "$CONF_X2" == "300" ] || { echo "X2 failed: expected 300, got $CONF_X2"; result=1; }
[ "$CONF_Y2" == "400" ] || { echo "Y2 failed: expected 400, got $CONF_Y2"; result=1; }
[ "$CONF_WAIT" == "10" ] || { echo "INTERVAL failed: expected 10, got $CONF_WAIT"; result=1; }
[ "$CONF_WAIT_JITTER" == "2" ] || { echo "INTERVAL_JITTER failed: expected 2, got $CONF_WAIT_JITTER"; result=1; }
[ "$CONF_X_JITTER" == "5" ] || { echo "COORD_X_JITTER failed: expected 5, got $CONF_X_JITTER"; result=1; }
[ "$CONF_Y_JITTER" == "5" ] || { echo "COORD_Y_JITTER failed: expected 5, got $CONF_Y_JITTER"; result=1; }
[ "$CONF_MAX_TIME" == "60" ] || { echo "TOTAL_DURATION failed: expected 60, got $CONF_MAX_TIME"; result=1; }

# 清理測試檔
rm "$TEST_ENV"

if [ $result -eq 0 ]; then
    echo "Config test passed (Safe mode)!"
    exit 0
else
    echo "Config test failed!"
    exit 1
fi