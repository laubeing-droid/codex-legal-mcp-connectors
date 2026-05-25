#!/usr/bin/env bash
# uninstall.sh — 卸载中国法律 MCP 连接器配置 (macOS / Linux)
# 用法: bash uninstall.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect.sh"

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; GRAY='\033[0;90m'; NC='\033[0m'

echo -e "${YELLOW}=== 卸载中国法律 MCP 连接器 ===${NC}\n"

active_envs=()
while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [ "$(env_installed "$line")" = "true" ]; then
        active_envs+=("$line")
    fi
done < <(get_environment_info)

if [ ${#active_envs[@]} -eq 0 ]; then
    active_envs=("codex|Codex Desktop|$HOME/.codex/config.toml|toml|true|mcp_servers")
fi

read -r -p "将从所有检测到的 MCP 客户端配置中移除法律连接器，确认？(y/N): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo -e "${GREEN}取消卸载。${NC}"
    exit 0
fi

# 要移除的 MCP Server 列表
REMOVE_SERVERS=(
    "yuandian-law" "yuandian-case" "yuandian-company" "chineselaw"
    "feishu"
    "pkulaw-law-search" "pkulaw-law-keyword" "pkulaw-case-semantic-search"
    "pkulaw-case-keyword" "pkulaw-law-item-keyword" "pkulaw-law-recognition"
    "pkulaw-case-number-recognition" "pkulaw-citation-validator"
    "pkulaw-doc-link" "pkulaw-semantic-nlsql"
    "rmfyalk" "flk-npc"
)

for env_line in "${active_envs[@]}"; do
    cpath=$(env_config_path "$env_line")
    disp=$(env_display "$env_line")
    fmt=$(env_format "$env_line")

    if [ ! -f "$cpath" ]; then
        echo -e "  ${GRAY}[!]  $disp: 配置文件不存在${NC}"
        continue
    fi

    removed=0
    if [ "$fmt" = "toml" ]; then
        for srv in "${REMOVE_SERVERS[@]}"; do
            if grep -q "\[mcp_servers\.$srv\]" "$cpath" 2>/dev/null; then
                # 用 Python 来精确删除 TOML section（比 sed 更可靠）
                python3 -c "
import re
with open('$cpath', 'r') as f: content = f.read()
# Remove the section block
content = re.sub(r'\[mcp_servers\.$srv\].*?(?=\[mcp_servers\.|\Z)', '', content, flags=re.DOTALL)
# Clean up excessive blank lines
content = re.sub(r'\n{3,}', '\n\n', content)
with open('$cpath', 'w') as f: f.write(content.strip() + '\n')
" 2>/dev/null && removed=$((removed + 1)) || true
            fi
        done
    else
        # JSON: use python3 to remove keys
        if command -v python3 &>/dev/null; then
            python3 -c "
import json, sys
with open('$cpath') as f: data = json.load(f)
if 'mcpServers' in data:
    removed = 0
    for srv in ['yuandian-law','yuandian-case','yuandian-company','chineselaw','feishu',
                'pkulaw-law-search','pkulaw-law-keyword','pkulaw-case-semantic-search',
                'pkulaw-case-keyword','pkulaw-law-item-keyword','pkulaw-law-recognition',
                'pkulaw-case-number-recognition','pkulaw-citation-validator',
                'pkulaw-doc-link','pkulaw-semantic-nlsql','rmfyalk','flk-npc']:
        if srv in data['mcpServers']:
            del data['mcpServers'][srv]
            removed += 1
    with open('$cpath', 'w') as f: json.dump(data, f, indent=2, ensure_ascii=False)
    print(removed)
" 2>/dev/null
        fi
        removed=0  # fallback
    fi

    if [ "$removed" -gt 0 ] 2>/dev/null; then
        echo -e "  ${GREEN}[OK] $disp: 移除了 $removed 个连接器${NC}"
    else
        echo -e "  ${GRAY}[!]  $disp: 未找到法律连接器配置${NC}"
    fi
done

echo ""
echo -e "${GREEN}卸载完成。重启对应客户端使生效。${NC}"
echo "注：本操作仅移除 MCP 连接器配置，不会删除技能文件或其他数据。"
