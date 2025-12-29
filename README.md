# AutoSwipe - Android Wi-Fi/USB 自動化工具

一個極簡、無依賴的 Bash 腳本，專為 Linux/WSL2 環境設計，透過 **Wi-Fi (Wireless ADB)** 或 **USB (usbipd)** 實現手機螢幕的定時自動滑動。

## 🌟 核心特色

- **智慧連線管理**：自動偵測已透過 USB (usbipd) 或網路在線的裝置，並提供智慧選擇選單。
- **雙模式支援**：同時相容傳統 Wi-Fi 無線偵錯與最新的 WSL2 USBipd 連接方式。
- **動態 IP 支援**：專為 Wi-Fi 環境設計，即使手機 IP 變動也能透過歷史紀錄輕鬆連線。
- **本地化安全設定**：ADB 金鑰與設定存放在專案內，不污染系統環境。
- **隨機化防偵測**：內建座標抖動與時間隨機化機制。

## 🛠 運作環境

- **OS**: Linux (在 Ubuntu 24 / WSL2 測試通過)
- **依賴**: `adb` (Android Debug Bridge)
  - 在 Ubuntu/WSL2 中安裝：`sudo apt update && sudo apt install adb -y`

## 🚀 快速開始 (專案設定)

### 1. 取得專案
```bash
git clone <your-repo-url>
cd autoswipe
```

### 2. 設定參數
複製 `.env.example` 並更名為 `.env`，修改座標與滑動參數：
```bash
cp .env.example .env
nano .env
```

### 3. 執行腳本
```bash
./autoswipe.sh
```

---

## 🔌 手機連線方式 (選擇其一)

### 方案 A：Wi-Fi 無線偵錯 (最推薦)
> **重要提醒**：手機必須連上 Wi-Fi 網路才能啟用此功能。若手機是開啟「熱點分享」給電腦連線，通常無法啟動無線偵錯。

1. **手機端**：進入「開發者選項」，啟用「無線偵錯」。
2. **手機端**：點擊「無線偵錯」，記下 **IP 地址與通訊埠**。
3. **手機端**：若為首次連線，點擊「使用配對碼配對」，記下 **配對碼** 與 **Port**。
4. **腳本端**：執行 `./autoswipe.sh` 後選擇：
   - `WiFi 配對連線`：適用於**首次連線**或需要重新配對時。
   - `直接 IP 連線`：適用於**先前已配對成功**，僅需輸入當前 Port 即可連線。

### 方案 B：USB 連線 (WSL2 / usbipd)
若您偏好透過實體 USB 線連接，請依序設定：

#### 1. Windows 端安裝 (管理員權限 PowerShell)
```powershell
winget install dorssel.usbipd-win
# (可選) 圖形管理介面
winget install nickbeth.wsl-usb-manager
```

#### 2. Windows 端首次設定範例
```powershell
# 1. 啟動服務 (可設為 Manual 或 Automatic)
Set-Service usbipd -StartupType Manual
Start-Service usbipd

# 2. 找到手機 BUSID (以 1-3 為例)
usbipd list
# 3. 綁定並強制連接
usbipd bind --busid 1-3 --force
usbipd attach --wsl --busid 1-3
```

#### 3. 疑難排錯
- **偵測不到**：拔掉手機 USB 線，等待 3 秒後重新插上。
- **權限問題**：執行 `sudo adb kill-server && sudo adb devices`。
- **確認狀態**：在 WSL2 執行 `lsusb` 與 `adb devices` 應看到裝置序號且狀態為 `device`。

---

## ⚙️ 設定檔說明 (.env)

| 變數名 | 說明 | 預設值 |
| :--- | :--- | :--- |
| `X1`, `Y1` | 滑動起始座標 | 500, 1500 |
| `X2`, `Y2` | 滑動結束座標 | 500, 500 |
| `COORD_X_JITTER` | X 軸隨機抖動範圍 (像素) | 10 |
| `COORD_Y_JITTER` | Y 軸隨機抖動範圍 (像素) | 50 |
| `INTERVAL` | 每次滑動的基礎間隔秒數 | 5 |
| `INTERVAL_JITTER` | 隨機額外等待上限 (秒) | 2 |
| `TOTAL_DURATION` | 總執行秒數 (0 代表無限循環) | 0 |
| `KILL_ADB_ON_EXIT` | 結束時是否關閉 ADB Server (true/false) | false |

## 📂 專案結構

- `autoswipe.sh`: 入口腳本。
- `lib/core.sh`: 核心功能模組。
- `.env`: 個人設定檔。
- `devices.conf`: 自動記錄的裝置清單。

## ⚠️ 注意事項

- **螢幕座標**：請開啟手機「開發者選項」中的「指標位置」來精確獲取您的滑動座標。
- **配對一次性**：Wi-Fi 配對成功後，只要不手動在手機取消，下次只需輸入連線 Port 即可。
- **環境清理**：腳本結束時會自動執行 Cleanup 流程，不影響其他 ADB session。

---
*不可言，本人自有妙用 ~*