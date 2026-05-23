#!/usr/bin/env bash
# detect.sh — 检测 Codex/Claude Code/Claude Desktop 环境 (macOS/Linux)
# 被 install.sh / verify.sh / update.sh 引用
# 用法: source "$(dirname "$0")/detect.sh"

detect_environments() {
    ENVIRONMENTS="[]"

    # Codex Desktop
    CODEX_CONFIG="${HOME}/.codex/config.toml"
    if [ -d "${HOME}/.codex" ]; then
        ENVIRONMENTS=$(echo "$ENVIRONMENTS" | python3 -c "
import json,sys
e=json.load(sys.stdin)
e.append({'name':'codex','display':'Codex Desktop','config':'${CODEX_CONFIG//\'/\\\'}','format':'toml'})
print(json.dumps(e))
" 2>/dev/null || echo "$ENVIRONMENTS")
    fi

    # Claude Code
    CLAUDE_CODE_CONFIG="${HOME}/.claude/settings.json"
    if [ -f "$CLAUDE_CODE_CONFIG" ]; then
        ENVIRONMENTS=$(echo "$ENVIRONMENTS" | python3 -c "
import json,sys
e=json.load(sys.stdin)
e.append({'name':'claude-code','display':'Claude Code','config':'${CLAUDE_CODE_CONFIG//\'/\\\'}','format':'json'})
print(json.dumps(e))
" 2>/dev/null || echo "$ENVIRONMENTS")
    fi

    # Claude Desktop (macOS)
    CLAUDE_DESKTOP_CONFIG="${HOME}/Library/Application Support/Claude/claude_desktop_config.json"
    if [ -f "$CLAUDE_DESKTOP_CONFIG" ]; then
        ENVIRONMENTS=$(echo "$ENVIRONMENTS" | python3 -c "
import json,sys
e=json.load(sys.stdin)
e.append({'name':'claude-desktop','display':'Claude Desktop','config':'${CLAUDE_DESKTOP_CONFIG//\'/\\\'}','format':'json'})
print(json.dumps(e))
" 2>/dev/null || echo "$ENVIRONMENTS")
    fi

    # Fallback: at least Codex
    if [ "$ENVIRONMENTS" = "[]" ]; then
        ENVIRONMENTS='[{"name":"codex","display":"Codex Desktop","config":"'${CODEX_CONFIG}'","format":"toml"}]'
    fi

    echo "$ENVIRONMENTS"
}

# TOML 写入（Codex）
write_mcp_toml() {
    local config_path="$1"
    local section="$2"
    local toml_block="$3"
    local dir
    dir=$(dirname "$config_path")
    mkdir -p "$dir"
    touch "$config_path"
    if grep -q "\[mcp_servers\.${section}\]" "$config_path" 2>/dev/null; then
        return 1  # 已存在
    fi
    echo "" >> "$config_path"
    echo "$toml_block" >> "$config_path"
    return 0
}

# JSON 写入（Claude Code / Claude Desktop）— 使用 Python 保证 JSON 操作正确
write_mcp_json() {
    local config_path="$1"
    local server_id="$2"
    local server_json="$3"
    local dir
    dir=$(dirname "$config_path")
    mkdir -p "$dir"

    python3 -c "
import json, os

config_path = '${config_path//\'/\\\'}'
server_id = '${server_id//\'/\\\'}'
server_config = json.loads('${server_json//\'/\\\'}')

if os.path.exists(config_path):
    with open(config_path, 'r', encoding='utf-8') as f:
        try:
            config = json.load(f)
        except:
            config = {}
else:
    config = {}

if 'mcpServers' not in config:
    config['mcpServers'] = {}
if 'env' not in config:
    config['env'] = {}

if server_id in config['mcpServers']:
    exit(1)  # 已存在

config['mcpServers'][server_id] = server_config

with open(config_path, 'w', encoding='utf-8') as f:
    json.dump(config, f, ensure_ascii=False, indent=2)

exit(0)
" 2>/dev/null
    return $?
}
