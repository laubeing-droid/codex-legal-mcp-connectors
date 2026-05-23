# Codex-Claude-legal-CN-mcp-connectors

中国法律 MCP 连接器配置工具。自动检测本机 MCP 客户端环境（Codex Desktop / Claude Code / Claude Desktop），写入中国法律检索连接器配置。

一次安装，多环境生效。

---

## 支持的连接器

| 连接器 | 类型 | 工具数 | 推荐 |
|--------|------|--------|------|
| **chineselaw（元典智库）** | stdio (npx) | 33 | ⭐ 首选 |
| **北大法宝 MCP 协议** | HTTP | 10 服务 | 推荐 |

## 快速开始

```powershell
git clone https://github.com/laubeing-droid/Codex-Claude-legal-CN-mcp-connectors.git
cd Codex-Claude-legal-CN-mcp-connectors
.\install.ps1
```

安装脚本自动检测本机客户端 → 输入凭证 → 写入配置。重启客户端即可使用。

## 使用本仓库的方式

| 方式 | 说明 |
|------|------|
| **独立使用** | 直接 `git clone` 后运行 `install.ps1` |
| **作为主仓库的依赖** | 由 [Claude-for-Legal-CN-to-Codex](https://github.com/laubeing-droid/Claude-for-Legal-CN-to-Codex) 自动克隆和调用 |

## 支持的环境

| 客户端 | 配置路径 | 格式 |
|--------|---------|------|
| Codex Desktop | `~/.codex/config.toml` | TOML |
| Claude Code | `~/.claude/settings.json` | JSON |
| Claude Desktop | `%LOCALAPPDATA%/Claude/claude_desktop_config.json` | JSON |

## 脚本清单

| 脚本 | Windows | macOS/Linux | 功能 |
|------|---------|-------------|------|
| `install.ps1` / `install.sh` | ✅ | ✅ | 交互式安装（5 步） |
| `verify.ps1` / `verify.sh` | ✅ | ✅ | 全环境配置验证 |
| `update.ps1` / `update.sh` | ✅ | ✅ | 自更新 + 全环境诊断 |
| `uninstall.ps1` / `uninstall.sh` | ✅ | ✅ | 全环境配置清理 |
| `detect.ps1` / `detect.sh` | ✅ | ✅ | 环境检测模块（被引用） |

## 连接器详情

### chineselaw（元典智库）
- **npm**: [chineselaw-mcp](https://www.npmjs.com/package/chineselaw-mcp)（MIT, zooges）
- **注册**: https://open.chineselaw.com → API 管理 → 创建 API Key
- **依赖**: Node.js >= 18
- **工具**: 法规检索(5) + 案例检索(4) + 企业信息(24) = 33 个

### 北大法宝 MCP 协议
- **注册**: https://mcp.pkulaw.com → 开发者控制台 → Access Token
- **10 个服务**: 法律法规检索（语义/关键词）、司法案例检索（语义/关键词）、法条精确查找、法条识别、案号识别、引用修正、法宝超链、语义 NL-SQL
- **无前置依赖**

## 凭证安全

- Token 和 API Key 存储在客户端配置文件中
- 安装时交互式输入，不保留在终端历史
- 切勿将含凭证的配置文件提交到 Git

## 许可证

MIT。