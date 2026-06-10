# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Claude Desktop 简体中文汉化工具（v1.11847.5）。只改资源文件，不动代码签名，安全可还原。

## 常用命令

```bash
# 安装汉化（会自动退出 Claude、注入翻译、再启动）
sudo bash install.sh

# 还原
sudo bash install.sh restore
```

## 三层 i18n 架构

| 层 | 文件 | 目标路径 | 条目 | 类型 |
|---|---|---|---|---|
| **Shell** | `zh-CN-shell.json` | `Resources/zh-CN.json` | ~407 | Electron 原生界面（菜单、对话框、系统弹窗） |
| **App** | `zh-CN-app.json` | `ion-dist/i18n/zh-CN.json` | ~15,966 | 应用内 Web UI（设置、对话、侧栏） |
| **Dynamic** | `zh-CN-statsig.json` | `ion-dist/i18n/dynamic/zh-CN.json` | ~65 | 模型选择标签、A/B 测试 i18n（原 Statsig） |

- **Shell/Statsig**：直接拷贝目标路径即完成注入
- **App**：需与 `en-US.json` merge，保留 en-US 中未翻译的 key 作为 fallback

## 补丁注入（JS 修改）

`install.sh` 在 `ion-dist/assets/v1/*.js` 中用正则搜索替换三处：

1. **w8 map** — locale→languageCode 映射对象，追加 `"zh-CN":"zh"`
2. **lang array** — 语言白名单数组，追加 `"zh-CN"`
3. **persona switch** — Persona locale switch，插入中文分支

三个补丁均幂等：检测到 `"zh-CN"` 已存在则跳过。

## 关键约束

- **不动代码签名** — 只改 `Resources/` 和 `ion-dist/` 下的文件，macOS 签名不受影响
- **可还原** — `restore` 删除注入文件 + 回滚 JS 补丁
- **增量兼容** — iOS、Web、旧版 Desktop 不受影响
- **Shell 层使用紧凑哈希 key**（v1.11187.4 引入），App 层沿用旧式哈希 key

## 词典维护规范

- 翻译 JSON 中 key 是哈希/ID，value 是简体中文
- 新增翻译时确保同层的 key-value 格式保持一致
- 维持 100% 覆盖（新版本发布后对比 en-US.json 补全缺失条目）
