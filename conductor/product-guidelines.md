# Product Guidelines - AutoSwipe Bash

## 開發原則
- **Fail Fast**：任何關鍵指令（如 adb connect/pair/shell）失敗時，應立即停止執行並告知錯誤原因。
- **安全性**：在程式正常退出或被使用者中斷（Ctrl+C）時，必須嘗試清理環境（如執行 adb disconnect）。
- **模組化**：核心功能應與入口腳本分離，以便支援多種連線模式（Wi-Fi/USB）。

## 程式碼風格
- **結構化**：使用 Bash Functions 將功能模組化（例如 `load_config`, `adb_auto_connect`, `start_main_loop`）。
- **說明文件**：代碼內部必須包含繁體中文註釋，解釋複雜邏輯與函數用途。
- **變數管理**：所有常數應從 `.env` 讀取，並在程式啟動時進行有效性驗證。

## 使用者體驗 (UX)
- **回饋一致性**：所有終端機輸出應包含 `[YYYY-MM-DD HH:MM:SS]` 格式的時間戳記。
- **智慧連線**：優先偵測已連線裝置，若無則提供多樣化連線選單。
- **設定防呆**：當 `.env` 缺少非關鍵變數時，應套用合理的預設值並通知使用者。