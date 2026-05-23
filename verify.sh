#!/usr/bin/env bash
# verify.sh — 通用验证脚本：检查 Codex/Claude Code/Claude Desktop MCP 配置 (macOS/Linux)
set -euo pipefail

MY_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${MY_DIR}/detect.sh"

echo "=== 中国法律 MCP 连接器 验证 ==="
echo ""

ENVS=$(detect_environments)
ALL_OK=true

echo "$ENVS" | python3 -c "
import json, sys, os, re

envs = json.load(sys.stdin)
all_ok = True

for e in envs:
    cp = e['config']
    display = e['display']
    fmt = e['format']

    print(f'>>> {display}')
    print(f'    配置: {cp}')

    if not os.path.exists(cp):
        print(f'  [!!] 配置文件不存在')
        all_ok = False
        print()
        continue

    if fmt == 'toml':
        with open(cp, 'r', encoding='utf-8') as f:
            content = f.read()
        sections = re.findall(r'\\[mcp_servers\\.([^\\]]+)\\]', content)
        if not sections:
            print(f'  [!!] 未找到任何 [mcp_servers] 配置')
            all_ok = False
        for s in sorted(set(sections)):
            if re.search(r'\\[mcp_servers\\.' + re.escape(s) + r'\\][\\s\\S]*?enabled\\s*=\\s*true', content):
                print(f'  [OK] {s} (已启用)')
            else:
                print(f'  [!]  {s} (已配置)')
            # check placeholders
            if s == 'chineselaw' and 'CHINESELAW_API_KEY = \"YOUR_API_KEY\"' in content:
                print(f'         [!] API Key 仍为占位符')
                all_ok = False
            if s.startswith('pkulaw') and 'Bearer YOUR_ACCESS_TOKEN' in content:
                print(f'         [!] Token 仍为占位符')
                all_ok = False
    else:
        try:
            import json as j
            with open(cp, 'r', encoding='utf-8') as f:
                cfg = j.load(f)
            servers = cfg.get('mcpServers', {})
            if not servers:
                print(f'  [!!] 未找到任何 mcpServers 配置')
                all_ok = False
            else:
                for name, svc in servers.items():
                    if svc.get('command') or svc.get('url'):
                        print(f'  [OK] {name} (已配置)')
                        env_vars = svc.get('env', {})
                        if env_vars.get('CHINESELAW_API_KEY') == 'YOUR_API_KEY':
                            print(f'         [!] API Key 仍为占位符')
                            all_ok = False
                        headers = svc.get('headers', {})
                        auth = headers.get('Authorization', '')
                        if 'Bearer YOUR_ACCESS_TOKEN' in auth:
                            print(f'         [!] Token 仍为占位符')
                            all_ok = False
                    else:
                        print(f'  [!]  {name} (配置不完整)')
                        all_ok = False
        except:
            print(f'  [!!] 配置文件损坏或格式错误')
            all_ok = False

    print()

if not all_ok:
    exit(1)
" 2>&1
EXIT_CODE=$?
[ $EXIT_CODE -ne 0 ] && ALL_OK=false

echo ""
if [ "$ALL_OK" = true ]; then
    echo "✓ 验证通过。所有配置正常。"
else
    echo "⚠ 存在上述问题，请参考 docs/connectors.md 修复。"
fi
