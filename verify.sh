#!/usr/bin/env bash
# verify.sh — 验证中国法律 MCP 连接器配置 (macOS / Linux)
# 用法: bash verify.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect.sh"

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'

echo -e "${CYAN}=== 中国法律 MCP 连接器 验证 ===${NC}\n"

active_envs=()
while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [ "$(env_installed "$line")" = "true" ]; then
        active_envs+=("$line")
    fi
done < <(get_environment_info)

if [ ${#active_envs[@]} -eq 0 ]; then
    echo -e "${RED}[!!] 未检测到任何 MCP 客户端环境。请先运行 bash install.sh${NC}"
    exit 1
fi

all_ok=true

for env_line in "${active_envs[@]}"; do
    cpath=$(env_config_path "$env_line")
    disp=$(env_display "$env_line")
    fmt=$(env_format "$env_line")

    echo -e "${YELLOW}>>> $disp${NC}"
    echo -e "    ${GRAY}配置: $cpath${NC}"

    if [ ! -f "$cpath" ]; then
        echo -e "  ${RED}[!!] 配置文件不存在${NC}"
        all_ok=false
        echo ""
        continue
    fi

    if [ "$fmt" = "toml" ]; then
        # TOML: grep sections
        sections=$(grep -oP '^\[mcp_servers\.\K[^\]]+' "$cpath" 2>/dev/null | sort -u || true)
        if [ -z "$sections" ]; then
            echo -e "  ${RED}[!!] 未找到任何 [mcp_servers] 配置${NC}"
            all_ok=false
        else
            while IFS= read -r section; do
                [ -z "$section" ] && continue
                if grep -A 20 "^\[mcp_servers\.$section\]" "$cpath" | grep -q "enabled\s*=\s*true"; then
                    echo -e "  ${GREEN}[OK] $section (已启用)${NC}"
                else
                    echo -e "  ${YELLOW}[!]  $section (已配置)${NC}"
                    all_ok=false
                fi
                # 检查占位符
                section_content=$(awk "/^\[mcp_servers\.$section\]/,/^\[mcp_servers\./" "$cpath" 2>/dev/null)
                if echo "$section_content" | grep -q "YOUR_API_KEY\|YOUR_ACCESS_TOKEN\|YOUR_APP_ID"; then
                    echo -e "         ${RED}[!] 凭证仍为占位符${NC}"
                    all_ok=false
                fi
            done <<< "$sections"
        fi
    else
        # JSON: use python3 or node
        if command -v python3 &>/dev/null; then
            python3 -c "
import json, sys
try:
    with open('$cpath') as f: data = json.load(f)
    servers = data.get('mcpServers', {})
    if not servers:
        print('  [!!] 未找到任何 mcpServers 配置')
        sys.exit(0)
    for name, svc in servers.items():
        if svc.get('command') or svc.get('url'):
            print(f'  [OK] {name} (已配置)')
        else:
            print(f'  [!]  {name} (配置不完整)')
        # 检查占位符
        env_vars = svc.get('env', {})
        for k, v in env_vars.items():
            if 'YOUR_' in str(v):
                print(f'         [!] {k} 仍为占位符')
        headers = svc.get('headers', {})
        auth = headers.get('Authorization', '')
        if 'YOUR_' in auth:
            print(f'         [!] Authorization 仍为占位符')
except Exception as e:
    print(f'  [!!] 配置文件损坏或格式错误: {e}')
" 2>/dev/null || { echo -e "  ${RED}[!!] 无法解析 JSON${NC}"; all_ok=false; }
        elif command -v node &>/dev/null; then
            node -e "
const fs = require('fs');
try {
    const data = JSON.parse(fs.readFileSync('$cpath','utf8'));
    const servers = data.mcpServers || {};
    const names = Object.keys(servers);
    if (names.length === 0) console.log('  [!!] 未找到任何 mcpServers 配置');
    names.forEach(name => {
        const svc = servers[name];
        console.log(svc.command||svc.url ? '  [OK] ' + name + ' (已配置)' : '  [!]  ' + name + ' (配置不完整)');
        const envVars = svc.env || {};
        Object.entries(envVars).forEach(([k,v]) => { if (String(v).includes('YOUR_')) console.log('         [!] ' + k + ' 仍为占位符'); });
        const auth = (svc.headers||{}).Authorization || '';
        if (auth.includes('YOUR_')) console.log('         [!] Authorization 仍为占位符');
    });
} catch(e) { console.log('  [!!] 配置文件损坏或格式错误'); }
" 2>/dev/null || { echo -e "  ${RED}[!!] 无法解析 JSON${NC}"; all_ok=false; }
        else
            echo -e "  ${RED}[!!] 需要 python3 或 node 来验证 JSON 配置${NC}"
            all_ok=false
        fi
    fi
    echo ""
done

# ─── npm 版本检查 ─────────────────────────────────────
echo -e "${YELLOW}npm 包版本:${NC}"
if command -v npm &>/dev/null; then
    for pkg in "@larksuiteoapi/lark-mcp" "@pkulaw/mcp-cli"; do
        latest=$(npm view "$pkg" version 2>/dev/null || echo "N/A")
        echo -e "  $pkg: latest=$latest"
    done
else
    echo "  npm 未安装"
fi

echo ""
if [ "$all_ok" = true ]; then
    echo -e "${GREEN}所有检查通过。${NC}"
else
    echo -e "${YELLOW}存在警告项，请检查上述标记。${NC}"
fi
