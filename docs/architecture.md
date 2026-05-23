# 架构说明

## 项目定位

本仓库是一个**跨平台 MCP 连接器配置管理工具**。不包含法律工作流内容，只负责向 Codex Desktop、Claude Code、Claude Desktop 等客户端写入中国法律 MCP 连接器配置。

## 数据流

```
用户运行 install.ps1 / install.sh
        │
        ▼
detect.ps1 / detect.sh           ← 自动检测本机客户端环境
  → Codex Desktop: ~/.codex/config.toml
  → Claude Code: ~/.claude/settings.json
  → Claude Desktop: AppData/Claude/claude_desktop_config.json
        │
        ▼
交互式配置                        ← 输入凭证 + 选择服务
  → chineselaw API Key
  → 北大法宝 Access Token + 服务选择
        │
        ▼
写入配置                         ← 自动适配 TOML/JSON 格式
  → 每个检测到的客户端
  → 只添加不覆盖已有配置
```

## 与主仓库的关系

```
Claude-for-Legal-CN-to-Codex        ← 技能包装层
  install.ps1 步骤 3
    → 克隆并调用本仓库的 install.ps1
  update.ps1 步骤 3/4
    → 调用本仓库的 verify.ps1 / update.ps1

Codex-Claude-legal-CN-mcp-connectors  ← MCP 连接器层（本仓库）
  install.ps1 / verify.ps1 / update.ps1
  detect.ps1（环境检测模块）
```

## 跨平台设计

| 平台 | 脚本 | 配置格式 | 写入方式 |
|------|------|---------|---------|
| Windows | `.ps1` | TOML / JSON | Out-File UTF8 |
| macOS/Linux | `.sh` | TOML / JSON | cat / jq |

两个平台的脚本保持功能对等。修改时必须同步更新双版本。