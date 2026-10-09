#!/usr/bin/env bash
# Builds the Webflow embeds from the readable sources.
#   dist/webflow-head.html    → paste into Pricing page settings, "Inside <head> tag"
#   dist/webflow-footer.html  → paste into Pricing page settings, "Before </body> tag"
# Webflow caps each slot at 50,000 characters, so the JS and CSS are minified.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p dist
npx -y esbuild@0.25.5 plan-checkout.js --minify --target=es2017 --log-level=warning --outfile=dist/plan-checkout.min.js
npx -y esbuild@0.25.5 plan-modals.css  --minify --log-level=warning --outfile=dist/plan-modals.min.css
{ printf '<style>'; cat dist/plan-modals.min.css; printf '</style>\n'; } > dist/webflow-head.html
{ printf '<script src="https://js.stripe.com/v3/"></script>\n<script>'; cat dist/plan-checkout.min.js; printf '</script>\n'; } > dist/webflow-footer.html
for f in dist/webflow-head.html dist/webflow-footer.html; do
  printf '%-26s %6d chars\n' "$f" "$(wc -c < "$f")"
done
# dist/preview.html: the page as Webflow will run it (minified embeds inlined), for local QA.
python3 - <<'PY'
import re
s = open('Merged Plan Selection.html').read()
head = open('dist/webflow-head.html').read()
foot = open('dist/webflow-footer.html').read()
s = s.replace('<link rel="stylesheet" href="plan-selection.css">', '<link rel="stylesheet" href="../plan-selection.css">')
s = s.replace('src="asi-gold-logo.png"', 'src="../asi-gold-logo.png"')
s = re.sub(r'<link rel="stylesheet" href="plan-modals.css">\s*<script src="https://js.stripe.com/v3/"></script>', head.strip(), s)
s = s.replace('<script src="plan-checkout.js"></script>', foot.strip())
open('dist/preview.html', 'w').write(s)
PY
echo "dist/preview.html written"
