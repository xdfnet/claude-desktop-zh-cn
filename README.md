<p align="center">
  <img src="https://img.shields.io/badge/Claude%20Desktop-1.17377.1-8A2BE2?style=for-the-badge&logo=anthropic" alt="Claude 版本">
  <img src="https://img.shields.io/badge/翻译-16,295%20%2B%20435%20%2B%2046条-blue?style=for-the-badge" alt="翻译覆盖">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="License">
</p>

<p align="center">
  <b>🀄 claude-desktop-zh-cn</b><br>
  <b>Claude Desktop 简体中文汉化</b><br>
  <i>替换英文为中文，不动代码签名。安全、纯净、可还原。</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/状态-稳定-brightgreen?style=flat-square" alt="状态">
  <img src="https://img.shields.io/badge/安装-一键脚本-blue?style=flat-square" alt="安装">
  <img src="https://img.shields.io/badge/还原-支持-orange?style=flat-square" alt="还原">
</p>

## 💡 原理

直接将 Claude Desktop 的英文（en-US）翻译文件替换为简体中文。英文是系统的默认回退语言，替换后无论在何种系统语言下都显示中文。

只需 1 处 JS 补丁阻止服务端语言覆盖，即可生效。

## 用法

```bash
# 安装汉化（自动退出 Claude → 安装 → 重启）
sudo bash install.sh

# 还原（自动退出 Claude → 还原英文 → 重启）
sudo bash install.sh restore
```

## 文件结构

| 文件 | 说明 |
|------|------|
| `zh-CN-app.json` | 应用 UI 简体中文（16,295 条） |
| `zh-CN-shell.json` | 原生界面简体中文（435 条） |
| `zh-CN-statsig.json` | Dynamic i18n 简体中文（46 条） |
| `install.sh` | 安装/还原脚本 |

## 许可

MIT
