#!/usr/bin/env bash
#
# 檢查「整個網域的 404 都倒向首頁那一頁」還成不成立（ARCHITECTURE.md 第 3.1 節）。
# 每次加新專案、或改 vercel.json 的代理規則之後跑一次；部署完才跑，線上規則才是新的。
#
#   bash scripts/check-404.sh
#
# 加新專案時：把它底下亂打的網址加進 WANT_404，把它實際存在的網址加進 MUST_WORK。
set -u
BASE=${1:-https://www.vibeweb100.com}

# 這些都不存在，應該回 404 + 首頁那張 404 頁
WANT_404="
/nope
/zh-TW/nope
/avalon/nope
/avalon/zh-TWkk
/avalon/zh-TW/nope
/avalon/zh-TW/game/nope
/buzzer/nope
/buzzer/zh-TWkk
/buzzer/zh-TW/nope
/newproject/whatever
"

# 白名單漏列就會從 200 變 404，所以每一條實際存在的路徑都要在這裡
MUST_WORK="
307 /
200 /zh-TW/
200 /404.html
307 /avalon
200 /avalon/zh-TW
200 /avalon/zh-TW/game
200 /avalon/zh-TW/rules
200 /avalon/favicon.svg
200 /avalon-sitemap.xml
302 /buzzer
302 /buzzer/
200 /buzzer/zh-TW/
200 /buzzer/zh-TW/rules/
200 /buzzer/app.js
200 /buzzer/app.css
200 /buzzer/header.js
200 /buzzer/vendor/qrcode.js
200 /buzzer/favicon.svg
200 /buzzer/sitemap.xml
200 /buzzer-sitemap.xml
"

fail=0

echo "== 應該回 404 + 首頁那張 404 頁 =="
for u in $WANT_404; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE$u")
  body=$(curl -s "$BASE$u")
  # id="home-btn" 只有首頁的 404.html 有，用它區分「我們的 404」和「子專案自己的 404」
  case "$body" in *'id="home-btn"'*) page=本站404 ;; *) page=別人的404 ; fail=1 ;; esac
  [ "$code" = 404 ] || { code="$code(該是404)"; fail=1; }
  printf '  %-30s %-16s %s\n' "$u" "$code" "$page"
done

echo
echo "== 這些不能壞 =="
echo "$MUST_WORK" | while read -r want u; do
  [ -z "${u:-}" ] && continue
  got=$(curl -s -o /dev/null -w '%{http_code}' "$BASE$u")
  if [ "$got" = "$want" ]; then printf '  %-30s %s\n' "$u" "$got"
  else printf '  %-30s %s（該是 %s）\n' "$u" "$got" "$want"; fi
done

echo
[ "$fail" = 0 ] && echo "404 全部倒向同一頁。" || echo "有沒倒過來的，看上面那組。"
