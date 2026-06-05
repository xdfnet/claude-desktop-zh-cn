# Claude Tweaks

Claude Desktop 简体中文汉化。只改资源文件，不动代码签名。

> 当前适配版本：**Claude 1.11187.2**

## 用法

```bash
# 安装汉化
sudo bash install.sh

# 还原
sudo bash install.sh restore
```

脚本会自动退出 Claude、注入翻译、再启动。

## 原理

脚本会扫描 `ion-dist/assets/v1/` 下所有 JS 文件，修补以下三处：

1. **语言白名单** — 找到 `["en-US","de-DE",…,"id-ID"]` 数组，追加 `"zh-CN"`
2. **日期 locale 映射** — 找到 `const w8={"en-US":"en",…}` 对象，追加 `"zh-CN":"zh"`
3. **Persona 语言开关** — 找到 `case"id-ID":…;default:` 语句，插入中文分支

然后**翻译合并** — 将 `zh-CN.json` 与 `en-US.json` 合并，写入 `i18n/zh-CN.json`

**statsig 同步** — 复制 `statsig-zh-CN.json` 到 `i18n/statsig/zh-CN.json`，新版 Claude 强制要求此文件，缺失会导致中文语言加载失败

**不重新签名** — 资源文件变更不受 macOS 代码签名检查

## 文件

```
claude-tweaks/
├── zh-CN.json              Claude 1.11187.2 简体中文翻译（15,724 条，100% 覆盖）
├── statsig-zh-CN.json      statsig 简体中文翻译（65 条，新版 Claude 必需）
├── install.sh                     安装/还原脚本
└── README.md                      本文件
```
