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
**運作原理**：透過 `usbipd` 工具將 Windows 主機的實體 USB 訊號轉換為網路協定，轉發至 WSL2 虛擬機中。對 WSL2 而言，這台手機就像是直接插在 Linux 實體主機上的 USB 裝置，穩定度高且不需開啟無線偵錯。

#### 1. Windows 端安裝 (管理員權限 PowerShell)
```powershell
winget install dorssel.usbipd-win
# (可選) 圖形管理介面
winget install nickbeth.wsl-usb-manager
```

#### 2. Windows 端首次設定與綁定
```powershell
# 1. 確保服務已啟動 (推薦設為 Manual)
Set-Service usbipd -StartupType Manual
Start-Service usbipd

# 2. 列出所有 USB 裝置並找到手機的 BUSID
usbipd list

# --- 真實案例輸出範例 ---
# BUSID  VID:PID    DEVICE                                                        STATE
# 1-3    04e8:6860  MyS23, SAMSUNG Mobile USB Modem, ADB Interface             Not shared
# 1-6    04f3:0c6e  ELAN WBF Fingerprint Sensor                                   Not shared
# -----------------------
# 在此範例中，手機的 BUSID 為 1-3

# 3. 綁定裝置 (只需做一次，若被佔用可加 --force)
usbipd bind --busid 1-3 --force
```

#### 3. 日常連接流程
1. **Windows 端**：執行 `usbipd attach --wsl --busid <BUSID>`。
2. **WSL2 端**：
   - 執行 `lsusb` 確認是否有看到裝置。
   - 執行 `adb devices` 確認狀態。
     - *注意：若顯示為空，請檢查手機「USB 偵錯」是否開啟，並點擊手機上的「允許連線」彈窗。*
3. **啟動腳本**：執行 `./autoswipe.sh`，選單中將會出現 `[在線]` 裝置選項。

#### 4. 疑難排錯：無法成功 Attach 時
若遇到裝置被 Windows 佔用或 Attach 失敗，請嘗試以下強制重新連接步驟：
1. **解除綁定**：`usbipd unbind --busid <BUSID>`
2. **強制綁定**：`usbipd bind --busid <BUSID> --force`
3. **實體重插**：拔掉手機 USB 線，等待約 3 秒後重新插上。
4. **重新執行連接**：`usbipd attach --wsl --busid <BUSID>`

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
