#!/usr/bin/env bash
# detect.sh — 检测 MCP 客户端环境 + 配置模板函数 (macOS / Linux)
# 被 install.sh / update.sh / uninstall.sh / verify.sh 引用
# 用法: source "$(dirname "$0")/detect.sh"

# ─── 环境检测 ──────────────────────────────────────────
get_environment_info() {
    local envs=()

    # Codex Desktop
    local codex_config="$HOME/.codex/config.toml"
    local codex_installed="false"
    [ -d "$HOME/.codex" ] && codex_installed="true"
    envs+=("codex|Codex Desktop|$codex_config|toml|$codex_installed|mcp_servers")

    # Claude Code (terminal)
    local claude_code_config="$HOME/.claude/settings.json"
    local claude_code_installed="false"
    [ -f "$claude_code_config" ] && claude_code_installed="true"
    envs+=("claude-code|Claude Code|$claude_code_config|json|$claude_code_installed|mcpServers")

    # Claude Desktop (macOS)
    local claude_desktop_config="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    local claude_desktop_installed="false"
    [ -f "$claude_desktop_config" ] && claude_desktop_installed="true"
    envs+=("claude-desktop|Claude Desktop|$claude_desktop_config|json|$claude_desktop_installed|mcpServers")

    printf '%s\n' "${envs[@]}"
}

# 从 env 行提取字段
env_name()        { echo "$1" | cut -d'|' -f1; }
env_display()     { echo "$1" | cut -d'|' -f2; }
env_config_path() { echo "$1" | cut -d'|' -f3; }
env_format()      { echo "$1" | cut -d'|' -f4; }
env_installed()   { echo "$1" | cut -d'|' -f5; }
env_mcp_section() { echo "$1" | cut -d'|' -f6; }

# ─── TOML 写入 (Codex Desktop) ─────────────────────────
write_mcp_to_codex() {
    local config_path="$1"
    local section="$2"
    local toml_block="$3"

    mkdir -p "$(dirname "$config_path")"
    [ ! -f "$config_path" ] && touch "$config_path"

    if grep -q "\[mcp_servers\.$section\]" "$config_path" 2>/dev/null; then
        return 1  # 已存在
    fi

    printf '\n%s\n' "$toml_block" >> "$config_path"
    return 0
}

# ─── JSON 写入 (Claude Code / Claude Desktop) ───────────
write_mcp_to_claude() {
    local config_path="$1"
    local server_id="$2"
    local server_json="$3"

    mkdir -p "$(dirname "$config_path")"

    if command -v python3 &>/dev/null; then
        python3 -c "
import json, sys, os
path = '$config_path'
data = {}
if os.path.exists(path):
    try:
        with open(path) as f: data = json.load(f)
    except: data = {}
if 'mcpServers' not in data: data['mcpServers'] = {}
if '$server_id' in data['mcpServers']:
    sys.exit(1)
data['mcpServers']['$server_id'] = $server_json
with open(path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
"
        return $?
    elif command -v node &>/dev/null; then
        node -e "
const fs = require('fs');
let data = {};
const path = '$config_path';
if (fs.existsSync(path)) {
    try { data = JSON.parse(fs.readFileSync(path,'utf8')); } catch(e) {}
}
if (!data.mcpServers) data.mcpServers = {};
if (data.mcpServers['$server_id']) process.exit(1);
data.mcpServers['$server_id'] = $server_json;
fs.writeFileSync(path, JSON.stringify(data, null, 2));
"
        return $?
    else
        echo "  [!!] 需要 python3 或 node 来处理 JSON 配置" >&2
        return 2
    fi
}

# ─── 元典智库 (chineselaw) 配置模板 ────────────────────
get_yuandian_http_servers() {
    local api_key="$1"
    cat <<EOF
yuandian-law|https://open.chineselaw.com/mcp/law/stream|元典-法律法规|5 个法律工具
yuandian-case|https://open.chineselaw.com/mcp/case/stream|元典-案例文书|4 个案例工具
yuandian-company|https://open.chineselaw.com/mcp/company/stream|元典-企业信息|26 个企业工具
EOF
}

get_yuandian_http_toml() {
    local name="$1" url="$2" api_key="$3"
    cat <<TOML
[mcp_servers.$name]
type = "http"
url = "$url"
http_headers = { Authorization = "Bearer $api_key", Accept = "application/json, text/event-stream" }
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
TOML
}

get_yuandian_http_json() {
    local url="$1" api_key="$2"
    cat <<JSON
{"url":"$url","headers":{"Authorization":"Bearer $api_key","Accept":"application/json, text/event-stream"}}
JSON
}

# ─── 飞书 (larksuite) 配置模板 ─────────────────────────
get_feishu_json() {
    local app_id="$1" app_secret="$2"
    cat <<JSON
{"command":"npx","args":["-y","@larksuiteoapi/lark-mcp"],"env":{"LARK_APP_ID":"$app_id","LARK_APP_SECRET":"$app_secret"}}
JSON
}

get_feishu_toml() {
    local app_id="$1" app_secret="$2"
    cat <<TOML
[mcp_servers.feishu]
command = "npx"
args = ["-y", "@larksuiteoapi/lark-mcp"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true

[mcp_servers.feishu.env]
LARK_APP_ID = "$app_id"
LARK_APP_SECRET = "$app_secret"
TOML
}

# ─── 北大法宝 (pkulaw) 配置模板 ────────────────────────
get_pkulaw_http_json() {
    local url="$1" token="$2"
    cat <<JSON
{"url":"$url","headers":{"Authorization":"Bearer $token"}}
JSON
}

# ─── 自建 Python MCP 配置模板 ──────────────────────────
get_self_hosted_rmfyalk_toml() {
    local token="$1" repo_root="$2"
    cat <<TOML
[mcp_servers.rmfyalk]
command = "python"
args = ["$repo_root/servers/rmfyalk/scripts/server.py"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true

[mcp_servers.rmfyalk.env]
RMFYALK_TOKEN = "$token"
TOML
}

get_self_hosted_flknpc_toml() {
    local repo_root="$1"
    cat <<TOML
[mcp_servers.flk-npc]
command = "python"
args = ["$repo_root/servers/flk-npc/scripts/server.py"]
startup_timeout_sec = 30
tool_timeout_sec = 600
enabled = true
TOML
}
