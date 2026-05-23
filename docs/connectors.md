# MCP 连接器配置指南

Codex Desktop 的 MCP 配置位于 `~/.codex/config.toml` 的 `[mcp_servers]` 段。
运行 `install.ps1` 后会自动写入，你只需替换凭证。

---

## 一、chineselaw（元典智库）— 首选

基于 [chineselaw-mcp](https://www.npmjs.com/package/chineselaw-mcp)（作者 zooges，MIT），
将元典智库 API 开放平台封装为 MCP 工具，覆盖三大类共 **33 个工具**。

### 前置条件
- Node.js >= 18。从 https://nodejs.org 下载 LTS 版本

### 注册获取 API Key
1. 打开 https://open.chineselaw.com → 注册 → 个人中心 → API 管理 → 创建 API Key

### 配置
```powershell
notepad "$env:USERPROFILE\.codex\config.toml"
```
找到 `[mcp_servers.chineselaw.env]`，将 `CHINESELAW_API_KEY` 替换为真实 Key：

```toml
[mcp_servers.chineselaw]
command = "npx"
args = ["-y", "chineselaw-mcp"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true

[mcp_servers.chineselaw.env]
CHINESELAW_API_KEY = "YOUR_API_KEY"    # ← 替换
```

### 可用工具（33 个）

**法律法规（5）**：search_regulations, search_legal_articles, get_article_detail, get_regulation_detail, semantic_search_law

**案例文书（4）**：search_cases, search_authoritative_cases, get_case_detail, semantic_search_cases

**企业信息（24）**：企业检索、工商信息、商标专利、涉诉信息、失信被执行人、行政处罚等

---

## 二、北大法宝 MCP 协议 — Codex 集成方式

10 个独立 HTTP MCP 服务。安装脚本已写入配置，替换 Token 即可使用。

### 注册获取凭证
1. 打开 https://mcp.pkulaw.com → 注册 → 开发者控制台 → 我的应用
2. 创建应用，获取 Access Token

### 配置
打开 config.toml，将所有 `pkulaw-*` 段中的 `YOUR_ACCESS_TOKEN` 替换为真实 Token：

```toml
[mcp_servers.pkulaw-law-search]
url = "https://apim-gateway.pkulaw.com/mcp-law-search-service"
http_headers = { Authorization = "Bearer YOUR_ACCESS_TOKEN" }   # ← 替换
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
```

### 已配置的 10 个服务
| 配置段名 | 用途 |
|----------|------|
| pkulaw-law-search | 法律法规语义检索 |
| pkulaw-law-keyword | 法律法规关键词检索 |
| pkulaw-case-semantic-search | 案例语义检索 |
| pkulaw-case-keyword | 案例关键词检索 |
| pkulaw-law-item-keyword | 法条关键词检索 |
| pkulaw-law-recognition | 法律文本识别 |
| pkulaw-case-number-recognition | 案号识别 |
| pkulaw-citation-validator | 引证验证 |
| pkulaw-doc-link | 文档关联 |
| pkulaw-semantic-nlsql | NL SQL 查询（需额外购买） |

---

## 三、使用 pkulaw-mcp-cli 验证配置

基于 [@pkulaw/mcp-cli](https://www.npmjs.com/package/@pkulaw/mcp-cli)（北大法宝官方，MIT），
用于诊断 Token 有效性、发现已订阅服务、验证 API 返回。

### 安装与初始化
```bash
npm install -g @pkulaw/mcp-cli
pkulaw-mcp init --authorization "Bearer YOUR_ACCESS_TOKEN"
```

### 验证流程
```bash
pkulaw-mcp update                     # 第 1 步：确认 Token 有效
pkulaw-mcp tools                      # 第 2 步：查看可用工具
pkulaw-mcp law-search search_regulations --searchKey "民法典 合同无效"  # 第 3 步：直接调用
```

---

## 四、验证连接

重启 Codex Desktop 后测试：

**chineselaw 用户**：`搜索民法典关于合同无效的规定`
**北大法宝用户**：`查一下最新关于民间借贷的司法解释`

连接成功时引用标注来源；未连接时标注 `[需验证]`。

---

## 五、常见问题

- **连接器不生效？** 确认 Token 已替换、`enabled = true` 存在、已重启 Codex
- **chineselaw npx 错误？** `node --version` 确认 >= 18
- **二选一即可**，不需要两个都配
- **无连接器？** 技能仍可用，但引用标注 `[需验证]`
- **损坏了 config.toml？** 重新运行 `install.ps1`（只添加不覆盖）