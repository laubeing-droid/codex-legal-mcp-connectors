# Codex 中国法律 MCP 连接器

中国法律检索 MCP 连接器配置工具。支持三种方式连接权威法律数据源：

| 连接器 | 方式 | 工具数 | 推荐 |
|--------|------|--------|------|
| **chineselaw（元典智库）** | MCP 协议 stdio | 33 | ⭐ 首选 |
| **北大法宝 MCP 协议** | MCP 协议 HTTP | 10 服务 | 推荐 |
| **北大法宝 CLI 命令行** | CLI 工具 | — | 调试/验证 |

本仓库独立管理 MCP 配置，可与 [codex-legal-cn-skills](https://github.com/laubeing-droid/codex-legal-cn-skills) 配合使用，
也可单独安装（即使不使用法律技能，也能让 Codex 具备中国法律检索能力）。

---

## 快速安装

```powershell
git clone https://github.com/laubeing-droid/codex-legal-mcp-connectors.git
cd codex-legal-mcp-connectors
.\install.ps1
```

重启 Codex Desktop。然后替换凭证：
- **chineselaw**：注册 https://open.chineselaw.com → 获取 API Key → 编辑 config.toml → 替换 `CHINESELAW_API_KEY`
- **北大法宝**：注册 https://mcp.pkulaw.com → 获取 Token → 编辑 config.toml → 替换所有 `YOUR_ACCESS_TOKEN`

二选一即可。详细指南见 docs/connectors.md。

---

## 依赖关系

```
chineselaw-mcp (MCP stdio)         ← 基于 zooges/chineselaw-mcp (MIT)
@pkulaw/mcp-cli (CLI 调试工具)      ← 北大法宝官方 (MIT)
北大法宝 MCP 协议 (HTTP 10 服务)     ← 北大法宝官方
```

npm 包版本由 GitHub Actions 每周自动监控。

---

## 文件说明

| 文件 | 说明 |
|------|------|
| install.ps1 | 写入 MCP 配置到 ~/.codex/config.toml |
| verify.ps1 | 检查 config.toml 中 MCP 配置状态 |
| docs/connectors.md | 完整配置指南（含工具列表） |
| .github/workflows/npm-monitor.yml | npm 包版本监控 |

---

## 许可证

MIT。上游依赖：
- chineselaw-mcp（MIT，作者 zooges）
- @pkulaw/mcp-cli（MIT，北大法宝官方）