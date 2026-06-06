# Claude Desktop 简体中文汉化 - 架构

## 分层结构

```
Claude.app/Contents/Resources/
├── zh-CN.json                          ← Shell 层 (zh-CN-shell.json)
│   └── Electron 原生界面（菜单、对话框、系统弹窗、权限请求）
│   └── 407 条 · 紧凑哈希 key · 1.11187.4 新增
│
└── ion-dist/
    ├── i18n/
    │   ├── zh-CN.json                  ← App 层 (zh-CN-app.json)
    │   │   └── 应用内 Web UI（设置、对话、侧栏、全部界面）
    │   │   └── 15,724 条 · 哈希 key · 1.11187.x 沿用
    │   │
    │   └── statsig/
    │       └── zh-CN.json              ← Statsig 层 (zh-CN-statsig.json)
    │           └── 模型选择标签（Pro 标签、能力描述等）
    │           └── 65 条 · A/B 测试 i18n · 独立子系统
    │
    └── assets/v1/*.js                  ← JS 运行时（需打补丁）
        ├── w8 map        → 追加 "zh-CN":"zh"
        ├── lang array    → 追加 "zh-CN"
        └── persona switch → 追加 case "zh-CN"
```

## 三条 i18n 流

| 层 | 来源文件 | 目标路径 | 机制 |
|---|---|---|---|
| **Shell** | `zh-CN-shell.json` | `Resources/zh-CN.json` | 直接拷贝 |
| **App** | `zh-CN-app.json` | `ion-dist/i18n/zh-CN.json` | 与 `en-US.json` merge，保留旧 key |
| **Statsig** | `zh-CN-statsig.json` | `ion-dist/i18n/statsig/zh-CN.json` | 直接拷贝 |

## 补丁（JS 注入）

三个正则注入，在 `ion-dist/assets/v1/*.js` 中搜索替换：

1. **w8 map** — locale→languageCode 映射对象，追加 `"zh-CN":"zh"`
2. **lang array** — 语言白名单数组，追加 `"zh-CN"`
3. **persona switch** — Persona locale switch，插入中文分支

补丁幂等：检测到 `"zh-CN"` 已存在则跳过。

## 关键约束

- **不动代码签名** — 只改 `Resources/` 和 `ion-dist/` 下的资源文件和 JS，macOS 签名不受影响
- **可还原** — `restore` 命令删除注入的 zh-CN 文件 + 回滚 JS 补丁
- **增量兼容** — iOS 端、Web 端、旧版 Desktop 不受影响
