# 常见问题排查

## 连接器不生效？
1. 确认 config.toml 中 `enabled = true` 存在
2. 运行 `.\verify.ps1` 检查状态
3. 确认已重启 Codex Desktop
4. 运行 `.\update.ps1` 获取完整诊断

## chineselaw 不工作？
- `node --version` 确认 >= 18
- 从 https://nodejs.org 下载 LTS 版本
- 运行 `.\update.ps1` 检查 npm 包版本
- 确认 `CHINESELAW_API_KEY` 已替换为真实 Key

## Token 无效或过期？
- 运行 `.\update.ps1` 自动检测占位符
- 安装 `pkulaw-mcp-cli` 后验证 Token 有效性
- 登录 https://mcp.pkulaw.com 重新生成 Token

## 配置文件损坏？
- 重新运行 `.\install.ps1`（只添加不覆盖）
- 或手动编辑 `~/.codex/config.toml`

## 无连接器也能用吗？
可以。技能仍可用，但法规引用将标注 `[需验证]`，不保证现行有效性。

## 跨平台问题

| 问题 | Windows | macOS/Linux |
|------|---------|-------------|
| 运行脚本 | `.\install.ps1` | `chmod +x install.sh && ./install.sh` |
| 执行策略 | 需设置 RemoteSigned | 需设置可执行权限 |
| 配置路径 | `%USERPROFILE%` | `$HOME` |