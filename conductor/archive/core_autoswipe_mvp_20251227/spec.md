# Track Spec: Core AutoSwipe MVP

## 概述
建立一個極簡的 Bash 腳本 `autoswipe.sh`，實現透過 Wireless ADB 自動滑動手機螢幕的功能。

## 需求
1. **設定檔管理**:
   - 讀取 `.env` 檔案中的 `X1, Y1, X2, Y2` (座標), `INTERVAL` (間隔秒數), `TOTAL_DURATION` (總執行時間)。
   - 若未設定 `INTERVAL`，預設為 5 秒。
2. **互動式配對流程**:
   - 啟動時提示使用者輸入手機的 IP:Port。
   - 提示使用者輸入配對碼 (Pairing Code)。
   - 執行 `adb pair` 與 `adb connect`。
3. **主循環邏輯**:
   - 記錄啟動時間。
   - 每隔 `INTERVAL` 秒執行一次 `adb shell input swipe X1 Y1 X2 Y2`。
   - 每次執行後，檢查是否已超過 `TOTAL_DURATION`。
   - 顯示當前進度（已滑動次數、預估剩餘時間）。
4. **資源清理**:
   - 結束或被中斷 (Ctrl+C) 時，執行 `adb disconnect`。

## 驗證標準
- 腳本能成功讀取 `.env`。
- 能成功與手機配對並連線。
- 滑動動作在手機上實際發生。
- 時間到後腳本自動安全退出。
