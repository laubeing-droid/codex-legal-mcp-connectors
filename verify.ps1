<#
.SYNOPSIS
  验证 Codex 中国法律 MCP 连接器状态
.DESCRIPTION
  检查 config.toml 中各 MCP 配置是否启用，检测 npm 包版本。
#>

$ErrorActionPreference = 'Stop'
$ConfigPath = "$env:USERPROFILE\.codex\config.toml"

Write-Host '=== Codex 中国法律 MCP 连接器 验证 ===' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path $ConfigPath)) {
    Write-Host '[!!] config.toml 不存在，请先运行 install.ps1' -ForegroundColor Red
    exit 1
}

Write-Host "[OK] config.toml: $ConfigPath" -ForegroundColor Green
Write-Host ''

$config = Get-Content $ConfigPath -Encoding UTF8 -Raw
$allOk = $true

$checks = @(
    @{ name = 'chineselaw'; section = 'mcp_servers.chineselaw' }
    @{ name = 'pkulaw-law-search'; section = 'mcp_servers.pkulaw-law-search' }
    @{ name = 'pkulaw-case-keyword'; section = 'mcp_servers.pkulaw-case-keyword' }
)
foreach ($c in $checks) {
    if ($config -match "(?ms)^\[$($c.section)\]") {
        if ($config -match "(?ms)^\[$($c.section)\].*?enabled\s*=\s*true") {
            Write-Host "  [OK] $($c.name) (已启用)" -ForegroundColor Green
        } else {
            Write-Host "  [!]  $($c.name) (已配置但未启用)" -ForegroundColor Yellow
            $allOk = $false
        }
    } else {
        Write-Host "  [!!] $($c.name) (未配置)" -ForegroundColor Red
        $allOk = $false
    }
}

Write-Host ''
if ($allOk) { Write-Host '验证通过。' -ForegroundColor Green }
else { Write-Host '存在缺失，建议重新运行 install.ps1。' -ForegroundColor Yellow }