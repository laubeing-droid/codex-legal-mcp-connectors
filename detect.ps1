<#
.SYNOPSIS
  检测Codex/Claude Code/Claude Desktop环境并返回配置路径
.DESCRIPTION
  自动检测本机安装了哪些MCP客户端环境及各自的配置路径/格式。
  返回对象包含每个环境的配置信息。
#>

function Get-EnvironmentInfo {
    $envs = @()

    # ---- Codex Desktop ----
    $codexConfig = "$env:USERPROFILE\.codex\config.toml"
    $codexInstalled = Test-Path "$env:USERPROFILE\.codex"
    $envs += @{
        Name       = 'codex'
        Display    = 'Codex Desktop'
        ConfigPath = $codexConfig
        Format     = 'toml'
        Installed  = $codexInstalled
        McpSection = 'mcp_servers'        # TOML: [mcp_servers.xxx]
    }

    # ---- Claude Code (terminal) ----
    $claudeCodeConfig = "$env:USERPROFILE\.claude\settings.json"
    $claudeCodeInstalled = Test-Path $claudeCodeConfig
    $envs += @{
        Name       = 'claude-code'
        Display    = 'Claude Code'
        ConfigPath = $claudeCodeConfig
        Format     = 'json'
        Installed  = $claudeCodeInstalled
        McpSection = 'mcpServers'         # JSON: { mcpServers: { xxx: ... } }
    }

    # ---- Claude Desktop ----
    $claudeDesktopConfig = "$env:LOCALAPPDATA\Claude\claude_desktop_config.json"
    if (-not (Test-Path $claudeDesktopConfig)) {
        $claudeDesktopConfig = "$env:APPDATA\Claude\claude_desktop_config.json"
    }
    $claudeDesktopInstalled = Test-Path $claudeDesktopConfig
    $envs += @{
        Name       = 'claude-desktop'
        Display    = 'Claude Desktop'
        ConfigPath = $claudeDesktopConfig
        Format     = 'json'
        Installed  = $claudeDesktopInstalled
        McpSection = 'mcpServers'
    }

    return $envs
}

function Write-McpToCodex {
    param([string]$ConfigPath, [string]$Section, [string]$TomlBlock)
    if (-not (Test-Path (Split-Path -Parent $ConfigPath))) {
        $null = New-Item -ItemType Directory -Force (Split-Path -Parent $ConfigPath)
    }
    if (-not (Test-Path $ConfigPath)) {
        $null = New-Item -ItemType File -Force $ConfigPath
    }
    $content = Get-Content $ConfigPath -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
    if ($content -match "(?ms)^\[mcp_servers\.\Q$Section\E\]") {
        return $false  # 已存在
    }
    Add-Content -Path $ConfigPath -Value "`n$TomlBlock" -Encoding UTF8
    return $true
}

function Write-McpToClaude {
    param([string]$ConfigPath, [string]$ServerId, [hashtable]$ServerConfig)
    $dir = Split-Path -Parent $ConfigPath
    if (-not (Test-Path $dir)) { $null = New-Item -ItemType Directory -Force $dir }

    $json = @{}
    if (Test-Path $ConfigPath) {
        try { $json = Get-Content $ConfigPath -Encoding UTF8 -Raw | ConvertFrom-Json }
        catch { $json = @{} }
    }
    # ConvertFrom-Json returns PSCustomObject, convert to hashtable for easier manipulation
    $config = @{}
    $json.PSObject.Properties | ForEach-Object { $config[$_.Name] = $_.Value }

    if (-not $config.ContainsKey('mcpServers')) {
        $config['mcpServers'] = @{}
    }
    if (-not $config.ContainsKey('env')) {
        $config['env'] = @{}
    }

    if ($config['mcpServers'].ContainsKey($ServerId)) {
        return $false  # 已存在
    }

    $config['mcpServers'][$ServerId] = $ServerConfig

    # Write back with pretty formatting
    $jsonStr = $config | ConvertTo-Json -Depth 10
    Set-Content -Path $ConfigPath -Value $jsonStr -Encoding UTF8
    return $true
}

function Get-ChineselawStdConfig {
    param([string]$ApiKey)
    return @{
        command = 'npx'
        args    = @('-y', 'chineselaw-mcp')
        env     = @{ CHINESELAW_API_KEY = $ApiKey }
    }
}

function Get-PkulawHttpConfig {
    param([string]$Url, [string]$Token)
    return @{
        url     = $Url
        headers = @{ Authorization = "Bearer $Token" }
    }
}

Export-ModuleMember -Function Get-EnvironmentInfo, Write-McpToCodex, Write-McpToClaude,
    Get-ChineselawStdConfig, Get-PkulawHttpConfig
