# 架构说明

## 三层 i18n 架构

| 层 | 文件 | 目标路径 | 条目 | 类型 |
|---|---|---|---|---|
| **Shell** | `zh-CN-shell.json` | `Resources/zh-CN.json` | 425 | Electron 原生界面（菜单、对话框、系统弹窗） |
| **App** | `zh-CN-app.json` | `ion-dist/i18n/zh-CN.json` | 16,178 | 应用内 Web UI（设置、对话、侧栏） |
| **Dynamic** | `zh-CN-statsig.json` | `ion-dist/i18n/dynamic/zh-CN.json` | 69 | 模型选择标签、A/B 测试 i18n（原 Statsig） |

- **Shell / Dynamic**：直接拷贝目标路径即完成注入
- **App**：需与 `en-US.json` merge，保留 en-US 中未翻译的 key 作为 fallback

## 注入流程

| 步骤 | 说明 |
|------|------|
| 🔧 语言白名单 | 找到 `["en-US","de-DE",…,"id-ID"]` 数组，追加 `"zh-CN"` |
| 🌐 日期 locale 映射 | 找到 `const w8={"en-US":"en",…}` 对象，追加 `"zh-CN":"zh"` |
| 🎭 Persona 语言开关 | 找到 `case"id-ID":…;default:` 语句，插入中文分支 |
| 📦 翻译合并（app 层） | 将 `zh-CN-app.json` 与 `en-US.json` 合并，写入 `i18n/zh-CN.json` |
| 📦 翻译注入（shell 层） | 将 `zh-CN-shell.json` 写入 `Resources/zh-CN.json` |
| 📊 Dynamic 同步 | 复制 `zh-CN-statsig.json` 到 `i18n/dynamic/zh-CN.json` |

## 补丁注入（JS 修改）

`install.sh` 在 `ion-dist/assets/v1/*.js` 中用正则搜索替换三处：

1. **w8 map** — locale→languageCode 映射对象，追加 `"zh-CN":"zh"`
2. **lang array** — 语言白名单数组，追加 `"zh-CN"`
3. **persona switch** — Persona locale switch，插入中文分支

三个补丁均幂等：检测到 `"zh-CN"` 已存在则跳过。

## 文件结构

```
claude-tweaks/
├── zh-CN-app.json          Claude 1.12603.1 简体中文翻译（16,178 条，100% 覆盖，应用内 UI 层）
├── zh-CN-shell.json        Claude 1.12603.1 简体中文翻译（425 条，100% 覆盖，原生 Shell 层）
├── zh-CN-statsig.json      Dynamic i18n 简体中文翻译（69 条，模型选择标签 / A/B 测试）
├── ARCHITECTURE.md                  架构说明
├── install.sh                       安装/还原脚本
└── README.md                        使用说明
```

## 关键约束

- **不动代码签名** — 只改 `Resources/` 和 `ion-dist/` 下的文件，macOS 签名不受影响
- **可还原** — `restore` 删除注入文件 + 回滚 JS 补丁
- **增量兼容** — iOS、Web、旧版 Desktop 不受影响
- **Shell 层使用紧凑哈希 key**，App 层沿用旧式哈希 key
