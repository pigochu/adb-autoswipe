# Tech Stack - AutoSwipe Bash

## 核心技術
- **腳本語言**: Bash (建議版本 4.0+)
- **作業系統**: Ubuntu (WSL2)
- **連線協議**: ADB Wireless Pairing & USB (via USBIPD)

## 外部依賴
- **Platform-Tools**: `adb`
  - 使用者需確保 `adb` 可在終端機直接調用。
  - 主要指令：`adb pair`, `adb connect`, `adb disconnect`, `adb shell`, `adb -s`.
- **USBIPD-Win**: 於 Windows 端提供 USB 轉向功能，使 WSL2 能存取實體 USB 裝置。

## 開發與運行環境
- **環境變數**: 使用 `.env` 檔案管理座標與參數。
- **終端機**: 支援 ANSI 逃逸字元的標準 Linux Terminal。