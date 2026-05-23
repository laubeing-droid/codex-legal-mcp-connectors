# MCP 连接器配置参考

本仓库为中国法律 MCP 连接器提供完整的安装和配置支持。接入以下三种数据源：

| 连接器 | 类型 | 工具数 | 推荐 |
|--------|------|--------|------|
| **chineselaw（元典智库）** | stdio（npx） | 33 | ⭐ 首选 |
| **北大法宝 MCP 协议** | HTTP（10 个服务） | 10+ | 推荐 |
| **@pkulaw/mcp-cli** | CLI 调试工具 | — | 诊断/验证 |

chineselaw 和北大法宝**二选一即可**，不需要两个都配。

---

## 一、chineselaw（元典智库）

| 项目 | 内容 |
|------|------|
| npm 包 | [chineselaw-mcp](https://www.npmjs.com/package/chineselaw-mcp)（作者 zooges，MIT） |
| 注册 | https://open.chineselaw.com → 注册 → API 管理 → 创建 API Key |
| 启动方式 | `npx -y chineselaw-mcp` |
| 前置依赖 | Node.js >= 18 |

### 工具清单（33 个）

| 类别 | 数量 | 工具 |
|------|------|------|
| 法律法规 | 5 | search_regulations、search_legal_articles、get_article_detail、get_regulation_detail、semantic_search_law |
| 案例文书 | 4 | search_cases、search_authoritative_cases、get_case_detail、semantic_search_cases |
| 企业信息 | 24 | 企业检索、工商信息、商标专利、涉诉信息、失信被执行人、行政处罚等 |

### 配置段

**Codex Desktop（TOML）**：
```toml
[mcp_servers.chineselaw]
command = "npx"
args = ["-y", "chineselaw-mcp"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true

[mcp_servers.chineselaw.env]
CHINESELAW_API_KEY = "YOUR_API_KEY"    # ← 替换为真实 Key
```

**Claude Code / Claude Desktop（JSON）**：
```json
{
  "mcpServers": {
    "chineselaw": {
      "command": "npx",
      "args": ["-y", "chineselaw-mcp"],
      "env": { "CHINESELAW_API_KEY": "YOUR_API_KEY" }
    }
  }
}
```

---

## 二、北大法宝 MCP 协议

| 项目 | 内容 |
|------|------|
| 来源 | 北大法宝官方 MCP 平台 |
| 注册 | https://mcp.pkulaw.com → 开发者控制台 → 创建应用 → 获取 Access Token |
| 类型 | HTTP 服务，无前置依赖 |
| 网关基地址 | `https://apim-gateway.pkulaw.com` |

### 10 个服务清单

| # | 配置段名 | 官方中文名 | 端点路径 | 用途 |
|---|---------|-----------|---------|------|
| 1 | pkulaw-law-search | 检索法律法规-语义 | /mcp-law-search-service | 语义理解的法规检索 |
| 2 | pkulaw-law-keyword | 检索法律法规-关键词 | /mcp-law | 标题/正文关键词检索 |
| 3 | pkulaw-case-semantic-search | 检索司法案例-语义 | /mcp-case-search-service | 自然语言查找判例 |
| 4 | pkulaw-case-keyword | 检索司法案例-关键词 | /mcp-case | 案例标题/正文关键词检索 |
| 5 | pkulaw-law-item-keyword | 精准查找法条-关键词 | /mcp-fatiao | 法规名称+条号精确查询 |
| 6 | pkulaw-law-recognition | 法条识别与溯源 | /law_recognition | 文本中识别法规名称与条款 |
| 7 | pkulaw-case-number-recognition | 案号识别与溯源 | /case_number_recognition | 识别案号并溯源 |
| 8 | pkulaw-citation-validator | 修正生成幻觉-法条 | /pku_citation_validator | 分析引用并返回权威条文 |
| 9 | pkulaw-doc-link | 法宝超链 | /add-doc-link | 文本智能添加法规超链接 |
| 10 | pkulaw-semantic-nlsql | 法宝语义检索（NL-SQL） | 需自定义 | 自然语言多库语义检索（需额外购买） |

> 服务清单来源于 `@pkulaw/mcp-cli` npm 包内的 `dist/config/servers.json`，中文名为官方 displayName。

### 配置段示例

**Codex Desktop（TOML）**：
```toml
[mcp_servers.pkulaw-law-search]
url = "https://apim-gateway.pkulaw.com/mcp-law-search-service"
http_headers = { Authorization = "Bearer YOUR_ACCESS_TOKEN" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
```

**Claude Code / Claude Desktop（JSON）**：
```json
{
  "mcpServers": {
    "pkulaw-law-search": {
      "url": "https://apim-gateway.pkulaw.com/mcp-law-search-service",
      "headers": { "Authorization": "Bearer YOUR_ACCESS_TOKEN" }
    }
  }
}
```

---

## 三、@pkulaw/mcp-cli（调试工具）

| 项目 | 内容 |
|------|------|
| npm 包 | [@pkulaw/mcp-cli](https://www.npmjs.com/package/@pkulaw/mcp-cli)（北大法宝官方，MIT） |
| 安装 | `npm install -g @pkulaw/mcp-cli` |
| 初始化 | `pkulaw-mcp init --authorization "Bearer YOUR_ACCESS_TOKEN"` |
| 验证 | `pkulaw-mcp update` |
| 查看工具 | `pkulaw-mcp tools` |
| 诊断 | `pkulaw-mcp doctor` |

---

## 四、凭证配置

| 服务 | 注册地址 | 配置项 | 获取方式 |
|------|---------|--------|---------|
| chineselaw（元典智库） | https://open.chineselaw.com | `CHINESELAW_API_KEY` | 注册 → API 管理 → 创建 API Key |
| 北大法宝 | https://mcp.pkulaw.com | `Bearer YOUR_ACCESS_TOKEN` | 注册 → 开发者控制台 → 创建应用 |

install 时如未输入凭证，会写入占位符 `YOUR_API_KEY` / `YOUR_ACCESS_TOKEN`，运行 `update.ps1` 可检测并提示替换。

---

## 五、配套文档

| 文档 | 内容 |
|------|------|
| [usage-guide.md](usage-guide.md) | 使用指南（安装/验证/更新/配合主仓库） |
| [architecture.md](architecture.md) | 架构说明与数据流 |
| [troubleshooting.md](troubleshooting.md) | 常见问题排查 |
| [contributing.md](contributing.md) | 贡献指南 |
