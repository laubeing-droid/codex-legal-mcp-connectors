#!/usr/bin/env bash
# update.sh — 更新中国法律 MCP 连接器配置 (macOS / Linux)
# 用法: bash update.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect.sh"

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'

echo -e "${GREEN}=== 更新中国法律 MCP 连接器 ===${NC}\n"

# ─── 1. 环境检测 ──────────────────────────────────────
echo -e "${YELLOW}[1/5] 检测 MCP 客户端环境...${NC}"
active_envs=()
while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [ "$(env_installed "$line")" = "true" ]; then
        active_envs+=("$line")
        echo -e "  [OK] $(env_display "$line")"
    fi
done < <(get_environment_info)

if [ ${#active_envs[@]} -eq 0 ]; then
    echo -e "  ${RED}[!!] 未检测到任何 MCP 客户端环境${NC}"
    exit 1
fi
echo ""

# ─── 2. 配置完整性检查 ────────────────────────────────
echo -e "${YELLOW}[2/5] 检查配置完整性...${NC}"
config_ok=true
for env_line in "${active_envs[@]}"; do
    cpath=$(env_config_path "$env_line")
    disp=$(env_display "$env_line")
    fmt=$(env_format "$env_line")
    if [ ! -f "$cpath" ]; then
        echo -e "  ${RED}[!!] $disp: 配置文件不存在${NC}"
        config_ok=false
        continue
    fi
    if [ "$fmt" = "toml" ]; then
        count=$(grep -c '^\[mcp_servers\.' "$cpath" 2>/dev/null || echo 0)
        echo -e "  [OK] $disp: $count 个 MCP Server"
    else
        if command -v python3 &>/dev/null; then
            count=$(python3 -c "import json; d=json.load(open('$cpath')); print(len(d.get('mcpServers',{})))" 2>/dev/null || echo 0)
        elif command -v node &>/dev/null; then
            count=$(node -e "try{const d=JSON.parse(require('fs').readFileSync('$cpath','utf8'));console.log(Object.keys(d.mcpServers||{}).length)}catch(e){console.log(0)}" 2>/dev/null)
        else
            count="?"
        fi
        echo -e "  [OK] $disp: $count 个 MCP Server"
    fi
done
echo ""

# ─── 3. npm 版本检查 ──────────────────────────────────
echo -e "${YELLOW}[3/5] npm 包版本检查...${NC}"
if command -v npm &>/dev/null; then
    for pkg in "@larksuiteoapi/lark-mcp" "@pkulaw/mcp-cli"; do
        latest=$(npm view "$pkg" version 2>/dev/null || echo "N/A")
        local_ver=$(npm list -g "$pkg" --depth=0 2>/dev/null | grep "$pkg" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "未安装")
        echo -e "  $pkg: 本地=$local_ver  最新=$latest"
    done
else
    echo "  npm 未安装，跳过版本检查"
fi
echo ""

# ─── 4. 凭证检查 ──────────────────────────────────────
echo -e "${YELLOW}[4/5] 凭证状态检查...${NC}"
cred_issues=false
for env_line in "${active_envs[@]}"; do
    cpath=$(env_config_path "$env_line")
    [ -f "$cpath" ] || continue
    config_content=$(cat "$cpath")
    if echo "$config_content" | grep -q "YOUR_API_KEY\|YOUR_ACCESS_TOKEN\|YOUR_APP_ID"; then
        echo -e "  ${RED}[!!] $(env_display "$env_line"): 存在占位符凭证${NC}"
        cred_issues=true
    fi
done
if [ "$cred_issues" = false ]; then
    echo -e "  ${GREEN}凭证状态正常${NC}"
fi
echo ""

# ─── 5. 汇总 ──────────────────────────────────────────
echo -e "${YELLOW}[5/5] 汇总${NC}"
for env_line in "${active_envs[@]}"; do
    echo -e "  ${CYAN}$(env_display "$env_line"): $(env_config_path "$env_line")${NC}"
done
echo ""
echo -e "${GREEN}更新验证完成。重启 MCP 客户端使新内容生效。${NC}"
