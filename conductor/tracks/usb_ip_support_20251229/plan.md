# Plan: `autoswipe-refactor-and-ip-support`

## Phase 1: Logic Refactoring & Decoupling [checkpoint: 9daf2cd]
目標：將 `autoswipe.sh` 的核心邏輯與連線流程分離，並建立測試機制確保重構不破壞現有滑動功能。

- [x] **Task 1: 建立測試環境 (TDD Preparation)** 3005508
    - 建立 `tests/` 目錄。
    - 撰寫測試腳本以驗證 `load_config` 是否能正確解析 `.env`。
- [x] **Task 2: 重構配置加載 (load_config)** 8771508
    - 將 `load_config` 最佳化並確保其可獨立於連線流程執行。
    - 驗證測試通過。
- [x] **Task 3: 重構滑動循環 (start_main_loop)** cacf853
    - 將滑動邏輯改為接受外部參數或純粹依賴全域變數，確保其在任何 ADB 連線建立後都能運作。
- [x] Task: Conductor - User Manual Verification 'Phase 1: Logic Refactoring & Decoupling' (Protocol in workflow.md)

## Phase 2: Enhanced Connection Management
目標：實作智慧偵測邏輯，支援 USB (usbipd) 與直接 IP 連線。

- [x] **Task 1: 實作自動偵測邏輯** 5d2d6e9
    - 撰寫函數檢查 `adb devices` 輸出。
    - 若偵測到單一裝置，直接跳過連線流程。
- [x] **Task 2: 實作直接 IP 連線 (Direct IP Connect)** acaefbe
    - 增加互動式選項，允許使用者輸入 IP:Port 並呼叫 `adb connect`。
- [x] **Task 3: 整合連線選單** bea9884
    - 修改主流程，優先執行自動偵測，無果後彈出選單（USB/IP/WiFi Pairing）。
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Enhanced Connection Management' (Protocol in workflow.md)

## Phase 3: Final Integration & Cleanup
目標：整理程式碼，移除冗餘，並確保清理機制在所有模式下正常運作。

- [x] **Task 1: 優化 Cleanup 機制** 1c8db60
    - 確保 `adb disconnect` 僅在必要時執行（不影響其他 ADB session）。
- [ ] **Task 2: 全面整合測試**
    - 模擬 USB 插入、IP 連線與 WiFi 配對三種情境，確保功能無誤。
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Final Integration & Cleanup' (Protocol in workflow.md)
