# 架构说明

## 仓库定位

独立的 MCP 连接器配置仓库。只做一件事：

> **向本机所有 MCP 客户端的配置文件写入中国法律检索连接器**

## 架构流

```
用户运行 install.ps1 / install.sh
         │
         ▼
  detect.ps1 / detect.sh —— 自动检测本机 MCP 客户端
         │
         ├── Codex Desktop      → ~/.codex/config.toml             (TOML)
         ├── Claude Code        → ~/.claude/settings.json          (JSON)
         └── Claude Desktop     → %APPDATA%/Claude/... 或 ~/Library/... (JSON)
         │
         ▼
  交互式选择连接器 + 输入凭证
         │
         ├── chineselaw（stdio）→ 写入 command/args/env
         └── 北大法宝（HTTP）   → 写入 url/http_headers
         │
         ▼
  自动适配 TOML/JSON 格式，写入所有检测到的客户端
         │
         ▼
  verify.ps1（验证） / update.ps1（更新诊断）
```

## 脚本数据流

| 脚本 | 流程 |
|------|------|
| **install.ps1** | 环境检测 → Node.js 检查 → 输入凭证 → 选择服务 → 写入所有客户端配置 |
| **verify.ps1** | 环境检测 → 解析各客户端 MCP 段 → 检查 enabled/占位符 → 检查 npm 包版本 |
| **update.ps1** | git pull 自更新 → npm 版本检查 → 全环境 MCP 配置检查 → 凭证过期检测 → 汇总 |
| **uninstall.ps1** | 环境检测 → 从所有客户端配置移除 MCP 段 |
| **detect.ps1/sh** | 被以上脚本共用，检测本机是否安装各客户端并返回配置路径 |

## 依赖关系

```
本仓库（配置层）
  ├── 不依赖上游仓库（可独立使用）
  └── 被上游仓库的 install.ps1 / update.ps1 委托调用

外部依赖：
  ├── chineselaw-mcp（npm）     —— 元典智库 MCP 封装（MIT，zooges）
  ├── @pkulaw/mcp-cli（npm）    —— 北大法宝 CLI 工具（MIT，北大法宝官方）
  └── Node.js >= 18             —— chineselaw 运行环境
```
