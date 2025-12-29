# AutoSwipe - Android Wireless ADB 自动化工具

一个極簡、無依賴的 Bash 腳本，專為 Linux/WSL2 環境設計，透過 Wireless ADB 實現手機螢幕的定時自動滑動。

## 🌟 核心特色

- **智慧連線管理**：自動記錄已配對的手機型號與上次使用的 IP，下次連線更快速。
- **動態 IP 支援**：專為 Wi-Fi 環境設計，即使手機 IP 變動也能輕鬆連線。
- **本地化安全設定**：ADB 金鑰與設定存放在專案內的 `.android/` 目錄，不污染系統環境，且已透過 `.gitignore` 保護。
- **彈性執行模式**：支援「指定總時長」或「無限循環」模式。
- **使用者友善**：
  - 互動式引導配對與連線。
  - 開始執行前會暫停，留給使用者切換到目標 App 的時間。
  - 即時顯示滑動次數、已用時間或剩餘時間。
- **環境清理**：結束時自動斷開 ADB 連線，並可設定是否自動關閉 ADB Server。

## 🛠 運作環境

- **OS**: Linux (在 Ubuntu 24 / WSL2 測試通過)
- **依賴**: `adb` (Android Debug Bridge)

## 🔌 WSL2 USB 連接 (可選)

若您偏好透過 USB 連接手機而非 Wi-Fi，建議在 Windows 端安裝 **usbipd-win**。

### 1. Windows 端安裝 (管理員權限 PowerShell)
```powershell
# 安裝核心引擎 (微軟官方推薦)
winget install dorssel.usbipd-win

# (可選) 安裝圖形化管理介面
winget install nickbeth.wsl-usb-manager
```
*安裝完後，請重新啟動電腦或重啟 PowerShell 以生效。*

### 2. WSL2 端安裝
```bash
sudo apt update
sudo apt install linux-tools-virtual hwdata
sudo update-alternatives --install /usr/local/bin/usbip usbip `ls /usr/lib/linux-tools/*/usbip | tail -n1` 20
```

### 3. 使用方法

#### A. 首次設定 (Windows 管理員權限 PowerShell)
```powershell
# 1. 確保服務已啟動
# 若希望開機自動執行：
Set-Service usbipd -StartupType Automatic
# 若希望手動啟動 (推薦)：
Set-Service usbipd -StartupType Manual

Start-Service usbipd

# 2. 列出所有 USB 裝置並找到手機的 BUSID (例如 2-3)
usbipd list

# 3. 綁定裝置 (只需做一次)
usbipd bind --busid <BUSID>
```

#### B. 日常連線流程
1. **Windows 端**：`usbipd attach --wsl --busid <BUSID>` (或使用圖形介面點擊 Attach)。
2. **WSL2 端**：
   - 執行 `lsusb` 確認是否有看到裝置。
   - 執行 `adb devices` 確認狀態。
     - *注意：若顯示為空，請檢查手機「USB 偵錯」是否開啟，並點擊手機上的「允許連線」彈窗。*
     - *若仍偵測不到，可嘗試 `sudo adb kill-server && sudo adb devices`。*
3. **啟動腳本**：執行 `./autoswipe.sh`，選單中將會出現「在線裝置」選項。

#### C. 疑難排錯：無法成功 Attach 時
若遇到裝置被 Windows 佔用或 Attach 失敗，請嘗試以下強制重新連接步驟：
1. **解除綁定**：`usbipd unbind --busid <BUSID>`
2. **強制綁定**：`usbipd bind --busid <BUSID> --force`
3. **實體重插**：拔掉手機 USB 線，等待約 3 秒後重新插上。
4. **重新執行連接**：`usbipd attach --wsl --busid <BUSID>`

#### D. 如何確認 USB 是否正常運作
在 WSL2 終端機執行以下指令：
- **檢查硬體層**：`lsusb`
  - 應看到 `Samsung Electronics Co., Ltd Galaxy series` 或類似字樣。
- **檢查軟體層**：`adb devices`
  - 應看到裝置序號且狀態為 `device`。
- **檢查連線日誌**：`dmesg | tail`
  - 成功連接時應看到 `new high-speed USB device` 相關訊息。

#### E. 停止連線與還原
- **中斷連線 (還原給 Windows)**：`usbipd detach --busid <BUSID>`。
- **停止服務**：`Stop-Service usbipd` (若暫時不想使用此功能)。

## 🚀 快速開始

### 1. 安裝必要工具
在 Ubuntu/WSL2 中執行：
```bash
sudo apt update && sudo apt install adb -y
```

### 2. 手機端設定
1. 進入「開發者選項」，啟用「無線偵錯」。
2. 點擊「無線偵錯」，記下畫面上顯示的 **IP 地址與通訊埠**（連線用）。
3. 點擊「使用配對碼配對裝置」，記下 **配對碼** 與 **IP 地址及通訊埠**（配對用）。

### 3. 設定專案
複製 `.env.example` 並更名為 `.env`，修改座標與參數：
```bash
cp .env.example .env
nano .env
```

### 4. 執行腳本
```bash
./autoswipe.sh
```

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

- `autoswipe.sh`: 主程式腳本。
- `.env`: 個人設定檔（不提交至 Git）。
- `devices.conf`: 已記錄的裝置清單（自動產生，不提交至 Git）。
- `.android/`: 存放 ADB 安全金鑰的目錄（自動產生，不提交至 Git）。
- `conductor/`: 專案開發計畫與軌道紀錄。

## ⚠️ 注意事項

- **螢幕座標**：請開啟手機「開發者選項」中的「指標位置」來精確獲取您的滑動座標。
- **配對一次性**：配對 (Pairing) 成功後，只要不手動在手機取消，下次只需輸入連線 Port 即可。
- **WSL2 用戶**：確保您的手機與電腦網路互通（通常是連接在同一個 Wi-Fi 下）。若連線失敗，請檢查 Windows 防火牆設定。

---
*不可言，本人自有妙用 ~*
