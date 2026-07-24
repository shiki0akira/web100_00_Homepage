# web100_00_Homepage

Web100 系列的作品集入口首頁。純 HTML/CSS/JS，沒有框架、沒有 build 步驟，部署在 Vercel，綁定正式網域 `www.vibeweb100.com`。

## 先讀這個

完整架構規劃在同一個 repo 的 `ARCHITECTURE.md`，包含子路徑策略、Cloudflare Worker 路由總機規劃、repo 命名慣例、共用 design tokens、網址結構規則。改動任何跟路由/新專案接入有關的東西之前，先看那份文件。

## 這個 repo 的職責

- 網域根目錄 `/` 與各語言首頁 `/{lang}/`
- **暫時**透過 `vercel.json` 的 rewrite 把 `/avalon/*` 代理到阿瓦隆自己的 Vercel 部署（`web100_01_Avalon-Voice`），等 Cloudflare Worker 路由總機做好後這段代理規則要整段移除

## 加新專案時要改的地方（例如加 `web100_02_BuzzerGame`）

1. `index.html` 的 `STRINGS` 物件裡，每個語言都加上新專案的卡片文案（`xxxTitle`、`xxxDesc`、`xxxTag`）
2. `vercel.json` 的 `rewrites` 加一條 `/buzzer/:path*` 代理規則（放在同類規則旁邊即可，語言判斷用的萬用規則在最後，不受影響）
3. `sitemap.xml` 視需要補上新專案網址
4. 更新 `ARCHITECTURE.md` 第 9 節的進度追蹤表

## 語言判斷邏輯

- 網址帶語言（`/ja/`）→ 直接用
- 網址沒帶語言（`/`）→ 依序看 `localStorage['web100-lang']`、`web100_lang` cookie，都沒有用預設語言 `zh-TW`
- 使用者手動切換時，`persistLangPreference()` 會同時寫 `localStorage` 跟 `web100_lang` cookie（`path=/`，全站共用）——這個 cookie 名稱跟寫法要跟其他 Web100 專案保持一致，不要各專案各自發明一套

## vercel.json 的規則順序很重要

`/avalon/:path*` 這條代理規則必須排在語言萬用規則（`/:lang(zh-TW|en|...)`）**之前**，不然 Vercel 會先比對到語言規則。以後每加一個新專案的代理規則，都要放在語言萬用規則之前。
