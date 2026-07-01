<p align="center">
  <img src="https://img.shields.io/badge/Claude%20Desktop-1.17377.1-8A2BE2?style=for-the-badge&logo=anthropic" alt="Claude 版本">
  <img src="https://img.shields.io/badge/macOS-12.0%2B-00BFFF?style=for-the-badge&logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/翻译-18,043%20%2B%20435%20%2B%2046%20%2B%20344条%20%7C%2095%25-blue?style=for-the-badge" alt="翻译覆盖">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="License">
</p>

<p align="center">
  <b>🀄 claude-desktop-zh-cn</b><br>
  <b>Claude Desktop 简体中文汉化</b><br>
  <i>替换日语为中文，不动代码签名。安全、纯净、可还原。</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/状态-稳定-brightgreen?style=flat-square" alt="状态">
  <img src="https://img.shields.io/badge/安装-一键脚本-blue?style=flat-square" alt="安装">
  <img src="https://img.shields.io/badge/还原-支持-orange?style=flat-square" alt="还原">
  <img src="https://img.shields.io/badge/PR-welcome-purple?style=flat-square" alt="PR">
</p>

## 💡 原理

Claude Desktop 官方不支持中文，但支持日语（ja-JP）。本工具将日语翻译文件替换为简体中文，同时通过符号链让中文 locale 路径指向替换后的日语文件。

只需 1 处 JS 补丁阻止服务端 locale 覆盖，即可生效。

## 用法

```bash
# 安装汉化（自动退出 Claude → 安装 → 重启）
sudo bash install.sh

# 还原（自动退出 Claude → 还原日语 → 重启）
sudo bash install.sh restore
```

> ⚠️ 汉化后日语文件被替换为中文。如需使用日语，请先 `restore`。

## 文件结构

| 文件 | 说明 |
|------|------|
| `zh-CN-app.json` | 应用 UI 简体中文（18,043 条） |
| `zh-CN-shell.json` | 原生界面简体中文（435 条） |
| `zh-CN-statsig.json` | Dynamic i18n 简体中文（46 条） |
| `zh-CN-overrides.json` | 覆写文件（344 条） |
| `install.sh` | 安装/还原脚本 |

## 许可

MIT
