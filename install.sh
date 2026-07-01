#!/bin/bash
set -euo pipefail

APP=/Applications/Claude.app
RES=$(cd "$(dirname "$0")" && pwd)

log() { echo "$*"; }

quit_claude() {
    pkill -f "Claude" 2>/dev/null || true
    sleep 1
}

get_js_bundle() {
    python3 -c "
import re
with open('$APP/Contents/Resources/ion-dist/index.html') as f:
    m = re.search(r'src=\"(/assets/v1/index-[^\"]+\.js)\"', f.read())
    print(m.group(1) if m else '')
"
}

# 安装 App 层翻译：合并中文 → en-US.json
install_app_locale() {
    local target="$APP/Contents/Resources/ion-dist/i18n/en-US.json"
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

print(f'en-US: {translated} translated, {fallback} fallback')
PYEOF
    log "App locale installed (en-US -> Chinese)"
}

# 安装 Dynamic 层
install_dynamic_locale() {
    cp "$RES/zh-CN-statsig.json" "$APP/Contents/Resources/ion-dist/i18n/dynamic/en-US.json"
    log "Dynamic locale installed"
}

# 安装 Shell 层
install_shell_locale() {
    cp "$RES/zh-CN-shell.json" "$APP/Contents/Resources/en-US.json"
    log "Shell locale installed"
}

# 补丁：阻止服务端 bootstrap locale 覆盖
patch_ont() {
    local js_path
    js_path=$(get_js_bundle)
    if [ -z "$js_path" ]; then
        log "Error: cannot find main JS bundle"
        exit 1
    fi
    local full_path="$APP/Contents/Resources/ion-dist$js_path"

    # 幂等检查
    python3 -c "
with open('$full_path') as f:
    c = f.read()
if 'function ont(){return null}' in c:
    exit(0)
exit(1)
" && { log "ont() already patched"; return; }

    python3 << PYEOF
with open("$full_path") as f:
    content = f.read()

old = 'function ont(){const t=__(e=>e.setLocaleOverride);return e.useEffect(()=>{let e=!1;return vQ().then(s=>{if(e||!s?.locale)return;const n=IS([s.locale]);try{localStorage.setItem(ant,n)}catch{}n!==int&&t(n)}),()=>{e=!0}},[t]),null}'
new = 'function ont(){return null}'

if old in content:
    content = content.replace(old, new, 1)
    with open("$full_path", "w") as f:
        f.write(content)
    print("ont() patched to no-op")
else:
    print("Error: ont() pattern not found")
    exit(1)
PYEOF
    log "ont() patch installed"
}

restore_en_us() {
    # 从备份还原原始 en-US
    if [ -f /tmp/en-US.json.bak ]; then
        cp /tmp/en-US.json.bak "$APP/Contents/Resources/ion-dist/i18n/en-US.json"
        log "en-US.json restored from backup"
    fi
    if [ -f /tmp/en-US-dynamic.json.bak ]; then
        cp /tmp/en-US-dynamic.json.bak "$APP/Contents/Resources/ion-dist/i18n/dynamic/en-US.json"
    fi
    if [ -f /tmp/en-US-shell.json.bak ]; then
        cp /tmp/en-US-shell.json.bak "$APP/Contents/Resources/en-US.json"
    fi
}

restore_patch() {
    local js_path
    js_path=$(get_js_bundle)
    if [ -z "$js_path" ]; then
        log "Warning: cannot find JS bundle, skipping patch restore"
        return
    fi
    local full_path="$APP/Contents/Resources/ion-dist$js_path"

    python3 << PYEOF
with open("$full_path") as f:
    content = f.read()

old = 'function ont(){return null}'
new = 'function ont(){const t=__(e=>e.setLocaleOverride);return e.useEffect(()=>{let e=!1;return vQ().then(s=>{if(e||!s?.locale)return;const n=IS([s.locale]);try{localStorage.setItem(ant,n)}catch{}n!==int&&t(n)}),()=>{e=!0}},[t]),null}'

if old in content:
    content = content.replace(old, new, 1)
    with open("$full_path", "w") as f:
        f.write(content)
    print("ont() restored")
else:
    print("ont() not found (already restored or never patched)")
PYEOF
    log "Patch restored"
}

case "${1:-install}" in
    install)
        quit_claude

        # 备份原始 en-US 文件（仅首次安装时备份）
        [ ! -f /tmp/en-US.json.bak ] && cp "$APP/Contents/Resources/ion-dist/i18n/en-US.json" /tmp/en-US.json.bak 2>/dev/null || true
        [ ! -f /tmp/en-US-dynamic.json.bak ] && cp "$APP/Contents/Resources/ion-dist/i18n/dynamic/en-US.json" /tmp/en-US-dynamic.json.bak 2>/dev/null || true
        [ ! -f /tmp/en-US-shell.json.bak ] && cp "$APP/Contents/Resources/en-US.json" /tmp/en-US-shell.json.bak 2>/dev/null || true
        log "Backup saved"

        install_app_locale
        install_dynamic_locale
        install_shell_locale
        patch_ont
        log "Done! Launching Claude..."
        open -a "$APP"
        ;;
    restore)
        quit_claude
        restore_en_us
        restore_patch
        log "Restored. Launching Claude..."
        open -a "$APP"
        ;;
    *)
        echo "Usage: $0 [install|restore]"
        exit 1
        ;;
esac
