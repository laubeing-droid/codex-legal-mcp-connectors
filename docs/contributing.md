# 贡献指南

## 仓库结构

```
Codex-Claude-legal-CN-mcp-connectors/
  detect.ps1 / detect.sh        环境检测模块
  install.ps1 / install.sh      安装脚本
  verify.ps1 / verify.sh        验证脚本
  update.ps1 / update.sh        更新诊断脚本
  uninstall.ps1 / uninstall.sh  卸载脚本
  docs/                         文档
  .github/workflows/            GitHub Actions
```

## 双平台维护

Windows（PowerShell `.ps1`）和 macOS/Linux（Bash `.sh`）脚本需保持功能对等。
修改脚本时必须同步更新两个平台版本。

### 关键差异点

| 项 | Windows (PowerShell) | macOS/Linux (Bash) |
|----|---------------------|---------------------|
| JSON 解析 | ConvertFrom-Json | jq |
| TOML 解析 | 正则匹配 | 正则匹配 |
| 配置文件路径 | `%LOCALAPPDATA%` | `~/Library/Application Support` |

## 修改指南

### 添加新连接器
1. 在 `install.ps1` / `install.sh` 中添加连接器配置块
2. 在 `verify.ps1` / `verify.sh` 中添加对该连接器的检查
3. 更新 docs/connectors.md 中的服务列表

### 修改北大法宝服务列表
服务声明数组位于 `install.ps1` 的 `$allPkulawServices` 和 `install.sh` 的 `ALL_PKULAW_SERVICES`。
来源应与 `@pkulaw/mcp-cli` npm 包的 `dist/config/servers.json` 保持一致。

### 添加新 MCP 客户端支持
1. 在 detect.ps1 / detect.sh 的 Get-EnvironmentInfo 中新增检测
2. 确认该客户端的配置路径和格式
3. 在 install/verify/update/uninstall 脚本中适配格式
4. 更新文档

## 测试流程

```powershell
.\install.ps1           # 输入测试用 Token
.\verify.ps1            # 确认配置正确写入
.\update.ps1            # 确认自更新和诊断正常
.\uninstall.ps1         # 确认清理干净
```

推荐在 Windows + macOS/Linux 双平台测试。