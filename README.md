# Claude Code Windows 一键安装工具

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

帮助 Windows 用户一键配置 Claude Code 环境，支持自定义 API 地址。

## ✨ 功能特点

- 🚀 一键安装 Node.js、Git、Claude Code
- 🌏 国内镜像源加速下载
- 🔧 支持自定义 API 地址和 Key
- 🖥️ 自动创建桌面快捷方式
- ⚙️ 配置编辑器，方便修改设置

## 📋 系统要求

- Windows 10 / 11
- 网络连接

## 🚀 快速开始

### 方法一：一键安装

1. 下载本项目
2. 双击 `一键安装ClaudeCode.bat`
3. 按提示操作

### 方法二：手动安装

```powershell
powershell -ExecutionPolicy Bypass -File install-claude-code-en.ps1
```

## ⚙️ 自定义 API 配置

安装时选择「配置自定义 API」，或安装后双击 `修改配置.bat`。

### 配置文件位置

```
%USERPROFILE%\.claude.json
%USERPROFILE%\.claude\settings.json
```

### 配置格式

**~/.claude.json**
```json
{
  "hasCompletedOnboarding": true
}
```

**~/.claude/settings.json**
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://your-api-url.com",
    "ANTHROPIC_AUTH_TOKEN": "your-api-key",
    "ANTHROPIC_API_KEY": ""
  }
}
```

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `一键安装ClaudeCode.bat` | 安装入口 |
| `修改配置.bat` | 配置编辑器入口 |
| `install-claude-code-en.ps1` | 主安装脚本 |
| `config-editor.ps1` | 配置编辑器 |

## ❓ 常见问题

### Q: 为什么连接不上 API？

A: Claude Code v2.0 有已知 bug，需要：
1. 创建 `~/.claude.json` 并设置 `hasCompletedOnboarding: true`
2. 使用 `ANTHROPIC_AUTH_TOKEN` 而不是 `ANTHROPIC_API_KEY`
3. 将 `ANTHROPIC_API_KEY` 设为空字符串

### Q: 如何更新 Claude Code？

```cmd
npm update -g @anthropic-ai/claude-code
```

## 📜 License

MIT License

## 🙏 致谢

- [Anthropic](https://anthropic.com) - Claude Code
- [npmmirror](https://npmmirror.com) - 国内镜像源
