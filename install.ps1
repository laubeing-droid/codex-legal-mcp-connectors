<#
.SYNOPSIS
  安装 Codex 中国法律 MCP 连接器
.DESCRIPTION
  写入 chineselaw（元典智库）/ 北大法宝 MCP 配置到 ~/.codex/config.toml。
  仅添加不存在的条目，不删除或覆盖已有配置。
#>

$ErrorActionPreference = 'Stop'
$ConfigPath = "$env:USERPROFILE\.codex\config.toml"

Write-Host '=== 安装 Codex 中国法律 MCP 连接器 ===' -ForegroundColor Green
Write-Host ''

function Add-McpServerToConfig {
    param([string]$Section, [string]$TomlBlock)
    if (-not (Test-Path $ConfigPath)) {
        New-Item -ItemType File -Force $ConfigPath | Out-Null
    }
    $content = Get-Content $ConfigPath -Encoding UTF8 -Raw
    if ($content -match "(?ms)^\[mcp_servers\.\Q$Section\E\]") {
        Write-Host "  [跳过] $Section (已存在)" -ForegroundColor DarkYellow
        return $false
    }
    Add-Content -Path $ConfigPath -Value "`n$TomlBlock" -Encoding UTF8
    Write-Host "  [添加] $Section" -ForegroundColor Green
    return $true
}

Write-Host '写入 MCP 连接器配置...' -ForegroundColor Yellow

# chineselaw
Add-McpServerToConfig -Section 'chineselaw' -TomlBlock @"
[mcp_servers.chineselaw]
command = "npx"
args = ["-y", "chineselaw-mcp"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true

[mcp_servers.chineselaw.env]
CHINESELAW_API_KEY = "YOUR_API_KEY"
"@

# 北大法宝 10 个服务
$pkulawServices = @(
    @{ name = "pkulaw-law-search"; url = "https://apim-gateway.pkulaw.com/mcp-law-search-service" },
    @{ name = "pkulaw-law-keyword"; url = "https://apim-gateway.pkulaw.com/mcp-law" },
    @{ name = "pkulaw-case-semantic-search"; url = "https://apim-gateway.pkulaw.com/mcp-case-search-service" },
    @{ name = "pkulaw-case-keyword"; url = "https://apim-gateway.pkulaw.com/mcp-case" },
    @{ name = "pkulaw-law-item-keyword"; url = "https://apim-gateway.pkulaw.com/mcp-fatiao" },
    @{ name = "pkulaw-law-recognition"; url = "https://apim-gateway.pkulaw.com/law_recognition" },
    @{ name = "pkulaw-case-number-recognition"; url = "https://apim-gateway.pkulaw.com/case_number_recognition" },
    @{ name = "pkulaw-citation-validator"; url = "https://apim-gateway.pkulaw.com/pku_citation_validator" },
    @{ name = "pkulaw-doc-link"; url = "https://apim-gateway.pkulaw.com/add-doc-link" },
    @{ name = "pkulaw-semantic-nlsql"; url = "https://apim-gateway.pkulaw.com/YOUR_NL_SQL_SERVICE_ID" }
)
foreach ($svc in $pkulawServices) {
    Add-McpServerToConfig -Section $svc.name -TomlBlock @"
[mcp_servers.$($svc.name)]
url = "$($svc.url)"
http_headers = { Authorization = "Bearer YOUR_ACCESS_TOKEN" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
"@
}

Write-Host ''
Write-Host '安装完成！重启 Codex Desktop 使配置生效。' -ForegroundColor Green
Write-Host ''
Write-Host '===== 下一步：替换凭证 =====' -ForegroundColor Cyan
Write-Host "  notepad `$env:USERPROFILE\.codex\config.toml" -ForegroundColor Cyan
Write-Host ''
Write-Host 'chineselaw（推荐，33 个工具）：' -ForegroundColor Cyan
Write-Host '  注册 https://open.chineselaw.com → 替换 CHINESELAW_API_KEY' -ForegroundColor Cyan
Write-Host ''
Write-Host '北大法宝 MCP 协议（10 个服务）：' -ForegroundColor Cyan
Write-Host '  注册 https://mcp.pkulaw.com → 替换所有 YOUR_ACCESS_TOKEN' -ForegroundColor Cyan
Write-Host ''
Write-Host '北大法宝 CLI 命令行（可选调试）：' -ForegroundColor Cyan
Write-Host '  npm install -g @pkulaw/mcp-cli' -ForegroundColor Cyan
Write-Host '  pkulaw-mcp init --authorization "Bearer YOUR_ACCESS_TOKEN"' -ForegroundColor Cyan
Write-Host ''
Write-Host '详细指南见 docs/connectors.md' -ForegroundColor Cyan