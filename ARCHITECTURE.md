# 架构说明

## 三层 i18n 架构

| 层 | 文件 | 目标路径 | 条目 | 类型 |
|---|---|---|---|---|
| **Shell** | `zh-CN-shell.json` | `Resources/zh-CN.json` | 428 | Electron 原生界面（菜单、对话框、系统弹窗） |
| **App** | `zh-CN-app.json` | `ion-dist/i18n/zh-CN.json` | 16,980 | 应用内 Web UI（设置、对话、侧栏） |
| **Dynamic** | `zh-CN-statsig.json` | `ion-dist/i18n/dynamic/zh-CN.json` | 46 | 模型选择标签、A/B 测试 i18n |

- **Shell / Dynamic**：直接拷贝目标路径即完成补丁
- **App**：需与 `en-US.json` merge，保留 en-US 中未翻译的 key 作为 fallback

## 补丁流程

| 步骤 | 说明 |
|------|------|
| 🔧 语言白名单 | 找到 `["en-US","de-DE",…,"id-ID"]` 数组，追加 `"zh-CN"` |
| 🌐 日期 locale 映射 | 找到 `const w8={"en-US":"en",…}` 对象，追加 `"zh-CN":"zh"` |
| 🎭 Persona 语言开关 | 找到 `case"id-ID":…;default:` 语句，插入中文分支 |
| 📦 翻译合并（app 层） | 将 `zh-CN-app.json` 与 `en-US.json` 合并，写入 `i18n/zh-CN.json` |
| 📦 翻译补丁（shell 层） | 将 `zh-CN-shell.json` 写入 `Resources/zh-CN.json` |
| 📊 Dynamic 同步 | 复制 `zh-CN-statsig.json` 到 `i18n/dynamic/zh-CN.json` |

## JS 补丁

`install.sh` 在 `ion-dist/assets/v1/*.js` 中用正则搜索替换三处：

1. **locale map** — locale→languageCode 映射对象，追加 `"zh-CN":"zh"`
2. **lang array** — 语言白名单数组，追加 `"zh-CN"`
3. **persona switch** — Persona locale switch，插入中文分支

三个补丁均幂等：检测到 `"zh-CN"` 已存在则跳过。

## 关键约束

- **不动代码签名** — 只改 `Resources/` 和 `ion-dist/` 下的文件，macOS 签名不受影响
- **可还原** — `restore` 删除补丁文件 + 回滚 JS 修改
- **增量兼容** — iOS、Web、旧版 Desktop 不受影响

## 文件结构

```
claude-desktop-zh-cn/
├── zh-CN-app.json          Claude 1.15200.0 简体中文翻译（16,980 条，91% 覆盖，应用内 UI 层）
├── zh-CN-shell.json        Claude 1.15200.0 简体中文翻译（428 条，100% 覆盖，原生 Shell 层）
├── zh-CN-statsig.json      Dynamic i18n 简体中文翻译（46 条，模型选择标签 / A/B 测试）
├── ARCHITECTURE.md                  架构说明
├── install.sh                       安装/还原脚本
└── README.md                        使用说明
```
