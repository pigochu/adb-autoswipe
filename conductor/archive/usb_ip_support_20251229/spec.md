# Specification: `autoswipe-refactor-and-ip-support`

## Overview
本 Track 旨在重構 `autoswipe.sh`，引入對 `usbipd` (USB 連接) 與直接 IP 連線的支持。我們將整合連線邏輯，使其能自動偵測已連接的裝置，並提供更靈活的連線選項，同時保持核心滑動邏輯的共用性。

## Functional Requirements
1.  **整合型入口**：維持單一腳本 `autoswipe.sh`，不額外建立 `autoswipe-ip.sh`，改以內部邏輯或參數切換連線模式。
2.  **智慧連線優先級 (Connection Flow)**：
    *   **Step 1: 自動偵測**：檢查 `adb devices` 是否已有裝置在線（適用於 `usbipd` 或已連線裝置）。若只有一個裝置，直接進入滑動循環。
    *   **Step 2: 互動式選擇**：若無在線裝置，提供以下選項：
        *   `WiFi Pairing`: 執行現有的配對碼連線流程。
        *   `Direct Connect (IP)`: 手動輸入 IP:Port 進行連線。
3.  **核心邏輯重構**：
    *   將 `load_config` (環境變數讀取)、`start_main_loop` (滑動邏輯) 與 `cleanup` (清理機制) 抽離成獨立函數。
    *   滑動邏輯必須與連線方式完全解耦，僅依賴已建立的 ADB Session。
4.  **連線管理**：
    *   WiFi 配對模式仍維持 `devices.conf` 的記錄機制。
    *   直接 IP 連線模式不強制記錄到 `devices.conf`。

## Non-Functional Requirements
*   **相容性**：需在 WSL2 環境下運作良好（配合 `usbipd`）。
*   **穩健性**：若連線中斷，應能優雅地執行 `cleanup` 並提示使用者。

## Acceptance Criteria
*   [ ] 當透過 `usbipd` 讓 WSL2 識別到 USB 裝置時，`autoswipe.sh` 啟動後應能直接開始滑動，無需人工干預。
*   [ ] 腳本能正常切換至 IP 手動輸入模式並成功連線。
*   [ ] 原有的 WiFi 配對碼模式功能不受影響且能正常運作。
*   [ ] 所有模式均共用同一套 `.env` 配置與滑動間隔隨機化邏輯。

## Out of Scope
*   支援同時對多個裝置進行滑動（一次僅處理一個裝置）。
*   圖形介面。
