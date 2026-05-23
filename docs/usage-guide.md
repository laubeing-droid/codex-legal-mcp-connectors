# 使用指南

## 独立使用

本仓库可以独立使用，不依赖主技能仓库。

```powershell
git clone https://github.com/laubeing-droid/Codex-Claude-legal-CN-mcp-connectors.git
cd Codex-Claude-legal-CN-mcp-connectors
.\install.ps1
```

## 作为主仓库依赖

由 [Claude-for-Legal-CN-to-Codex](https://github.com/laubeing-droid/Claude-for-Legal-CN-to-Codex) 自动管理：
- `install.ps1` 步骤 3 自动克隆并运行本仓库的安装脚本
- `update.ps1` 步骤 3/4 自动调用本仓库的验证和更新脚本

## 脚本详解

### install.ps1

| 步骤 | 说明 |
|------|------|
| 1/5 环境检测 | 调用 detect.ps1，列出所有 MCP 客户端 |
| 2/5 前置检查 | 检测 Node.js（chineselaw 依赖） |
| 3/5 输入凭证 | chineselaw API Key（可选） |
| 4/5 选择服务 | 北大法宝 10 服务选择（多选或全部） |
| 5/5 写入配置 | 遍历所有客户端写入 TOML/JSON |

### verify.ps1

检查所有环境：
- MCP 连接器列表和启用状态
- Token/API Key 是否为占位符
- npm 包本地 vs 最新版本
- @pkulaw/mcp-cli 安装状态

### update.ps1

5 步全面诊断：
1. git pull 同步本仓库
2. 检查 npm 包版本
3. 全环境 MCP 配置检查
4. 凭证检测 + pkulaw-mcp-cli 验证
5. 汇总

### uninstall.ps1

1. 检测环境
2. 从所有客户端配置中移除 MCP 段
3. 用户确认后执行

## 常见用法

```powershell
.\install.ps1              # 安装 MCP 连接器
.\verify.ps1               # 验证配置状态
.\update.ps1               # 更新 + 诊断
.\uninstall.ps1            # 卸载 MCP 连接器
```