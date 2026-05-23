<#
.SYNOPSIS
  通用安装脚本：支持 Codex Desktop / Claude Code / Claude Desktop
.DESCRIPTION
  自动检测本机安装的所有 MCP 客户端环境，将中国法律 MCP 连接器
  写入每个环境的配置文件中（TOML 或 JSON 格式自动适配）。
  支持交互式输入凭证、选择服务、检测前置依赖。
#>

$ErrorActionPreference = 'Stop'
$MyDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ─── 加载检测模块 ──────────────────────────────────────
. "$MyDir\detect.ps1"

function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

Write-Host '=== 安装中国法律 MCP 连接器 ===' -ForegroundColor Green
Write-Host ''

# ─── 1. 环境检测 ──────────────────────────────────────
Write-Host '[1/5] 检测本机 MCP 客户端环境...' -ForegroundColor Yellow
$envs = Get-EnvironmentInfo
$activeEnvs = $envs | Where-Object { $_.Installed }
if ($activeEnvs.Count -eq 0) {
    Write-Host '  未检测到已安装的 MCP 客户端环境。' -ForegroundColor Yellow
    Write-Host '  将至少为 Codex Desktop 创建配置。' -ForegroundColor DarkGray
    # 强制添加 Codex 作为 fallback
    $codexFallback = @{
        Name = 'codex'; Display = 'Codex Desktop'
        ConfigPath = "$env:USERPROFILE\.codex\config.toml"
        Format = 'toml'; Installed = $true; McpSection = 'mcp_servers'
    }
    $activeEnvs = @($codexFallback)
}
foreach ($e in $activeEnvs) {
    $icon = if ($e.Installed) { '[OK]' } else { '[!]' }
    $status = if ($e.Installed) { '已安装' } else { '未检测到' }
    Write-Host "  $icon $($e.Display)" -ForegroundColor $(if ($e.Installed) { 'Green' } else { 'DarkGray' })
    Write-Host "        配置: $($e.ConfigPath) ($($e.Format))" -ForegroundColor DarkGray
}

# ─── 2. 前置检查 ──────────────────────────────────────
Write-Host ''
Write-Host '[2/5] 前置检查...' -ForegroundColor Yellow
$nodeOk = $true
if (-not (Test-Command 'node')) {
    Write-Host '  [!!] Node.js 未安装！chineselaw 需要 Node.js >= 18' -ForegroundColor Red
    Write-Host '       下载: https://nodejs.org (LTS 版本)' -ForegroundColor Cyan
    $nodeOk = $false
} else {
    $nodeVer = & node --version
    Write-Host "  [OK] Node.js $nodeVer" -ForegroundColor Green
}

Write-Host ''

# ─── 3. chineselaw ────────────────────────────────────
Write-Host '[3/5] chineselaw（元典智库）— 推荐，33 个工具' -ForegroundColor Cyan
Write-Host '   注册: https://open.chineselaw.com → API 管理 → 创建 API Key' -ForegroundColor DarkGray

$installChineselaw = if ($nodeOk) { (Read-Host '是否安装 chineselaw？(Y/n)') -ne 'n' } else { $false }
$apiKey = 'YOUR_API_KEY'
if ($nodeOk -and $installChineselaw) {
    $input = Read-Host '  请输入 CHINESELAW_API_KEY（留空=使用占位符）'
    if (-not [string]::IsNullOrEmpty($input)) { $apiKey = $input }
    else { Write-Host '  使用占位符，稍后手动替换' -ForegroundColor DarkYellow }
}

if ($installChineselaw) {
    foreach ($e in $activeEnvs) {
        if ($e.Format -eq 'toml') {
            $tomlBlock = @"
[mcp_servers.chineselaw]
command = "npx"
args = ["-y", "chineselaw-mcp"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true

[mcp_servers.chineselaw.env]
CHINESELAW_API_KEY = "$apiKey"
"@
            $added = Write-McpToCodex -ConfigPath $e.ConfigPath -Section 'chineselaw' -TomlBlock $tomlBlock
        } else {
            $svcConfig = Get-ChineselawStdConfig -ApiKey $apiKey
            $added = Write-McpToClaude -ConfigPath $e.ConfigPath -ServerId 'chineselaw' -ServerConfig $svcConfig
        }
        Write-Host "  $($(if ($added) { '[添加]' } else { '[跳过]' })) $($e.Display) -> chineselaw" -ForegroundColor $(if ($added) { 'Green' } else { 'DarkYellow' })
    }
} else {
    $reason = if (-not $nodeOk) { '（缺少 Node.js）' } else { '' }
    Write-Host "  跳过 chineselaw $reason" -ForegroundColor DarkGray
}

Write-Host ''

# ─── 4. 北大法宝 ─────────────────────────────────────
Write-Host '[4/5] 北大法宝 MCP 协议 — 10 个 HTTP 服务' -ForegroundColor Cyan
Write-Host '   注册: https://mcp.pkulaw.com → 开发者控制台 → 获取 Access Token' -ForegroundColor DarkGray

$installPkulaw = (Read-Host '是否安装北大法宝？(Y/n)') -ne 'n'
$token = 'YOUR_ACCESS_TOKEN'
if ($installPkulaw) {
    $input = Read-Host '  请输入 Access Token（留空=使用占位符）'
    if (-not [string]::IsNullOrEmpty($input)) { $token = $input }
    else { Write-Host '  使用占位符，稍后手动替换' -ForegroundColor DarkYellow }

    $allPkulawServices = @(
        @{ name = 'pkulaw-law-search';             url = 'https://apim-gateway.pkulaw.com/mcp-law-search-service';         display = '检索法律法规-语义';      desc = '基于语义理解的法律法规检索与相关文章查找' }
        @{ name = 'pkulaw-law-keyword';             url = 'https://apim-gateway.pkulaw.com/mcp-law';                       display = '检索法律法规-关键词';    desc = '法规标题或正文关键词精确匹配检索' }
        @{ name = 'pkulaw-case-semantic-search';    url = 'https://apim-gateway.pkulaw.com/mcp-case-search-service';       display = '检索司法案例-语义';      desc = '用自然语言描述查找相关判例' }
        @{ name = 'pkulaw-case-keyword';            url = 'https://apim-gateway.pkulaw.com/mcp-case';                      display = '检索司法案例-关键词';    desc = '案例标题或正文关键词检索' }
        @{ name = 'pkulaw-law-item-keyword';        url = 'https://apim-gateway.pkulaw.com/mcp-fatiao';                    display = '精准查找法条-关键词';    desc = '通过法规名称与条号精确查询法条内容' }
        @{ name = 'pkulaw-law-recognition';         url = 'https://apim-gateway.pkulaw.com/law_recognition';               display = '法条识别与溯源';          desc = '从文本中识别法规名称与条款，返回来源链接' }
        @{ name = 'pkulaw-case-number-recognition'; url = 'https://apim-gateway.pkulaw.com/case_number_recognition';      display = '案号识别与溯源';          desc = '识别案号、标准化验证及与案例库溯源' }
        @{ name = 'pkulaw-citation-validator';      url = 'https://apim-gateway.pkulaw.com/pku_citation_validator';       display = '修正生成幻觉-法条';      desc = '分析引用并返回权威条文，修正模型引注幻觉' }
        @{ name = 'pkulaw-doc-link';                url = 'https://apim-gateway.pkulaw.com/add-doc-link';                  display = '法宝超链';                desc = '为文本智能添加法规超链接指向北大法宝文档' }
        @{ name = 'pkulaw-semantic-nlsql';          url = 'https://apim-gateway.pkulaw.com/YOUR_NL_SQL_SERVICE_ID';       display = '法宝语义检索（NL-SQL）'; desc = '自然语言在多库中语义检索（需额外购买配置）' }
    )

    Write-Host '  选择要安装的服务（多选，用逗号分隔，如 1,3,5）:' -ForegroundColor Yellow
    for ($i = 0; $i -lt $allPkulawServices.Count; $i++) {
        $svc = $allPkulawServices[$i]
        Write-Host "    [$($i+1)] $($svc.display) — $($svc.desc)" -ForegroundColor DarkGray
    }
    Write-Host "    [a] 全部安装" -ForegroundColor DarkGray
    $selection = Read-Host '  请输入'

    $selectedIndices = @()
    if ($selection -eq 'a' -or $selection -eq 'A' -or [string]::IsNullOrWhiteSpace($selection)) {
        $selectedIndices = 0..($allPkulawServices.Count - 1)
    } else {
        $selection -split ',' | ForEach-Object {
            $num = $_.Trim() -as [int]
            if ($num -ge 1 -and $num -le $allPkulawServices.Count) {
                $selectedIndices += $num - 1
            }
        }
    }

    foreach ($idx in $selectedIndices) {
        $svc = $allPkulawServices[$idx]
        foreach ($e in $activeEnvs) {
            if ($e.Format -eq 'toml') {
                $tomlBlock = @"
[mcp_servers.$($svc.name)]
url = "$($svc.url)"
http_headers = { Authorization = "Bearer $token" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
"@
                $added = Write-McpToCodex -ConfigPath $e.ConfigPath -Section $svc.name -TomlBlock $tomlBlock
            } else {
                $svcConfig = Get-PkulawHttpConfig -Url $svc.url -Token $token
                $added = Write-McpToClaude -ConfigPath $e.ConfigPath -ServerId $svc.name -ServerConfig $svcConfig
            }
            if ($added) {
                Write-Host "  [添加] $($e.Display) -> $($svc.name)" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host '  跳过北大法宝' -ForegroundColor DarkGray
}

# ─── 5. 完成 ─────────────────────────────────────────
Write-Host ''
Write-Host '[5/5] 安装完成！' -ForegroundColor Yellow
Write-Host ''
Write-Host '已配置的 MCP 客户端环境:' -ForegroundColor Cyan
foreach ($e in $activeEnvs) {
    Write-Host "  - $($e.Display): $($e.ConfigPath)" -ForegroundColor Cyan
}
Write-Host ''
Write-Host '===== 后续步骤 =====' -ForegroundColor Cyan
Write-Host '1. 重启对应的 MCP 客户端' -ForegroundColor Cyan
Write-Host '2. 运行 verify.ps1 验证配置' -ForegroundColor Cyan
Write-Host '3. (如需替换凭证) 修改上述配置文件中的占位符' -ForegroundColor Cyan
Write-Host ''
Write-Host 'chineselaw 注册: https://open.chineselaw.com' -ForegroundColor Cyan
Write-Host '北大法宝注册:  https://mcp.pkulaw.com' -ForegroundColor Cyan
Write-Host '详细指南:        docs/connectors.md' -ForegroundColor Cyan
