# 快速入门

60 秒完成 MCP 连接器配置。

## 安装

```powershell
git clone https://github.com/laubeing-droid/Codex-Claude-legal-CN-mcp-connectors.git
cd Codex-Claude-legal-CN-mcp-connectors
.\install.ps1
```

```bash
# macOS/Linux
git clone https://github.com/laubeing-droid/Codex-Claude-legal-CN-mcp-connectors.git
cd Codex-Claude-legal-CN-mcp-connectors
chmod +x install.sh && ./install.sh
```

## 安装流程

安装脚本会引导你完成 5 步：
1. **环境检测** — 自动发现本机 MCP 客户端
2. **前置检查** — 检测 Node.js（chineselaw 依赖）
3. **chineselaw 配置** — 输入 API Key（可留空）
4. **北大法宝配置** — 输入 Access Token，选择服务
5. **完成** — 配置已写入所有检测到的客户端

## 验证

```powershell
.\verify.ps1
```

## 完整技能包

本仓库通常与 [Claude-for-Legal-CN-to-Codex](https://github.com/laubeing-droid/Claude-for-Legal-CN-to-Codex) 配合使用，后者提供 13 个法律技能入口和自动更新机制。