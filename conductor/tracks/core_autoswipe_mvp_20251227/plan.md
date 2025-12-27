# Track Plan: Core AutoSwipe MVP

## Phase 1: 基礎架構與設定 (Setup & Config)
- [~] Task: 建立 ".env.example" 與 ".env" 驗證邏輯
  - [ ] Write Tests: 撰寫測試確認腳本能正確識別缺失的環境變數。
  - [ ] Implement: 實現 `load_config` 函數，包含預設值設定。
- [x] Task: 實現基礎日誌與時間戳記功能 (8b341c4)
  - [ ] Write Tests: 測試日誌輸出格式是否包含正確的時間戳記。
  - [ ] Implement: 實現 `log_info`, `log_error` 函數。
- [ ] Task: Conductor - User Manual Verification 'Phase 1: 基礎架構與設定' (Protocol in workflow.md)

## Phase 2: ADB 連線管理 (Connection Management)
- [ ] Task: 實現互動式配對與連線函數
  - [ ] Write Tests: 使用 Mock ADB 指令測試連線成功與失敗的流程。
  - [ ] Implement: 實現 `adb_pair_and_connect` 函數。
- [ ] Task: 實現 Ctrl+C 捕捉與清理邏輯
  - [ ] Write Tests: 測試當接收到 SIGINT 時是否觸發斷開連線動作。
  - [ ] Implement: 使用 `trap` 捕捉訊號並執行清理。
- [ ] Task: Conductor - User Manual Verification 'Phase 2: ADB 連線管理' (Protocol in workflow.md)

## Phase 3: 核心滑動邏輯 (Core Loop)
- [ ] Task: 實現定時滑動與進度顯示
  - [ ] Write Tests: 測試滑動指令的參數拼湊是否正確。
  - [ ] Implement: 實現 `perform_swipe` 與進度回饋。
- [ ] Task: 實現時間檢查與自動結束
  - [ ] Write Tests: 測試當目前時間超過設定時長時，循環是否終止。
  - [ ] Implement: 在主循環中加入時間比對邏輯。
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 核心滑動邏輯' (Protocol in workflow.md)
