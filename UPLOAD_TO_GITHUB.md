# 如何上传到 GitHub

## 方式 1: 通过 GitHub 网页（最简单）

### 步骤：

1. **登录 GitHub**
   - 访问 https://github.com
   - 登录你的账号

2. **创建新仓库**
   - 点击右上角 "+" → "New repository"
   - Repository name: `openclaw-wecom-robot-deployment`
   - Description: `一键部署 OpenClaw + 企业微信 + 机器狗控制系统`
   - 选择 Public（公开）
   - **不要** 勾选 "Add a README file"（我们已经有了）
   - 点击 "Create repository"

3. **上传文件**
   - 在新仓库页面，点击 "uploading an existing file"
   - 将以下文件拖拽到浏览器：
     * `deploy-openclaw-wecom-robot.sh`
     * `README.md`
     * `DEPLOYMENT_README.md`
     * `QUICK_START.md`
     * `LICENSE`
     * `.gitignore`
   - 添加 commit 信息: "Initial commit: Complete deployment solution"
   - 点击 "Commit changes"

4. **完成！**
   - 你的仓库链接: `https://github.com/YOUR_USERNAME/openclaw-wecom-robot-deployment`
   - 别人可以通过以下命令使用:
   ```bash
   wget https://raw.githubusercontent.com/YOUR_USERNAME/openclaw-wecom-robot-deployment/main/deploy-openclaw-wecom-robot.sh
   bash deploy-openclaw-wecom-robot.sh
   ```

---

## 方式 2: 通过命令行（适合技术用户）

### 步骤：

1. **配置 Git（首次使用）**
   ```bash
   git config --global user.name "你的名字"
   git config --global user.email "your.email@example.com"
   ```

2. **在 GitHub 创建新仓库**
   - 访问 https://github.com/new
   - Repository name: `openclaw-wecom-robot-deployment`
   - 选择 Public
   - **不要** 添加 README、.gitignore 或 license（我们已经有了）
   - 点击 "Create repository"

3. **初始化并推送**
   ```bash
   cd ~/.openclaw/workspace/openclaw-wecom-robot-deployment
   
   # 初始化 Git
   git init
   
   # 添加所有文件
   git add .
   
   # 提交
   git commit -m "Initial commit: Complete deployment solution"
   
   # 关联远程仓库（替换 YOUR_USERNAME）
   git remote add origin https://github.com/YOUR_USERNAME/openclaw-wecom-robot-deployment.git
   
   # 推送到 GitHub
   git branch -M main
   git push -u origin main
   ```

4. **输入 GitHub 凭据**
   - Username: 你的 GitHub 用户名
   - Password: 使用 Personal Access Token（不是密码！）
   
   **如何获取 Personal Access Token:**
   - 访问 https://github.com/settings/tokens
   - 点击 "Generate new token" → "Generate new token (classic)"
   - 勾选 `repo` 权限
   - 点击 "Generate token"
   - 复制 token（只显示一次！）
   - 在推送时使用这个 token 作为密码

---

## 验证上传成功

访问你的仓库: `https://github.com/YOUR_USERNAME/openclaw-wecom-robot-deployment`

你应该看到：
- ✅ README.md 显示在首页
- ✅ 6 个文件（包括 deploy 脚本）
- ✅ MIT License
- ✅ .gitignore

---

## 分享给别人

**一行命令部署:**
```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/openclaw-wecom-robot-deployment/main/deploy-openclaw-wecom-robot.sh && bash deploy-openclaw-wecom-robot.sh
```

**或者发送仓库链接:**
```
https://github.com/YOUR_USERNAME/openclaw-wecom-robot-deployment
```

别人可以查看 README 了解如何使用。

---

## 🎉 完成！

现在任何人都可以通过你的 GitHub 仓库一键部署整个系统了！

需要帮助？提交 Issue 到你的仓库或联系我。
