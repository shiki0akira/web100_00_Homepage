# Web100 系列專案 - 架構規劃文件

目標：以 100 個獨立的 vibecoding 小遊戲/小工具，集中在同一個網域下累積流量與 SEO 權重，最終申請 Google AdSense 產生廣告收益。

## 1. 為什麼選子路徑而不是子網域

全部採用子路徑架構，根網域只有一個，所有小遊戲/工具都掛在它底下的路徑：

```
vibeweb100.com/                  → 作品集首頁（web100_00_Homepage）
vibeweb100.com/avalon/*          → 阿瓦隆語音（web100_01_Avalon-Voice）
vibeweb100.com/buzzer/*          → 搶答遊戲（下一個專案）
vibeweb100.com/game003/*         → 第 3 個專案
```

原因：子路徑下，Google 把所有內容視為同一個網域累積 SEO 權重；AdSense 審核也是以整個網域為單位一次審核，不用每個小工具各自申請。

## 2. 網址結構規則（2026/7 確定）

**遊戲代號在前、語言在後**：`/{game}/{lang}/...`，例如 `/avalon/zh-TW/game`。

這是為了讓 Cloudflare Worker 路由總機只要檢查路徑第一段是不是已知的遊戲代號就能決定轉發去哪，不需要知道有幾種語言。每個新專案的路由（React Router 或其他框架）都要遵守這個順序。

## 3. 技術棧不同時，如何掛在同一個網域下

用 Cloudflare Worker 當整個網域的路由總機，攔截所有進入 vibeweb100.com 的請求，依路徑開頭轉發到對應專案：

```
使用者請求 vibeweb100.com/avalon/xxx
        │
        ▼
  Cloudflare Worker（路由總機）
        │
        ├─ /avalon/*  → reverse proxy 轉發到 Vercel 上的阿瓦隆
        ├─ /buzzer/*  → 轉發到 Cloudflare Pages/Durable Object
        └─ 其他（根路徑 /）→ 回傳作品集首頁
```

**目前狀態（過渡期）**：Cloudflare Worker 還沒做。暫時由 `web100_00_Homepage` 的 `vercel.json` 用 rewrite 直接代理 `/avalon/*` 到阿瓦隆自己的 Vercel 部署網址，等 Worker 做好後這段代理規則會整段移除。

## 4. 前端 vs 前端+後端的部署選擇

| | 純前端（像阿瓦隆） | 有後端/即時連線（像搶答） |
|---|---|---|
| 部署平台 | Vercel | Cloudflare Workers（assets binding + Durable Objects） |
| 原因 | 靜態網頁 + JS，Vercel 免費簡單 | 需要 WebSocket 房間狀態，Vercel serverless function 不支援長連線 |
| 接入方式 | Worker/首頁 rewrite 代理過去 | 本來就在 Cloudflare，Worker 做好後可用 Service Binding 內部呼叫，效能更好 |

搶答（02）實作時確認了：**靜態檔不用另外開 Cloudflare Pages**，同一個 Worker 用 assets binding 就能服務，網頁與 WebSocket 同源、不用處理 CORS，也少一個部署目標。之後需要即時連線的專案照這個做法。

## 5. Repo 策略

維持「一個專案一個 GitHub repo」，不做 monorepo：
- 各專案技術棧、部署平台不同，合併管理反而綁手綁腳
- 一個專案出狀況不會拖累其他專案
- 獨立部署、獨立回滾

命名慣例：`web100_00_Homepage`、`web100_01_Avalon-Voice`、`web100_02_BuzzerGame`……依序編號。

## 6. 語言判斷邏輯

1. 網址帶語言 → 直接用該語言
2. 網址沒帶語言 → 依序看 `localStorage`、`web100_lang` cookie，都沒有就用預設語言（zh-TW）
3. 使用者手動切換語言時，寫入 `web100_lang` cookie（`path=/`，全站共用，供之後 Cloudflare Worker 判斷語言用）
4. Cookie 優先權 > IP 地區猜測（Worker 之後會依訪客 IP 對應語言自動導向，但使用者手動選過的語言不會被地區覆蓋）

## 7. 共用設計代幣

技術棧不同（React+Tailwind / 純 HTML+CSS+JS），無法直接共用元件庫，改為共用一份「規則」。

**唯一來源是 `design-tokens.css`（這個 repo 根目錄），不要把變數複製貼到別的 repo。** 其他專案直接引用正式網址：

```html
<link rel="stylesheet" href="https://www.vibeweb100.com/design-tokens.css">
```

配色來自 Figma 的變數庫（Primary / Secondary / Accent / Neutral 四組色階 + 一組半透明），`design-tokens.css` 裡的 primitive 變數跟 Figma 變數同名，語意層變數（`--color-bg`、`--color-accent`……）再指到 primitive。改配色時先動 Figma、再同步這份檔案，兩邊名字對得上就不會走鐘。

⚠️ `index.html` 的 `<style>` 裡有一份一模一樣的變數副本（內嵌是為了避免首屏閃色），改 `design-tokens.css` 時要兩邊一起改。

要改配色/字級/間距，只改這一份檔案，全系列專案下次部署就會拿到最新值。目前只提供變數，不含選取器樣式規則；深色/淺色是一組 `-light` 後綴的平行變數，怎麼切換（class、data-attribute、prefers-color-scheme）由各專案自己決定——各專案目前的切換機制還不一致（Homepage 用 `body.light` 表示淺色、Avalon 的 Tailwind 用 `darkMode: 'class'` 表示深色），統一這件事留給之後設計 UI 系統時處理。

共用元件規範：
- 圖示：一律用 **Material Symbols Rounded**（24px / wght 400 / GRAD 0 / opsz 24），從 <https://fonts.google.com/icons?icon.style=Rounded> 取。純 HTML 專案直接內嵌 SVG、把 `fill` 改成 `currentColor`（不要載整套字型，一顆圖示不值得多一個網路請求）；React 專案可用 `material-symbols` 套件，但樣式要選 Rounded
- 導覽列：左側 logo/系列名稱（連回首頁），右側放該專案自己的功能按鈕
- 頁尾：一條 `Primary/600` 分隔線，左邊是回首頁連結 `← Web100` + 專案編號（去掉 `web100_` 前綴，例如 `01_Avalon-Voice`），右邊是版權標語 `© 2026 Web100 Series`；640px 以下才斷行堆疊。首頁的頁尾是另一套：只置中放一行 `© 2026 Web100 Series`，沒有回首頁連結也沒有專案編號，不要跟著小專案改
- 導覽列/頁尾的文字維持語言中性（品牌名、專案編號、年份），不進 i18n 檔
- 按鈕：統一圓角、主色、hover 效果
- 按鈕 disabled：跟可點擊時的「立體」語言相反，用「壓扁」表示不能點——拿掉厚度陰影（`box-shadow: none`），底色換成同色階淺兩階、文字用該階對應的深字（例：淺色 `Secondary/800 on Secondary/200` 4.62:1，深色 `Primary/400 on Primary/800` 4.62:1），不要單純疊 `opacity-50`。外框式按鈕例外：本來就沒有厚度可拿，直接整體降到 40% 透明度即可（WCAG 1.4.3 不強制非互動元件的對比度）。不要另外加鎖頭一類的圖示——壓扁的樣式本身就是「不能點」的訊號，不需要疊加解釋
- 卡片容器：統一用 `--color-bg-card`、`--radius`、`--shadow-card`

## 8. AdSense 注意事項

- 子路徑架構下，審核以整個網域為單位
- 風險提醒：Google 對「內容農場」式大量相似小網站堆疊很敏感，100 個專案務必維持「每個都是真正對使用者有用的小工具/遊戲」

## 9. 專案進度追蹤

| 專案 | 狀態 | 部署平台 | 備註 |
|---|---|---|---|
| web100_00_Homepage | 已上線 | Vercel | 暫時代理 /avalon/* 到阿瓦隆 |
| web100_01_Avalon-Voice | 已上線 | Vercel | 已改為 /avalon/{lang}/ 網址結構，已裝 GA4 |
| Cloudflare Worker 路由總機 | 待實作 | Cloudflare Workers | 下一步優先要做的基礎建設 |
| web100_02_BuzzerGame | 開發完成，待部署 | Cloudflare Workers | 單一 Worker 同時服務靜態檔與 Durable Object；本機驗證過，卡在 `wrangler login` 還沒做 |

`web100_02_BuzzerGame` 部署完成後還要補三件事，順序不能顛倒（不然首頁會出現連不到的卡片）：

1. `wrangler deploy`，記下 Worker 的實際網址
2. 首頁 `vercel.json` 加 `/buzzer/:path*` 代理規則（放在語言萬用規則之前）
3. 首頁 `index.html` 的 `STRINGS` 與 `scripts/prerender.js` 加上搶答遊戲的卡片

## 10. 每次開發新專案前的檢查清單

1. 對照第 2 節網址結構規則（遊戲代號在前、語言在後）
2. 對照第 7 節 design tokens
3. 判斷是純前端還是需要後端，選擇對應部署平台（第 4 節）
4. GitHub 開新 repo，依編號命名
5. 在首頁的 `vercel.json`（或 Cloudflare Worker 設定，等做好後）加一條轉發規則
6. 部署完成後更新本文件第 9 節的進度追蹤表
7. 部署完成後更新 `README.md` 的「專案一覽」表格，補上正式網址與 GitHub 連結
