# Web100 首頁

Web100 系列小遊戲/小工具的作品集入口首頁，純 HTML/CSS/JS，不用框架，部署在 Vercel，綁定正式網域 `www.vibeweb100.com`。

## 架構說明

- 這個專案負責網域根目錄 `/` 與各語言首頁 `/{lang}/`
- `/avalon/*` 目前透過 `vercel.json` 的 rewrite **暫時代理**到阿瓦隆語音自己的 Vercel 部署（`web100_01_Avalon-Voice`）
  - 之後 Cloudflare Worker 路由總機做好後，這段代理規則會整段移除，改由 Worker 統一處理所有子專案的路由
- 每加一個新的 Web100 子專案（例如 `web100_02_BuzzerGame`），要做的事：
  1. 在 `index.html` 的 `STRINGS` 裡加上新專案的卡片文案（每個語言都要）
  2. 在 `vercel.json` 的 `rewrites` 裡加一條 `/{新專案代號}/*` 代理規則（或等 Worker 做好後改到 Worker 設定）
  3. 在 `sitemap.xml` 視需要補上新專案的網址

## 語言判斷邏輯

1. 網址帶語言（`/ja/`）→ 直接用該語言
2. 網址沒帶語言（`/`）→ 依序看 `localStorage['web100-lang']` 與 `web100_lang` cookie，都沒有就用預設語言（`zh-TW`）
3. 使用者手動切換語言時，同時寫入 `localStorage` 與 `web100_lang` cookie（`path=/`，全站共用）
4. `web100_lang` cookie 之後會給 Cloudflare Worker 讀取，用來做「訪客 IP 地區 → 自動判斷語言」，且 cookie 優先權高於 IP 猜測（使用者手動選過就不會再被地區覆蓋）

## 共用設計代幣

視覺樣式沿用 Web100 架構規劃文件裡的 `design-tokens.css` 規則（深色系、紫藍色主色調），之後每個新專案都比照這份風格手動實作。
