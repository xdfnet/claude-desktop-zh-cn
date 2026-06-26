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
    ls "$APP/Contents/Resources/ion-dist/assets/v1/"*.js 2>/dev/null
}

patch_locale_map() {
    local js="$1"
    python3 - "$js" << 'PYEOF'
import re, sys

js = sys.argv[1]
with open(js) as f:
    content = f.read()

# In v1.15962.0, locale map: const uze={"en-US":"en","de-DE":"de",...}
# Note: hi-IN→"en", pt-BR→"pt_BR" in this version
m = re.search(r'const\s+\w+\s*=\s*\{"en-US":"en"[^}]+\}', content)
if not m:
    sys.exit(0)

orig = m.group(0)
if '"zh-CN"' in orig:
    sys.exit(0)

# Insert zh-CN before the closing brace
patched = orig[:-1] + ',"zh-CN":"zh"}'
content = content.replace(orig, patched, 1)
with open(js, 'w') as f:
    f.write(content)
print('  locale map: zh-CN added')
PYEOF
}

patch_lang_array() {
    local js="$1"
    python3 - "$js" << 'PYEOF'
import re, sys

js = sys.argv[1]
with open(js) as f:
    content = f.read()

# In v1.15962.0: DW=["en-US","de-DE","fr-FR","ko-KR","ja-JP","es-419","es-ES","it-IT","hi-IN","pt-BR","id-ID"]
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

# Pattern: case"id-ID":return["language","id"];default:return t
m = re.search(r'case"id-ID":return\["language","id"\];default:return\s+t', content)
if not m:
    sys.exit(0)

orig = m.group(0)
# Also handle default:return t vs default:return r (variable name may differ)
# The pattern is: ...;default:return <var>
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

install_resources_locale() {
    local src="$RES/zh-CN-shell.json"
    local dst="$APP/Contents/Resources/zh-CN.json"
    if [ -f "$src" ]; then
        cp "$src" "$dst"
        log "Resources locale installed"
    fi
}

install_locale() {
    local target="$APP/Contents/Resources/ion-dist/i18n/zh-CN.json"
    python3 - "$APP" "$RES" "$target" << 'PYEOF'
import json, sys

app, res, target = sys.argv[1], sys.argv[2], sys.argv[3]

try:
    en = json.load(open(f'{app}/Contents/Resources/ion-dist/i18n/en-US.json'))
    zh = json.load(open(f'{res}/zh-CN-app.json'))
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
    log "App locale installed"
}

install_dynamic_locale() {
    local target="$APP/Contents/Resources/ion-dist/i18n/dynamic/zh-CN.json"
    cp "$RES/zh-CN-statsig.json" "$target"
    log "Dynamic locale installed"
}

case "${1:-install}" in
    install)
        quit_claude
        log "Patching JS files..."
        for js in $(find_v1_js); do
            # Locale map and lang array are in the same JS file (content-hash named)
            # Persona switch is in a separate file — check all for safe idempotency
            patch_locale_map "$js"
            patch_lang_array "$js"
            patch_persona_switch "$js"
        done
        install_locale
        install_resources_locale
        install_dynamic_locale
        log "Done! Launching Claude..."
        open -a "$APP"
        ;;
    restore)
        quit_claude
        rm -f "$APP/Contents/Resources/ion-dist/i18n/zh-CN.json"
        rm -f "$APP/Contents/Resources/ion-dist/i18n/dynamic/zh-CN.json"
        rm -f "$APP/Contents/Resources/zh-CN.json"
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
