# 企业微信机器狗控制系统 - 一键部署

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

通过企业微信实时控制 Unitree Go2 机器狗的完整部署方案。基于 OpenClaw 框架 + 企业微信集成。

## ✨ 特性

- 🤖 **完整机器人控制** - 状态查询、拍照、动作、移动、转向
- 💬 **企业微信实时控制** - 发送消息即可控制，延迟 <3 秒
- 🚀 **一键部署** - 单个脚本完成所有安装和配置
- 📦 **完全自包含** - 无需额外下载其他文件
- 🔒 **自动服务化** - systemd 守护进程，开机自启
- 📝 **详细文档** - 包含故障排查和进阶配置

## 🎯 快速开始

### 一行命令部署

```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/openclaw-wecom-robot-deployment/main/deploy-openclaw-wecom-robot.sh && bash deploy-openclaw-wecom-robot.sh
```

### 或者分步骤

```bash
# 1. 下载脚本
wget https://raw.githubusercontent.com/YOUR_USERNAME/openclaw-wecom-robot-deployment/main/deploy-openclaw-wecom-robot.sh

# 2. 赋予执行权限
chmod +x deploy-openclaw-wecom-robot.sh

# 3. 运行部署
bash deploy-openclaw-wecom-robot.sh
```

## 📋 系统要求

- **操作系统**: Ubuntu 20.04+ 或 Debian 11+
- **架构**: x86_64 或 ARM64
- **内存**: 最低 2GB RAM
- **磁盘**: 最低 10GB 可用空间
- **权限**: 需要 sudo 权限
- **网络**: 需要访问外网

## 🔑 准备工作

部署前请准备以下信息：

### 1. AI API 凭据（必需）
- [ ] **Anthropic API Key** (推荐)
  - 或 OpenAI API Key
  - 或 AWS Bedrock 配置
- 获取地址: https://console.anthropic.com/

### 2. 企业微信配置（必需）
- [ ] Corp ID
- [ ] Corp Secret
- [ ] Agent ID
- [ ] 回调 Token
- [ ] EncodingAESKey

获取方式：
1. 登录 [企业微信管理后台](https://work.weixin.qq.com/)
2. 进入 "应用管理" → "自建应用"
3. 创建应用并记录上述信息

### 3. 机器人 API 凭据（必需）
- [ ] Robot API Base URL
- [ ] Robot Username
- [ ] Robot Password Hash

### 4. 服务器配置（必需）
- [ ] 服务器公网 IP 地址
- [ ] 开放端口 8080（用于企业微信回调）

## 🚀 部署流程

脚本会自动完成以下步骤：

1. ✅ 检查系统环境
2. ✅ 安装系统依赖（Python, Node.js, ffmpeg, git）
3. ✅ 安装 OpenClaw
4. ✅ 配置 OpenClaw（AI API）
5. ✅ 安装机器人控制框架
6. ✅ 配置企业微信机器人
7. ✅ 创建 systemd 服务
8. ✅ 启动所有服务

**预计时间**: 5-10 分钟

## 🤖 机器人功能

部署完成后，可以通过企业微信控制机器狗：

### 基础命令
```
你好              # 打招呼
机器狗状态        # 查看状态
拍照              # 拍摄照片
```

### 动作控制
```
站高              # 站立
趴下              # 趴下
坐下              # 坐下
打招呼            # 挥手
伸懒腰            # 伸展
舞蹈1 / 舞蹈2     # 跳舞
```

### 移动控制
```
前进2米           # 前进指定距离
后退1米           # 后退指定距离
右转90度          # 右转指定角度
左转180度         # 左转指定角度
```

## 📖 详细文档

- [**快速开始指南**](QUICK_START.md) - 3 分钟快速上手
- [**完整部署文档**](DEPLOYMENT_README.md) - 详细说明和故障排查

## 🛠️ 服务管理

### OpenClaw Gateway
```bash
openclaw gateway start    # 启动
openclaw gateway stop     # 停止
openclaw gateway status   # 状态
```

### WeCom Bot
```bash
sudo systemctl start wecom-bot.service     # 启动
sudo systemctl stop wecom-bot.service      # 停止
sudo systemctl status wecom-bot.service    # 状态
sudo journalctl -u wecom-bot.service -f    # 查看日志
```

## 📁 目录结构

```
~/.openclaw/
├── config.json                    # OpenClaw 配置
├── workspace/
│   ├── wecom-bot/                # WeCom 机器人
│   │   ├── venv/                 # Python 虚拟环境
│   │   ├── .env                  # WeCom 凭据
│   │   ├── app_instant_real.py   # Flask 服务
│   │   └── instant_processor.py  # 消息处理器
│   ├── roboagent-repo/           # 机器人代理
│   │   └── .env                  # 机器人 API 凭据
│   └── robot-snapshots/          # 机器狗照片存储
└── memory/                        # 记忆文件
```

## 🔧 故障排查

### 企业微信回调验证失败
```bash
# 检查服务状态
sudo systemctl status wecom-bot.service

# 检查端口监听
sudo netstat -tlnp | grep 8080

# 查看日志
sudo journalctl -u wecom-bot.service -f
```

### 机器人无响应
```bash
# 查看实时日志
sudo journalctl -u wecom-bot.service -f

# 检查 OpenClaw
openclaw gateway status
```

更多故障排查方案请查看 [完整文档](DEPLOYMENT_README.md)。

## 🔒 安全建议

1. ⚠️ 不要在公开仓库中提交 `.env` 文件
2. 🔑 定期轮换 API 密钥
3. 🔐 使用 HTTPS（通过 nginx 反向代理）
4. 🚫 限制服务器访问 IP
5. 🔄 定期更新系统和依赖包

## 🌟 支持的机器人

- Unitree Go2_021
- Unitree Go2_001

## 📦 依赖项

脚本会自动安装：
- OpenClaw (最新版)
- Python 3 + pip + venv
- Node.js (LTS)
- ffmpeg
- git, curl, jq

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 🔗 相关链接

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Discord 社区](https://discord.com/invite/clawd)
- [技能市场](https://clawhub.com)

## ⚡ 性能

- 部署时间: ~5-10 分钟
- 内存占用: ~200MB (运行时)
- 响应延迟: <3 秒（企业微信消息）

## 📸 演示

部署完成后，在企业微信中发送：
```
拍照
```

机器狗会立即返回当前摄像头画面！

---

**Made with ❤️ by OpenClaw Community**

如有问题，请提交 Issue 或加入 Discord 社区讨论。
