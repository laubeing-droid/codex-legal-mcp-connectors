# 更新日志

## [1.2.0] - 2026-05-23

### 泛化为多环境通用安装
- detect.ps1 / detect.sh: 新增环境检测模块，自动发现 Codex Desktop / Claude Code / Claude Desktop
- install.ps1: 全环境写入（适配 TOML + JSON 双格式）
- install.sh: 同步支持多环境安装
- verify.ps1: 全环境检查（TOML 和 JSON 双格式）
- verify.sh: 同步支持多环境验证
- update.ps1: 全环境诊断 + Token 过期检测
- update.sh: 同步支持多环境更新

### 完善配套设施
- QUICKSTART.md: 60 秒快速入门
- .gitattributes: Git 行尾配置（PS1/MD/Shell 统一 LF）
- uninstall.ps1 / uninstall.sh: 全环境卸载脚本（从 TOML/JSON 配置中移除连接器）
- docs/architecture.md: 架构说明、数据流、依赖关系
- docs/contributing.md: 贡献指南、编码规范、版本号规则
- docs/troubleshooting.md: 常见问题排查（安装/配置/多环境/网络）
- docs/usage-guide.md: 完整使用指南（含连接器详解、调试方法）
- docs/connectors.md: 增加配套文档交叉引用
- README.md: 更新完整文件清单和环境支持表
- .github/workflows/npm-monitor.yml: 优化版本检测流程

## [1.1.0] - 2026-05-23

### 改进
- install.ps1: 交互式输入 API Key / Access Token，替代硬编码占位符
- install.ps1: 添加 Node.js 前置检测
- install.ps1: 支持选择要安装的北大法宝服务（多选）
- install.ps1: 添加 Read-Host 交互提示

### 新增
- update.ps1: 新脚本，包含自更新 + npm 版本检查 + 全部 MCP 配置状态检查 + Token 过期检测 + @pkulaw/mcp-cli 验证
- install.sh: 新增 macOS/Linux 支持（Bash）
- verify.sh: 新增 macOS/Linux 验证脚本
- update.sh: 新增 macOS/Linux 更新脚本

### 增强
- verify.ps1: 改为动态发现所有 [mcp_servers.*] 配置段，检查全部服务
- verify.ps1: 新增 Token / API Key 占位符检测
- verify.ps1: 新增 npm 包版本检查
- verify.ps1: 新增 @pkulaw/mcp-cli 检测
- README.md: 更新文件清单，新增多平台支持说明

## [1.0.0] - 2026-05-23

### 新增
- 初始版本：install.ps1, verify.ps1, README.md, docs/connectors.md, npm-monitor.yml
- 支持 chineselaw（元典智库）+ 北大法宝 MCP 协议 + @pkulaw/mcp-cli

