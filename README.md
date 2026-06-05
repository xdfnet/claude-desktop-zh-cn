<p align="center">
  <img src="https://img.shields.io/badge/Claude%20Desktop-1.11187.2-8A2BE2?style=for-the-badge&logo=anthropic" alt="Claude 版本">
  <img src="https://img.shields.io/badge/macOS-12.0%2B-00BFFF?style=for-the-badge&logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/翻译-15,724%20条%20%7C%20100%25-success?style=for-the-badge" alt="翻译覆盖">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="License">
</p>

<p align="center">
  <b>🀄 Claude Desktop 简体中文汉化</b><br>
  <i>只改资源文件，不动代码签名。安全、纯净、可还原。</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/状态-稳定-brightgreen?style=flat-square" alt="状态">
  <img src="https://img.shields.io/badge/安装-一键脚本-blue?style=flat-square" alt="安装">
  <img src="https://img.shields.io/badge/还原-支持-orange?style=flat-square" alt="还原">
  <img src="https://img.shields.io/badge/PR-welcome-purple?style=flat-square" alt="PR">
</p>

## 用法

```bash
# 安装汉化
sudo bash install.sh

# 还原
sudo bash install.sh restore
```

脚本会自动退出 Claude、注入翻译、再启动。

## 原理

| 步骤 | 说明 |
|------|------|
| 🔧 语言白名单 | 找到 `["en-US","de-DE",…,"id-ID"]` 数组，追加 `"zh-CN"` |
| 🌐 日期 locale 映射 | 找到 `const w8={"en-US":"en",…}` 对象，追加 `"zh-CN":"zh"` |
| 🎭 Persona 语言开关 | 找到 `case"id-ID":…;default:` 语句，插入中文分支 |
| 📦 翻译合并 | 将 `zh-CN.json` 与 `en-US.json` 合并，写入 `i18n/zh-CN.json` |
| 📊 statsig 同步 | 复制 `statsig-zh-CN.json` 到 `i18n/statsig/zh-CN.json` |

> **为什么不需要重新签名？** 资源文件变更不受 macOS 代码签名检查。

## 文件

```
claude-tweaks/
├── zh-CN.json              Claude 1.11187.2 简体中文翻译（15,724 条，100% 覆盖）
├── statsig-zh-CN.json      statsig 简体中文翻译（65 条，新版 Claude 必需）
├── install.sh                     安装/还原脚本
└── README.md                      本文件
```
