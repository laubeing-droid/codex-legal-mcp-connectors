# 连接器配置指南

安装后重启 Codex Desktop 即可使用。配置存储在 `~/.codex/config.toml`。

---

## 一、chineselaw（元典智库）— 首选

基于 [chineselaw-mcp](https://www.npmjs.com/package/chineselaw-mcp)（MIT），将元典智库 API 封装为 MCP 工具。

### 前置条件
- **Node.js >= 18**。下载 https://nodejs.org（LTS 版本）

### 注册获取 API Key
1. 打开 https://open.chineselaw.com → 注册
2. 个人中心 → API 管理 → 创建 API Key

### 配置示例（`~/.codex/config.toml`）

```toml
[mcp_servers.chineselaw]
command = "npx"
args = ["-y", "chineselaw-mcp"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true

[mcp_servers.chineselaw.env]
CHINESELAW_API_KEY = "你的真实API Key"    # ← 替换
```

### 可用工具（33 个）

| 类别 | 数量 | 工具 |
|------|:----:|------|
| 法律法规 | 5 | search_regulations, search_legal_articles, get_article_detail, get_regulation_detail, semantic_search_law |
| 案例文书 | 4 | search_cases, search_authoritative_cases, get_case_detail, semantic_search_cases |
| 企业信息 | 24 | 企业检索、工商信息、商标专利、涉诉信息、失信被执行人、行政处罚等 |

---

## 二、北大法宝 MCP 协议

### 注册获取 Token
1. 打开 https://mcp.pkulaw.com → 注册
2. 开发者控制台 → 创建 Access Token

### 10 个服务详情

| # | 配置段名 | 中文名 | 用途 |
|---|---------|--------|------|
| 1 | pkulaw-law-search | 检索法律法规-语义 | 基于语义理解的法规检索 |
| 2 | pkulaw-law-keyword | 检索法律法规-关键词 | 标题或正文关键词检索 |
| 3 | pkulaw-case-semantic-search | 检索司法案例-语义 | 自然语言查找判例 |
| 4 | pkulaw-case-keyword | 检索司法案例-关键词 | 案例检索 |
| 5 | pkulaw-law-item-keyword | 精准查找法条-关键词 | 按名称与条号查法条 |
| 6 | pkulaw-law-recognition | 法条识别与溯源 | 识别法规名称与条款 |
| 7 | pkulaw-case-number-recognition | 案号识别与溯源 | 识别案号并溯源 |
| 8 | pkulaw-citation-validator | 修正生成幻觉-法条 | 返回权威条文纠正幻觉 |
| 9 | pkulaw-doc-link | 法宝超链 | 文本添加法规超链接 |
| 10 | pkulaw-semantic-nlsql | 法宝语义检索（NL-SQL） | 多库语义检索（需额外购买） |

### 配置示例

```toml
[mcp_servers.pkulaw-law-search]
url = "https://apim-gateway.pkulaw.com/mcp-law-search-service"
http_headers = { Authorization = "Bearer YOUR_ACCESS_TOKEN" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
```

其他 9 个服务同理，替换 URL 和段名。

---

## 三、使用 pkulaw-mcp-cli 验证

基于 [@pkulaw/mcp-cli](https://www.npmjs.com/package/@pkulaw/mcp-cli)（北大法宝官方，MIT），用于诊断。

```bash
npm install -g @pkulaw/mcp-cli
pkulaw-mcp init --authorization "Bearer YOUR_ACCESS_TOKEN"
pkulaw-mcp update          # 拉取工具列表
pkulaw-mcp tools           # 列出可用工具
pkulaw-mcp check           # 检查配置完整性
```

---

## 四、凭证安全

- Token 和 API Key 存储在客户端配置文件中
- 切勿提交含凭证的配置文件到 Git
- 安装时交互式输入，不保留在终端历史