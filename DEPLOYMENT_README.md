# OpenClaw + WeCom + Robot Control - 完整部署指南

## 概述

这是一个一键部署脚本，用于在全新的 Ubuntu/Debian 服务器上部署：
- OpenClaw Gateway（AI 助手框架）
- 企业微信（WeCom）机器人集成
- Unitree Go2 机器狗控制系统

## 系统要求

- **操作系统**: Ubuntu 20.04+ 或 Debian 11+
- **架构**: x86_64 或 ARM64
- **内存**: 最低 2GB RAM
- **磁盘**: 最低 10GB 可用空间
- **网络**: 需要访问外网（安装依赖）
- **权限**: 需要 sudo 权限

## 快速开始

### 1. 下载脚本

```bash
cd ~
wget https://your-server/deploy-openclaw-wecom-robot.sh
# 或者从现有服务器复制
scp user@server:~/.openclaw/workspace/deploy-openclaw-wecom-robot.sh .
```

### 2. 赋予执行权限

```bash
chmod +x deploy-openclaw-wecom-robot.sh
```

### 3. 运行部署脚本

```bash
bash deploy-openclaw-wecom-robot.sh
```

脚本会交互式地询问所需的配置信息。

## 部署流程详解

### 步骤 1: 检查系统环境
- 验证操作系统
- 检查 sudo 权限
- 确认网络连接

### 步骤 2: 安装系统依赖
自动安装：
- Python 3 + pip + venv
- Node.js (LTS版本)
- ffmpeg (视频处理)
- git, curl, jq (工具)

### 步骤 3: 安装 OpenClaw
- 通过 npm 全局安装 OpenClaw
- 版本: 最新稳定版

### 步骤 4: 配置 OpenClaw
需要提供：
- **API Provider**: anthropic/openai/bedrock
- **API Key**: 对应的 API 密钥
- **WhatsApp**: 可选配置

### 步骤 5: 配置机器人 API
需要提供：
- **API Base URL**: 机器人 API 地址（默认: https://api.rodimus.cloud/api/v1）
- **Username**: 机器人用户名
- **Password Hash**: 机器人密码哈希

### 步骤 6: 配置企业微信
需要提供：
- **Corp ID**: 企业微信企业 ID
- **Corp Secret**: 企业应用 Secret
- **Agent ID**: 应用的 Agent ID
- **Token**: 回调验证 Token
- **EncodingAESKey**: 消息加密密钥

### 步骤 7: 创建 systemd 服务
自动创建并启用：
- `wecom-bot.service` - 企业微信机器人服务

### 步骤 8: 启动服务
- 启动 OpenClaw Gateway
- 启动 WeCom Bot 服务

## 准备工作清单

部署前请准备以下信息：

### 1. AI API 凭据
- [ ] Anthropic API Key (推荐)
  - 或 OpenAI API Key
  - 或 AWS Bedrock 配置

### 2. 企业微信配置
- [ ] Corp ID
- [ ] Corp Secret
- [ ] Agent ID
- [ ] 回调 Token
- [ ] EncodingAESKey

获取方式：
1. 登录 [企业微信管理后台](https://work.weixin.qq.com/wework_admin/frame)
2. 进入 "应用管理" → "自建应用"
3. 创建应用并记录上述信息
4. 在应用设置中配置回调 URL: `http://YOUR_SERVER_IP:8080/wecom`

### 3. 机器人 API 凭据
- [ ] Robot API Base URL
- [ ] Robot Username
- [ ] Robot Password Hash

### 4. 服务器信息
- [ ] 服务器公网 IP 地址
- [ ] 开放端口 8080（用于企业微信回调）

## 部署后配置

### 1. 配置企业微信回调 URL

在企业微信应用设置中：
1. 进入 "接收消息" 设置
2. URL 填写: `http://YOUR_SERVER_IP:8080/wecom`
3. Token: 使用部署时填写的 Token
4. EncodingAESKey: 使用部署时填写的 Key
5. 点击 "保存" 并验证

### 2. 测试机器人功能

在企业微信中发送消息给应用：

```
# 基础测试
你好

# 机器狗状态
机器狗状态

# 拍照
拍照

# 动作控制
站高
趴下
打招呼
舞蹈1

# 移动控制
前进2米
右转90度
后退1米
```

### 3. 查看日志

```bash
# OpenClaw 日志
openclaw logs

# WeCom Bot 日志
sudo journalctl -u wecom-bot.service -f

# 实时监控
sudo systemctl status wecom-bot.service
```

## 服务管理

### OpenClaw Gateway

```bash
# 启动
openclaw gateway start

# 停止
openclaw gateway stop

# 重启
openclaw gateway restart

# 状态
openclaw gateway status
```

### WeCom Bot

```bash
# 启动
sudo systemctl start wecom-bot.service

# 停止
sudo systemctl stop wecom-bot.service

# 重启
sudo systemctl restart wecom-bot.service

# 状态
sudo systemctl status wecom-bot.service

# 查看日志
sudo journalctl -u wecom-bot.service -f
```

## 目录结构

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

## 故障排查

### 1. WeCom 回调验证失败

**症状**: 企业微信回调 URL 验证失败

**检查**:
```bash
# 确认服务运行
sudo systemctl status wecom-bot.service

# 检查端口监听
sudo netstat -tlnp | grep 8080

# 测试本地访问
curl http://localhost:8080/wecom
```

**解决**:
- 确认服务器防火墙开放 8080 端口
- 确认云服务商安全组开放 8080 端口
- 检查 Token 和 EncodingAESKey 是否正确

### 2. 机器人无响应

**症状**: 发送消息后没有回复

**检查**:
```bash
# 查看实时日志
sudo journalctl -u wecom-bot.service -f
```

**解决**:
- 检查 instant_processor.py 是否存在
- 确认 Robot API 凭据正确
- 验证 OpenClaw 运行正常

### 3. 拍照失败

**症状**: 执行拍照命令报错

**检查**:
```bash
# 确认 ffmpeg 安装
ffmpeg -version

# 测试 Robot API 连接
cd ~/.openclaw/workspace/roboagent-repo
source venv/bin/activate
python3 -c "from roboagent.robot_client import RobotAPIClient; print('OK')"
```

### 4. Python 依赖问题

**症状**: ModuleNotFoundError

**解决**:
```bash
cd ~/.openclaw/workspace/wecom-bot
source venv/bin/activate
pip install flask requests python-dotenv WeChatPy cryptography httpx pillow
```

## 更新和维护

### 更新 OpenClaw

```bash
sudo npm update -g openclaw
openclaw gateway restart
```

### 更新 Robot Agent

```bash
cd ~/.openclaw/workspace/roboagent-repo
git pull origin main
```

### 备份配置

```bash
# 备份所有配置
tar -czf openclaw-backup-$(date +%Y%m%d).tar.gz \
  ~/.openclaw/config.json \
  ~/.openclaw/workspace/wecom-bot/.env \
  ~/.openclaw/workspace/roboagent-repo/.env
```

## 安全建议

1. **不要在公开仓库中提交 .env 文件**
2. **定期轮换 API 密钥**
3. **使用 HTTPS（通过 nginx 反向代理）**
4. **限制服务器访问 IP**
5. **定期更新系统和依赖包**

## 高级配置

### 使用 nginx 反向代理（推荐）

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location /wecom {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 添加更多机器人命令

编辑 `~/.openclaw/workspace/wecom-bot/instant_processor.py`:

```python
# 在 process_wecom_message() 函数中添加新的命令处理逻辑
if "你的命令" in message:
    return "你的响应"
```

## 支持与反馈

- GitHub Issues: https://github.com/openclaw/openclaw/issues
- Discord 社区: https://discord.com/invite/clawd
- 文档: https://docs.openclaw.ai

## 许可证

本部署脚本基于 MIT 许可证开源。
