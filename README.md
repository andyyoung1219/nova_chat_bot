# NASA Cosmos Messenger

一款以 NASA 每日天文圖（APOD）為核心的 Android 對話 App，透過與 AI 助理「Nova」聊天，探索宇宙每一天的樣貌。

---

## 專案架構

```
lib/
├── main.dart                  # App 入口、MaterialApp 設定
├── UI/
│   └── main_ui.dart           # BottomNavigationBar，切換 Tab
├── pages/
│   ├── chat/
│   │   └── chat_page.dart     # Nova 聊天介面
│   ├── collect/
│   │   └── collect_page.dart  # 收藏瀏覽介面
│   └── cards/
│       └── sky_card.dart      # 生日星空卡元件
├── services/
│   ├── nasa_api_service.dart  # NASA APOD API 呼叫 + 離線降級
│   ├── storage_service.dart   # SQLite 快取 & 收藏管理
│   ├── speech_service.dart    # 語音辨識封裝
│   └── share_service.dart     # 截圖 & 系統分享
└── data/
    ├── nasa_api_data.dart     # APOD 資料模型
    └── message_model.dart     # 聊天訊息模型
```

### 架構選擇說明

整體採用 **Service 層分離** 的設計原則，將所有邏輯從 UI 層抽離，封裝為各自獨立的 Service 類別。Widget 只負責畫面狀態的管理與呈現，不直接處理 API、資料庫或硬體操作，讓各模組職責清晰、易於維護與擴充。

#### NasaApiService — NASA API 呼叫與離線降級
負責對 NASA 的網路請求。請求前先檢查網路連線，並優先讀取本機快取；有網路時才發出 HTTP 請求，失敗或逾時則自動降級回快取，並透過 callback 通知 UI 層。

#### StorageService — SQLite 本機儲存
以 Singleton 模式管理單一關聯式資料庫連線，內含 `cache`（FIFO 快取，上限 10 筆）與 `favorites`（使用者收藏）兩張職責分離的資料表。
當收藏異動時自動通知 UI 更新，無需手動傳遞 callback。

#### SpeechService — 語音辨識封裝
使用 `speech_to_text` 套件，對外提供初始化、開始、停止三個簡潔介面。
辨識狀態透過 callback 回傳給 UI 層，Service 本身不持有任何 Widget 參考，維持單向依賴。

#### ShareCardManager — 截圖與系統分享
以靜態方法封裝截圖與分享的完整流程，接收 `GlobalKey` 對 `SkyCard` 元件進行截圖，輸出 PNG 後呼叫系統分享介面，回傳 `bool` 讓呼叫端處理結果提示。

---

## 支援的日期格式

Nova 的日期解析器以正規表達式實作，支援以下格式輸入：

| 格式 | 範例 |
|------|------|
| `YYYY/MM/DD` | `2026/04/20` |
| `YYYY-MM-DD` | `2026-04-20` |
| `YYYY年MM月DD日` | `2026年4月20日` |
| `YYYY MM DD`（空格分隔） | `2026 04 20` |

**日期合法性驗證規則：**
- 最早日期：`1995-06-16`（NASA APOD 首日）
- 最晚日期：今天（不接受未來日期）
- 自動檢查日期進位（例如 2月30日 會被拒絕）

---

## Bonus 功能

### 離線快取
將已查詢過的 APOD 資料存入 SQLite `cache` 表，採 FIFO 策略最多保留 10 筆。離線時執行三層降級：

1. 查詢指定日期的快取
2. 取得最新一筆快取作為備援
3. 以上皆無則拋出例外，回覆錯誤訊息

### 分享星空卡
在收藏 Tab 點擊蛋糕圖示，可為任一 APOD 圖片製作「生日星空卡」：
- 輸入壽星名字（選填，最多 15 字）
- 即時預覽深色宇宙風格卡片
- 點擊分享後，截圖輸出為 PNG 並呼叫系統分享介面

### 語音輸入
聊天室輸入框旁提供麥克風按鈕，支援繁體中文（`zh_TW`）、基礎英文語音辨識，輸入時，麥克風變紅提示使用者正在辨識。

---

## 使用套件

| 套件 | 用途 |
|------|------|
| `http` | 網路請求 |
| `sqflite` | 本機 SQLite 資料庫 |
| `cached_network_image` | 圖片快取與載入 |
| `flutter_dotenv` | 管理 API Key |
| `speech_to_text` | 語音辨識 |
| `share_plus` | 系統分享 |
| `path_provider` | 取得裝置暫存路徑 |

---

## 環境設定

在專案根目錄建立 `.env.example` 檔案，填入 NASA API Key，並改名為 `.env`：

```
NASA_API_KEY=your_api_key_here
```

> 可至 [https://api.nasa.gov/](https://api.nasa.gov/) 免費申請。