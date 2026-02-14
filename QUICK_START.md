# 快速开始 - 一键部署

## 最简单的方式（只需一个文件！）

```bash
# 1. 复制脚本到新服务器
scp deploy-openclaw-wecom-robot.sh user@new-server:~

# 2. SSH 到新服务器
ssh user@new-server

# 3. 运行（就这么简单！）
bash deploy-openclaw-wecom-robot.sh
```

**✨ 完全自给自足**：这个脚本包含所有需要的代码，无需其他文件！

## 需要准备的信息

### 必需
1. **Anthropic API Key** (推荐)
   - 注册: https://console.anthropic.com/
   - 获取 API key

2. **企业微信配置** (5项)
   - Corp ID
   - Corp Secret
   - Agent ID
   - Token
   - EncodingAESKey
   
   获取: https://work.weixin.qq.com/wework_admin/frame → 应用管理 → 自建应用

3. **机器人 API** (3项)
   - API Base URL: https://api.rodimus.cloud/api/v1
   - Username
   - Password Hash

4. **服务器公网 IP**
   - 用于配置企业微信回调

### 可选
- WhatsApp 配置（扫码链接）

## 部署流程

脚本会自动：
1. ✓ 安装系统依赖（Python, Node.js, ffmpeg, git）
2. ✓ 安装 OpenClaw
3. ✓ 配置 OpenClaw（AI API）
4. ✓ 安装机器人控制框架
5. ✓ 配置企业微信机器人
6. ✓ 创建 systemd 服务
7. ✓ 启动所有服务

预计时间：**5-10 分钟**

## 部署后

### 1. 配置企业微信回调
在企业微信应用设置中：
- URL: `http://YOUR_IP:8080/wecom`
- 使用部署时填写的 Token 和 Key

### 2. 测试
在企业微信中发消息：
```
你好
机器狗状态
拍照
站高
右转90度
```

### 3. 查看日志
```bash
# WeCom Bot 日志
sudo journalctl -u wecom-bot.service -f

# OpenClaw 日志
openclaw logs
```

## 管理命令

```bash
# 启动/停止 WeCom Bot
sudo systemctl start wecom-bot.service
sudo systemctl stop wecom-bot.service

# 启动/停止 OpenClaw
openclaw gateway start
openclaw gateway stop
```

## 需要帮助？

详细文档: [DEPLOYMENT_README.md](./DEPLOYMENT_README.md)

---

**提示**: 首次部署建议先在测试环境运行，熟悉流程后再部署到生产环境。
