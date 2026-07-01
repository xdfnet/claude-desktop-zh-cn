# 架构说明

## 汉化策略：替换英文

Claude Desktop 官方不支持中文。汉化策略：**将英文（en-US）翻译文件替换为简体中文**。

### 为什么替换英文而不是新建 zh-CN？

1. **en-US 是系统默认回退语言** — 无论系统语言怎么设，最终都会回退到英文
2. **无需符号链** — 直接替换 en-US，不存在 locale 匹配问题
3. **只需一个简单 JS 补丁** — 阻止服务端 bootstrap 语言覆盖即可

## 三层翻译

| 层 | 源文件 | 目标路径 | 条目 | 类型 |
|---|---|---|---|---|
| **App** | `zh-CN-app.json` | `ion-dist/i18n/en-US.json` | 16,295 | 应用内 Web UI |
| **Dynamic** | `zh-CN-statsig.json` | `ion-dist/i18n/dynamic/en-US.json` | 46 | 模型选择标签、A/B 测试 |
| **Shell** | `zh-CN-shell.json` | `Resources/en-US.json` | 435 | 原生界面（菜单、对话框） |

- **App**：与 `en-US.json` merge，未翻译 key 保留英文作为 fallback
- **其余**：直接拷贝

## JS 补丁（1 处）

因新版 Web App 通过 bootstrap 请求获取 `locale` 字段并用其覆盖系统语言，需要阻止此行为。

**补丁位置**：`index-*.js` 中的 `ont()` 组件

**补丁内容**：

```javascript
// 补丁前：从服务端 bootstrap 获取 locale 并覆盖
function ont() {
  const setLocaleOverride = __(e => e.setLocaleOverride);
  return e.useEffect(() => {
    let cleanup = false;
    return vQ().then(s => {
      if (cleanup || !s?.locale) return;
      const n = IS([s.locale]);
      n !== int && setLocaleOverride(n);  // ← 覆盖系统语言
    }), () => { cleanup = true };
  }, [setLocaleOverride]), null;
}

// 补丁后：空函数，不做 locale 覆盖
function ont() { return null; }
```

**幂等**：检测到 `function ont(){return null}` 已存在则跳过。  
**可还原**：`restore` 回滚到原始函数体。

## 补丁流程

```mermaid
flowchart LR
    A[zh-CN-app.json] --> B[合并 en-US.json]
    B --> C[i18n/en-US.json]
    D[zh-CN-shell.json] --> E[Resources/en-US.json]
    F[zh-CN-statsig.json] --> G[i18n/dynamic/en-US.json]
    H[补丁 ont()] --> I[阻止 bootstrap 覆盖]
```

## 还原流程

1. 从 `/tmp/` 备份还原原始 `en-US.json` / `dynamic/en-US.json` / `Resources/en-US.json`
2. 回滚 JS 补丁（还原 `ont()` 原始代码）

## 文件结构

```
claude-desktop-zh-cn/
├── zh-CN-app.json          简体中文（16,295 条，替换 i18n/en-US.json）
├── zh-CN-shell.json        简体中文（435 条，替换 Resources/en-US.json）
├── zh-CN-statsig.json      Dynamic i18n（46 条，替换 dynamic/en-US.json）
├── ARCHITECTURE.md         架构说明
├── install.sh              安装/还原脚本
└── README.md               使用说明
```

## 关键约束

- **不动代码签名** — 只改 `Resources/` 和 `ion-dist/` 下的文件，macOS 签名不受影响
- **可还原** — 备份原始英文文件，restore 完全回滚
- **增量兼容** — iOS、Web、旧版 Desktop 不受影响
