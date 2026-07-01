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

直接用简体中文 **替换英文（en-US）文件**。英文是系统默认回退语言，替换后无论系统语言怎么设都显示中文。

| 层 | 源文件 | 目标路径 | 条目 | 说明 |
|---|---|---|---|---|
| **App** | `zh-CN-app.json` | `i18n/en-US.json` | 16,295 | 应用 UI（替换英文） |
| **Dynamic** | `zh-CN-statsig.json` | `i18n/dynamic/en-US.json` | 46 | 模型标签等 |
| **Shell** | `zh-CN-shell.json` | `Resources/en-US.json` | 435 | 原生界面（菜单、对话框） |

同时通过 **JS 补丁** 将 `ont()` 组件改为空函数，阻止服务端 bootstrap 返回的 `locale` 覆盖语言。

## 关键约束

- **不动代码签名** — 只改 `Resources/` 和 `ion-dist/` 下的文件，macOS 签名不受影响
- **可还原** — 备份原始英文文件到 `/tmp/`，restore 完全回滚
- **增量兼容** — iOS、Web、旧版 Desktop 不受影响

## 词典维护规范

- 翻译 JSON 中 key 是哈希/ID，value 是简体中文
- 新增翻译时确保同层的 key-value 格式保持一致
- 维持高覆盖（新版本发布后对比 en-US.json 补全缺失条目，未翻译 key 保留 en-US 原文作为 fallback）
