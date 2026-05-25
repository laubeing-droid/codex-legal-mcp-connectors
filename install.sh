#!/usr/bin/env bash
# install.sh — 安装中国法律 MCP 连接器 (macOS / Linux)
# 用法: bash install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect.sh"

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'

echo -e "${GREEN}=== 安装中国法律 MCP 连接器 ===${NC}\n"

# ─── 1. 环境检测 ──────────────────────────────────────
echo -e "${YELLOW}[1/8] 检测本机 MCP 客户端环境...${NC}"
active_envs=()
while IFS= read -r line; do
    [ -z "$line" ] && continue
    installed=$(env_installed "$line")
    if [ "$installed" = "true" ]; then
        icon="[OK]"
        color="$GREEN"
        active_envs+=("$line")
    else
        icon="[!]"
        color="$GRAY"
    fi
    echo -e "  $icon $(env_display "$line")${NC}"
    echo -e "        配置: $(env_config_path "$line") ($(env_format "$line"))${GRAY}${NC}"
done < <(get_environment_info)

if [ ${#active_envs[@]} -eq 0 ]; then
    echo -e "  ${YELLOW}未检测到已安装的 MCP 客户端，将至少为 Codex Desktop 创建配置。${NC}"
    active_envs=("codex|Codex Desktop|$HOME/.codex/config.toml|toml|true|mcp_servers")
fi

# ─── 2. 前置检查 ──────────────────────────────────────
echo ""
echo -e "${YELLOW}[2/8] 前置检查...${NC}"
node_ok=true
if ! command -v node &>/dev/null; then
    echo -e "  ${RED}[!!] Node.js 未安装！飞书 / pkulaw 需要 Node.js >= 18${NC}"
    echo -e "  ${CYAN}       安装: brew install node (macOS) 或 https://nodejs.org${NC}"
    node_ok=false
else
    node_ver=$(node --version)
    echo -e "  ${GREEN}[OK] Node.js $node_ver${NC}"
fi
echo ""

# ─── 3. 元典智库 ──────────────────────────────────────
echo -e "${CYAN}[3/8] 元典智库 — 中国法律检索（36 API + 33 MCP 工具）${NC}"
echo -e "   注册: https://open.chineselaw.com → API 管理 → 创建 API Key${GRAY}${NC}"
echo -e "   REST: https://open.chineselaw.com/open/{routeKey} (X-API-Key)${GRAY}${NC}"
echo ""
echo -e "  接入方式:${YELLOW}${NC}"
echo -e "    [1] Streamable HTTP MCP（官方推荐，3 个细分 Server）${CYAN}${NC}"
echo -e "    [3] 跳过${GRAY}${NC}"
read -r -p "  请选择 (默认 1): " mode
mode="${mode:-1}"

if [ "$mode" != "3" ]; then
    read -r -p "  请输入 API Key（留空=使用占位符）: " yuandian_key
    yuandian_key="${yuandian_key:-YOUR_API_KEY}"
    if [ "$yuandian_key" = "YOUR_API_KEY" ]; then
        echo -e "  ${YELLOW}使用占位符，稍后手动替换${NC}"
    fi

    while IFS= read -r svc_line; do
        [ -z "$svc_line" ] && continue
        svc_name=$(echo "$svc_line" | cut -d'|' -f1)
        svc_url=$(echo "$svc_line" | cut -d'|' -f2)
        svc_display=$(echo "$svc_line" | cut -d'|' -f3)

        for env_line in "${active_envs[@]}"; do
            fmt=$(env_format "$env_line")
            cpath=$(env_config_path "$env_line")
            disp=$(env_display "$env_line")

            if [ "$fmt" = "toml" ]; then
                toml=$(get_yuandian_http_toml "$svc_name" "$svc_url" "$yuandian_key")
                if write_mcp_to_codex "$cpath" "$svc_name" "$toml"; then
                    echo -e "  ${GREEN}[添加] $disp -> $svc_name ($svc_display)${NC}"
                else
                    echo -e "  ${YELLOW}[跳过] $disp -> $svc_name（已存在）${NC}"
                fi
            else
                json=$(get_yuandian_http_json "$svc_url" "$yuandian_key")
                if write_mcp_to_claude "$cpath" "$svc_name" "$json"; then
                    echo -e "  ${GREEN}[添加] $disp -> $svc_name ($svc_display)${NC}"
                else
                    echo -e "  ${YELLOW}[跳过] $disp -> $svc_name（已存在）${NC}"
                fi
            fi
        done
    done < <(get_yuandian_http_servers "$yuandian_key")
else
    echo "  跳过元典智库"
fi
echo ""

# ─── 4. 飞书 ──────────────────────────────────────────
echo -e "${CYAN}[4/8] 飞书 — 文档 / 审批 / 日历 / 消息${NC}"
echo -e "   开通: https://open.feishu.cn/app → 创建应用 → 获取 App ID + App Secret${GRAY}${NC}"
echo ""
read -r -p "  是否安装飞书 MCP？(y/N): " install_feishu
if [ "$install_feishu" = "y" ] || [ "$install_feishu" = "Y" ]; then
    if [ "$node_ok" = false ]; then
        echo -e "  ${RED}[!!] 跳过：需要 Node.js${NC}"
    else
        read -r -p "  请输入 App ID: " feishu_app_id
        read -r -p "  请输入 App Secret: " feishu_app_secret
        feishu_app_id="${feishu_app_id:-YOUR_APP_ID}"
        feishu_app_secret="${feishu_app_secret:-YOUR_APP_SECRET}"

        for env_line in "${active_envs[@]}"; do
            fmt=$(env_format "$env_line")
            cpath=$(env_config_path "$env_line")
            disp=$(env_display "$env_line")
            if [ "$fmt" = "toml" ]; then
                toml=$(get_feishu_toml "$feishu_app_id" "$feishu_app_secret")
                if write_mcp_to_codex "$cpath" "feishu" "$toml"; then
                    echo -e "  ${GREEN}[添加] $disp -> feishu${NC}"
                else
                    echo -e "  ${YELLOW}[跳过] $disp -> feishu（已存在）${NC}"
                fi
            else
                json=$(get_feishu_json "$feishu_app_id" "$feishu_app_secret")
                if write_mcp_to_claude "$cpath" "feishu" "$json"; then
                    echo -e "  ${GREEN}[添加] $disp -> feishu${NC}"
                else
                    echo -e "  ${YELLOW}[跳过] $disp -> feishu（已存在）${NC}"
                fi
            fi
        done
    fi
fi
echo ""

# ─── 5. 北大法宝 ──────────────────────────────────────
echo -e "${CYAN}[5/8] 北大法宝 — pkulaw 系列 MCP 连接器${NC}"
echo -e "   注册: https://mcp.pkulaw.com → 获取 Access Token${GRAY}${NC}"
echo ""
read -r -p "  是否安装北大法宝 MCP？(y/N): " install_pkulaw
if [ "$install_pkulaw" = "y" ] || [ "$install_pkulaw" = "Y" ]; then
    if [ "$node_ok" = false ]; then
        echo -e "  ${RED}[!!] 跳过：需要 Node.js${NC}"
    else
        read -r -p "  请输入 Access Token: " pkulaw_token
        pkulaw_token="${pkulaw_token:-YOUR_ACCESS_TOKEN}"

        echo -e "  ${YELLOW}选择要安装的服务（多选，用逗号分隔，如 1,3,5）:${NC}"
        echo "    [1] 法宝法条检索"
        echo "    [2] 法宝法条关键词检索"
        echo "    [3] 法宝案例语义检索"
        echo "    [4] 法宝案例关键词检索"
        echo "    [5] 法宝法条逐条检索"
        echo "    [6] 法宝法条识别"
        echo "    [7] 法宝案号识别"
        echo "    [8] 法宝引用核验"
        echo "    [9] 法宝超链"
        echo "    [10] 法宝语义检索（NL-SQL）"
        echo "    [a] 全部安装"
        read -r -p "  请输入: " pkulaw_sel

        declare -A PKULAW_SERVICES=(
            [1]="pkulaw-law-search|https://apim-gateway.pkulaw.com/assistant/mcp-law-search/mcp"
            [2]="pkulaw-law-keyword|https://apim-gateway.pkulaw.com/assistant/mcp-law-keyword/mcp"
            [3]="pkulaw-case-semantic-search|https://apim-gateway.pkulaw.com/assistant/mcp-case-search/mcp"
            [4]="pkulaw-case-keyword|https://apim-gateway.pkulaw.com/assistant/mcp-case-keyword/mcp"
            [5]="pkulaw-law-item-keyword|https://apim-gateway.pkulaw.com/assistant/mcp-law-item/mcp"
            [6]="pkulaw-law-recognition|https://apim-gateway.pkulaw.com/assistant/mcp-law-recognition/mcp"
            [7]="pkulaw-case-number-recognition|https://apim-gateway.pkulaw.com/assistant/mcp-case-recognition/mcp"
            [8]="pkulaw-citation-validator|https://apim-gateway.pkulaw.com/assistant/mcp-citation/mcp"
            [9]="pkulaw-doc-link|https://apim-gateway.pkulaw.com/assistant/mcp-doc-link/mcp"
            [10]="pkulaw-semantic-nlsql|https://apim-gateway.pkulaw.com/assistant/mcp-pkulaw-search/mcp"
        )

        selected=()
        if [ "$pkulaw_sel" = "a" ] || [ "$pkulaw_sel" = "A" ] || [ -z "$pkulaw_sel" ]; then
            selected=(1 2 3 4 5 6 7 8 9 10)
        else
            IFS=',' read -ra nums <<< "$pkulaw_sel"
            for n in "${nums[@]}"; do
                n=$(echo "$n" | xargs)
                if [ -n "${PKULAW_SERVICES[$n]:-}" ]; then
                    selected+=("$n")
                fi
            done
        fi

        for idx in "${selected[@]}"; do
            svc="${PKULAW_SERVICES[$idx]}"
            svc_name=$(echo "$svc" | cut -d'|' -f1)
            svc_url=$(echo "$svc" | cut -d'|' -f2)

            for env_line in "${active_envs[@]}"; do
                fmt=$(env_format "$env_line")
                cpath=$(env_config_path "$env_line")
                disp=$(env_display "$env_line")
                if [ "$fmt" = "toml" ]; then
                    toml="[mcp_servers.$svc_name]\nurl = \"$svc_url\"\nhttp_headers = { Authorization = \"Bearer $pkulaw_token\" }\nstartup_timeout_sec = 30\ntool_timeout_sec = 600\nenabled = true"
                    if write_mcp_to_codex "$cpath" "$svc_name" "$toml"; then
                        echo -e "  ${GREEN}[添加] $disp -> $svc_name${NC}"
                    fi
                else
                    json="{\"url\":\"$svc_url\",\"headers\":{\"Authorization\":\"Bearer $pkulaw_token\"}}"
                    if write_mcp_to_claude "$cpath" "$svc_name" "$json"; then
                        echo -e "  ${GREEN}[添加] $disp -> $svc_name${NC}"
                    fi
                fi
            done
        done
    fi
fi
echo ""

# ─── 6. 完成 ──────────────────────────────────────────
echo -e "${YELLOW}[8/8] 安装完成！${NC}"
echo ""
echo -e "${CYAN}已配置的 MCP 客户端环境:${NC}"
for env_line in "${active_envs[@]}"; do
    echo -e "  - $(env_display "$env_line"): $(env_config_path "$env_line")"
done
echo ""
echo -e "${CYAN}===== 后续步骤 =====${NC}"
echo "1. 重启对应的 MCP 客户端"
echo "2. 运行 bash verify.sh 验证配置"
echo "3. (如需替换凭证) 修改上述配置文件中的占位符"
echo ""
echo "元典智库注册: https://open.chineselaw.com"
echo "飞书开通:     https://open.feishu.cn/app"
echo "北大法宝注册: https://mcp.pkulaw.com"
echo "详细指南:     docs/connectors.md"
