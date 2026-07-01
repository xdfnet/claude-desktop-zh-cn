# 架构说明

## 汉化策略：替换日语

Claude Desktop v1.17377.1 官方支持 en-US / ja-JP / de-DE / fr-FR 等语言，**不支持中文（zh-CN）**。  
汉化策略：**将日语（ja-JP）翻译文件替换为简体中文**，同时建立中文 locale 到日语文件的符号链。

### 为什么替换日语而不是新建 zh-CN？

1. **ja-JP 是官方支持的 locale** — locale 检测系统能正确识别，不会回退到 en-US
2. **Web App 从服务端获取 locale** — bootstrap 返回的 locale 可能覆盖系统语言，新建 zh-CN 无法解决覆盖问题
3. **只需一个简单 JS 补丁** — 阻止服务端 locale 覆盖后，系统 zh-* 语言通过符号链指向 ja-JP 文件

## 四层翻译

| 层 | 源文件 | 目标路径（替换日语） | 条目 | 类型 |
|---|---|---|---|---|
| **App** | `zh-CN-app.json` | `ion-dist/i18n/ja-JP.json` | 18,043 | 应用内 Web UI |
| **Dynamic** | `zh-CN-statsig.json` | `ion-dist/i18n/dynamic/ja-JP.json` | 46 | 模型选择标签、A/B 测试 |
| **Overrides** | `zh-CN-overrides.json` | `ion-dist/i18n/ja-JP.overrides.json` | 344 | 法律条款、连接器状态 |
| **Shell** | `zh-CN-shell.json` | `Resources/ja-JP.json` | 435 | 原生界面（菜单、对话框） |

- **App**：与 `en-US.json` merge，未翻译 key 保留英文作为 fallback
- **其余**：直接拷贝

## 符号链

将系统 locale 路径指向替换后的日语文件，确保 locale 检测走任何 zh-* 路径都能加载中文：

```
i18n/zh-CN.json → ja-JP.json
i18n/zh-Hans-CN.json → ja-JP.json
i18n/zh.json → ja-JP.json
i18n/dynamic/zh-CN.json → ja-JP.json
i18n/dynamic/zh-Hans-CN.json → ja-JP.json
...
```

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
    B --> C[i18n/ja-JP.json]
    D[zh-CN-shell.json] --> E[Resources/ja-JP.json]
    F[zh-CN-statsig.json] --> G[i18n/dynamic/ja-JP.json]
    H[zh-CN-overrides.json] --> I[i18n/ja-JP.overrides.json]
    J[创建符号链] --> K[zh-*.json → ja-JP.json]
    L[补丁 ont()] --> M[阻止 bootstrap 覆盖]
```

## 还原流程

1. 从 `/tmp/` 备份还原原始 `ja-JP.json` / `dynamic/ja-JP.json` / `ja-JP.overrides.json`
2. 删除 `i18n/` 下所有 zh-* 符号链
3. 删除 `Resources/ja-JP.json` + `zh-CN.json`
4. 回滚 JS 补丁（还原 `ont()` 原始代码）

## 文件结构

```
claude-desktop-zh-cn/
├── zh-CN-app.json          Claude 1.17377.1 简体中文（18,043 条，替换 ja-JP）
├── zh-CN-shell.json        Claude 1.17377.1 简体中文（435 条，替换 Resources/ja-JP）
├── zh-CN-statsig.json      Dynamic i18n（46 条，替换 dynamic/ja-JP）
├── zh-CN-overrides.json    覆写文件（344 条，替换 ja-JP.overrides）
├── ARCHITECTURE.md         架构说明
├── install.sh              安装/还原脚本
└── README.md               使用说明
```

## 关键约束

- **不动代码签名** — 只改 `Resources/` 和 `ion-dist/` 下的文件，macOS 签名不受影响
- **可还原** — 备份原始日语文件，restore 完全回滚
- **日语用户注意** — 汉化后日语文件被替换为中文，日语用户需先 restore
- **增量兼容** — iOS、Web、旧版 Desktop 不受影响
