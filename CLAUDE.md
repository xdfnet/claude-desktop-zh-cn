# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Claude Desktop 简体中文汉化工具（v1.17377.1）。只改资源文件，不动代码签名，安全可还原。

## 常用命令

```bash
# 安装汉化
sudo bash install.sh

# 还原
sudo bash install.sh restore
```

## 汉化原理

Claude Desktop 官方支持日语（ja-JP）但不支持中文。汉化方案是 **替换日语文件为中文**：

| 层 | 源文件 | 目标路径 | 条目 | 说明 |
|---|---|---|---|---|
| **App** | `zh-CN-app.json` | `i18n/ja-JP.json` | 18,043 | 应用 UI（替换日语） |
| **Dynamic** | `zh-CN-statsig.json` | `i18n/dynamic/ja-JP.json` | 46 | 模型标签等 |
| **Overrides** | `zh-CN-overrides.json` | `i18n/ja-JP.overrides.json` | 344 | 法律条款等 |
| **Shell** | `zh-CN-shell.json` | `Resources/ja-JP.json` | 435 | 原生界面（菜单、对话框） |
| **Symlinks** | → | `i18n/zh-*.json → ja-JP.json` | — | 系统中文 locale 指向日语文件 |

同时通过 **JS 补丁** 将 `ont()` 组件改为空函数，阻止服务端 bootstrap 返回的 `locale` 覆盖系统语言。

## 关键约束

- **不动代码签名** — 只改 `Resources/` 和 `ion-dist/` 下的文件，macOS 签名不受影响
- **可还原** — `restore` 还原原始日语文件 + 回滚 JS 补丁
- **增量兼容** — iOS、Web 不受影响；日语用户需先 restore 再使用

## 词典维护规范

- 翻译 JSON 中 key 是哈希/ID，value 是简体中文
- 新增翻译时确保同层的 key-value 格式保持一致
- 维持高覆盖（新版本发布后对比 en-US.json 补全缺失条目，未翻译 key 保留 en-US 原文作为 fallback）
