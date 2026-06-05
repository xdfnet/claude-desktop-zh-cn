#!/bin/bash
set -euo pipefail

APP=/Applications/Claude.app
RES=$(cd "$(dirname "$0")" && pwd)

log() { echo "$*"; }

quit_claude() {
    pkill -f "Claude" 2>/dev/null || true
    sleep 1
}

find_v1_js() {
    # Returns all JS files in v1 dir
    ls "$APP/Contents/Resources/ion-dist/assets/v1/"*.js 2>/dev/null
}

patch_w8_map() {
    local js="$1"
    python3 - "$js" << 'PYEOF'
import re, sys

js = sys.argv[1]
with open(js) as f:
    content = f.read()

# const w8={"en-US":"en","de-DE":"de",...}
m = re.search(r'const\s+\w+\s*=\s*\{"en-US":"en"[^}]+\}', content)
if not m:
    sys.exit(0)

orig = m.group(0)
if '"zh-CN"' in orig:
    sys.exit(0)

patched = orig[:-1] + ',"zh-CN":"zh"}'
content = content.replace(orig, patched, 1)
with open(js, 'w') as f:
    f.write(content)
print('  w8 map: zh-CN added')
PYEOF
}

patch_lang_array() {
    local js="$1"
    python3 - "$js" << 'PYEOF'
import re, sys

js = sys.argv[1]
with open(js) as f:
    content = f.read()

m = re.search(r'\["en-US","de-DE","fr-FR","ko-KR","ja-JP","es-419","es-ES","it-IT","hi-IN","pt-BR","id-ID"\]', content)
if not m:
    sys.exit(0)

orig = m.group(0)
if '"zh-CN"' in orig:
    sys.exit(0)

patched = orig[:-1] + ',"zh-CN"]'
content = content.replace(orig, patched, 1)
with open(js, 'w') as f:
    f.write(content)
print('  lang array: zh-CN added')
PYEOF
}

patch_persona_switch() {
    local js="$1"
    python3 - "$js" << 'PYEOF'
import re, sys

js = sys.argv[1]
with open(js) as f:
    content = f.read()

if 'case"zh-CN"' in content:
    sys.exit(0)

# Pattern: case"id-ID":return["language","id"];default:return r
m = re.search(r'case"id-ID":return\["language","id"\];default:', content)
if not m:
    sys.exit(0)

orig = m.group(0)
patched = orig.replace(';default:', ';case"zh-CN":return["language","zh"];default:')
content = content.replace(orig, patched, 1)
with open(js, 'w') as f:
    f.write(content)
print('  persona switch: zh-CN added')
PYEOF
}

remove_zhcn_from_file() {
    local js="$1"
    python3 - "$js" << 'PYEOF'
import sys

js = sys.argv[1]
with open(js) as f:
    content = f.read()

if '"zh-CN"' not in content:
    sys.exit(0)

original = content

# Remove from object format
content = content.replace(', "zh-CN":"zh"', '')
content = content.replace(',"zh-CN":"zh"', '')

# Remove from array format
content = content.replace(', "zh-CN"', '')
content = content.replace(',"zh-CN"', '')

# Remove persona switch case
content = content.replace(';case"zh-CN":return["language","zh"]', '')

if content != original:
    with open(js, 'w') as f:
        f.write(content)
    print('  zh-CN references removed')
PYEOF
}

install_locale() {
    local target="$APP/Contents/Resources/ion-dist/i18n/zh-CN.json"
    python3 - "$APP" "$RES" "$target" << 'PYEOF'
import json, sys

app, res, target = sys.argv[1], sys.argv[2], sys.argv[3]

try:
    en = json.load(open(f'{app}/Contents/Resources/ion-dist/i18n/en-US.json'))
    zh = json.load(open(f'{res}/zh-CN.json'))
except FileNotFoundError as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)

merged = {}
translated = fallback = 0
for k, v in en.items():
    if k in zh:
        merged[k] = zh[k]
        if zh[k] != v:
            translated += 1
    else:
        merged[k] = v
        fallback += 1

with open(target, 'w') as out:
    json.dump(merged, out, ensure_ascii=False, indent=2)
    out.write('\n')

print(f'zh-CN: {translated} translated, {fallback} fallback')
PYEOF
    log "Locale installed"
}

install_statsig() {
    local target="$APP/Contents/Resources/ion-dist/i18n/statsig/zh-CN.json"
    cp "$RES/statsig-zh-CN.json" "$target"
    log "Statsig locale installed"
}

case "${1:-install}" in
    install)
        quit_claude
        log "Patching JS files..."
        for js in $(find_v1_js); do
            patch_w8_map "$js"
            patch_lang_array "$js"
            patch_persona_switch "$js"
        done
        install_locale
        install_statsig
        log "Done! Launching Claude..."
        open -a "$APP"
        ;;
    restore)
        quit_claude
        rm -f "$APP/Contents/Resources/ion-dist/i18n/zh-CN.json"
        rm -f "$APP/Contents/Resources/ion-dist/i18n/statsig/zh-CN.json"
        log "Removed zh-CN locale files"
        log "Restoring JS files..."
        for js in $(find_v1_js); do
            remove_zhcn_from_file "$js"
        done
        log "Restored. Launching Claude..."
        open -a "$APP"
        ;;
    *)
        echo "Usage: $0 [install|restore]"
        exit 1
        ;;
esac
