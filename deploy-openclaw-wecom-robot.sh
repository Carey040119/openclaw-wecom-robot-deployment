#!/usr/bin/env bash
# OpenClaw + WeCom + Robot Control - Complete Deployment Script
# Usage: sudo bash deploy-openclaw-wecom-robot.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${HOME}/.openclaw/workspace"
WECOM_BOT_DIR="${WORKSPACE_DIR}/wecom-bot"
ROBOT_REPO_DIR="${WORKSPACE_DIR}/roboagent-repo"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

prompt_input() {
    local var_name=$1
    local prompt_text=$2
    local default_value=$3
    
    if [ -n "$default_value" ]; then
        read -p "$prompt_text [$default_value]: " value
        value=${value:-$default_value}
    else
        read -p "$prompt_text: " value
    fi
    
    eval "$var_name='$value'"
}

prompt_secret() {
    local var_name=$1
    local prompt_text=$2
    
    read -sp "$prompt_text: " value
    echo
    eval "$var_name='$value'"
}

# ============================================
# 1. Check Prerequisites
# ============================================
check_prerequisites() {
    log_info "检查系统依赖..."
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        log_error "请不要以 root 用户运行此脚本"
        log_info "使用: bash $0"
        exit 1
    fi
    
    # Check OS
    if [ ! -f /etc/os-release ]; then
        log_error "无法检测操作系统"
        exit 1
    fi
    
    . /etc/os-release
    if [ "$ID" != "ubuntu" ] && [ "$ID" != "debian" ]; then
        log_warn "此脚本针对 Ubuntu/Debian 优化，其他系统可能需要调整"
    fi
    
    log_info "✓ 系统检查通过"
}

# ============================================
# 2. Install OpenClaw
# ============================================
install_openclaw() {
    log_info "安装 OpenClaw..."
    
    if command -v openclaw &> /dev/null; then
        log_info "OpenClaw 已安装，检查版本..."
        openclaw --version
        
        prompt_input "REINSTALL_OPENCLAW" "是否重新安装 OpenClaw? (y/n)" "n"
        if [ "$REINSTALL_OPENCLAW" != "y" ]; then
            return 0
        fi
    fi
    
    # Install Node.js if needed
    if ! command -v node &> /dev/null; then
        log_info "安装 Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    # Install OpenClaw
    log_info "通过 npm 安装 OpenClaw..."
    sudo npm install -g openclaw
    
    log_info "✓ OpenClaw 安装完成"
}

# ============================================
# 3. Configure OpenClaw
# ============================================
configure_openclaw() {
    log_info "配置 OpenClaw..."
    
    mkdir -p "${HOME}/.openclaw/workspace"
    cd "${HOME}/.openclaw"
    
    # Check if already configured
    if [ -f "${HOME}/.openclaw/config.json" ]; then
        log_info "发现现有配置文件"
        prompt_input "RECONFIG_OPENCLAW" "是否重新配置? (y/n)" "n"
        if [ "$RECONFIG_OPENCLAW" != "y" ]; then
            return 0
        fi
    fi
    
    log_info "收集配置信息..."
    
    # API Provider
    prompt_input "API_PROVIDER" "选择 API 提供商 (anthropic/openai/bedrock)" "anthropic"
    
    if [ "$API_PROVIDER" == "anthropic" ]; then
        prompt_secret "ANTHROPIC_API_KEY" "输入 Anthropic API Key"
        export ANTHROPIC_API_KEY
    elif [ "$API_PROVIDER" == "openai" ]; then
        prompt_secret "OPENAI_API_KEY" "输入 OpenAI API Key"
        export OPENAI_API_KEY
    fi
    
    # Create basic config
    log_info "生成配置文件..."
    
    cat > "${HOME}/.openclaw/config.json" << EOF
{
  "agent": {
    "id": "main",
    "model": "anthropic/claude-sonnet-4-5"
  },
  "channels": {}
}
EOF
    
    log_info "✓ OpenClaw 配置完成"
}

# ============================================
# 4. Install System Dependencies
# ============================================
install_system_deps() {
    log_info "安装系统依赖..."
    
    sudo apt-get update
    sudo apt-get install -y \
        python3 \
        python3-pip \
        python3-venv \
        ffmpeg \
        git \
        curl \
        jq
    
    log_info "✓ 系统依赖安装完成"
}

# ============================================
# 5. Setup Robot Agent Repository
# ============================================
setup_robot_repo() {
    log_info "设置机器人代理仓库..."
    
    mkdir -p "$WORKSPACE_DIR"
    cd "$WORKSPACE_DIR"
    
    if [ -d "$ROBOT_REPO_DIR" ]; then
        log_info "机器人仓库已存在"
        prompt_input "UPDATE_ROBOT_REPO" "是否更新? (y/n)" "n"
        if [ "$UPDATE_ROBOT_REPO" == "y" ]; then
            cd "$ROBOT_REPO_DIR"
            git pull
        fi
    else
        log_info "克隆机器人仓库..."
        git clone https://github.com/yoctta/roboagent.git "$ROBOT_REPO_DIR"
    fi
    
    # Configure robot API credentials
    log_info "配置机器人 API 凭据..."
    
    prompt_input "ROBOT_API_BASE_URL" "机器人 API 地址" "https://api.rodimus.cloud/api/v1"
    prompt_input "ROBOT_USERNAME" "机器人用户名" ""
    prompt_secret "ROBOT_PASSWORD_HASH" "机器人密码哈希"
    
    cat > "$ROBOT_REPO_DIR/.env" << EOF
ROBOT_API_BASE_URL=$ROBOT_API_BASE_URL
ROBOT_USERNAME=$ROBOT_USERNAME
ROBOT_PASSWORD_HASH=$ROBOT_PASSWORD_HASH
EOF
    
    log_info "✓ 机器人仓库配置完成"
}

# ============================================
# 6. Setup WeCom Bot
# ============================================
setup_wecom_bot() {
    log_info "设置企业微信机器人..."
    
    mkdir -p "$WECOM_BOT_DIR"
    cd "$WECOM_BOT_DIR"
    
    # Create Python virtual environment
    if [ ! -d "venv" ]; then
        log_info "创建 Python 虚拟环境..."
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    # Install dependencies
    log_info "安装 Python 依赖..."
    pip install --upgrade pip
    pip install flask requests python-dotenv WeChatPy cryptography
    
    # Install roboagent dependencies
    cd "$ROBOT_REPO_DIR"
    pip install httpx python-dotenv pillow
    
    # Get WeCom credentials
    log_info "配置企业微信凭据..."
    
    prompt_input "WECOM_CORP_ID" "企业微信 Corp ID" ""
    prompt_secret "WECOM_CORP_SECRET" "企业微信 Corp Secret"
    prompt_input "WECOM_AGENT_ID" "企业微信 Agent ID" ""
    prompt_secret "WECOM_TOKEN" "企业微信回调 Token"
    prompt_secret "WECOM_ENCODING_AES_KEY" "企业微信 EncodingAESKey"
    
    # Create WeCom bot .env
    cat > "$WECOM_BOT_DIR/.env" << EOF
WECOM_CORP_ID=$WECOM_CORP_ID
WECOM_CORP_SECRET=$WECOM_CORP_SECRET
WECOM_AGENT_ID=$WECOM_AGENT_ID
WECOM_TOKEN=$WECOM_TOKEN
WECOM_ENCODING_AES_KEY=$WECOM_ENCODING_AES_KEY
EOF
    
    # Copy bot files
    log_info "创建 WeCom 机器人文件..."
    
    # Create app_instant_real.py
    cat > "$WECOM_BOT_DIR/app_instant_real.py" << 'PYEOF'
#!/usr/bin/env python3
"""WeCom Bot - Real-time message processor with instant replies."""
from flask import Flask, request
import json
import hashlib
import subprocess
import sys
from pathlib import Path
from WXBizMsgCrypt3 import WXBizMsgCrypt
import xml.etree.ElementTree as ET
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

app = Flask(__name__)

# WeCom credentials
CORP_ID = os.getenv("WECOM_CORP_ID")
TOKEN = os.getenv("WECOM_TOKEN")
ENCODING_AES_KEY = os.getenv("WECOM_ENCODING_AES_KEY")
CORP_SECRET = os.getenv("WECOM_CORP_SECRET")
AGENT_ID = os.getenv("WECOM_AGENT_ID")

# Initialize crypto
wxcpt = WXBizMsgCrypt(TOKEN, ENCODING_AES_KEY, CORP_ID)

def get_access_token():
    """Get WeCom access token."""
    import requests
    url = f"https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid={CORP_ID}&corpsecret={CORP_SECRET}"
    resp = requests.get(url)
    data = resp.json()
    return data.get("access_token")

def send_text_message(user_id, content):
    """Send text message via WeCom API."""
    import requests
    token = get_access_token()
    url = f"https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token={token}"
    
    payload = {
        "touser": user_id,
        "msgtype": "text",
        "agentid": int(AGENT_ID),
        "text": {"content": content}
    }
    
    resp = requests.post(url, json=payload)
    return resp.json()

def upload_media(file_path, media_type="image"):
    """Upload media to WeCom and get media_id."""
    import requests
    token = get_access_token()
    url = f"https://qyapi.weixin.qq.com/cgi-bin/media/upload?access_token={token}&type={media_type}"
    
    with open(file_path, 'rb') as f:
        files = {'media': f}
        resp = requests.post(url, files=files)
    
    data = resp.json()
    return data.get("media_id")

def send_image_message(user_id, media_id):
    """Send image message via WeCom API."""
    import requests
    token = get_access_token()
    url = f"https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token={token}"
    
    payload = {
        "touser": user_id,
        "msgtype": "image",
        "agentid": int(AGENT_ID),
        "image": {"media_id": media_id}
    }
    
    resp = requests.post(url, json=payload)
    return resp.json()

@app.route('/wecom', methods=['GET', 'POST'])
def wecom_callback():
    if request.method == 'GET':
        # Verification
        msg_signature = request.args.get('msg_signature')
        timestamp = request.args.get('timestamp')
        nonce = request.args.get('nonce')
        echostr = request.args.get('echostr')
        
        ret, sEchoStr = wxcpt.VerifyURL(msg_signature, timestamp, nonce, echostr)
        if ret == 0:
            return sEchoStr
        return "Verification failed", 403
    
    elif request.method == 'POST':
        # Message callback
        msg_signature = request.args.get('msg_signature')
        timestamp = request.args.get('timestamp')
        nonce = request.args.get('nonce')
        
        # Decrypt message
        ret, xml_content = wxcpt.DecryptMsg(request.data, msg_signature, timestamp, nonce)
        
        if ret != 0:
            return "Decrypt failed", 400
        
        # Parse XML
        root = ET.fromstring(xml_content)
        msg_type = root.find('MsgType').text
        from_user = root.find('FromUserName').text
        
        if msg_type == 'text':
            content = root.find('Content').text
            
            # Process with instant_processor.py
            try:
                proc_input = json.dumps({"user_id": from_user, "message": content})
                result = subprocess.run(
                    [sys.executable, "instant_processor.py"],
                    input=proc_input,
                    capture_output=True,
                    text=True,
                    timeout=60,
                    cwd=Path(__file__).parent
                )
                
                if result.returncode == 0:
                    response_data = json.loads(result.stdout)
                    reply = response_data.get("reply")
                    
                    # Handle image response
                    if isinstance(reply, dict) and reply.get("type") == "image":
                        media_id = upload_media(reply["path"])
                        send_image_message(from_user, media_id)
                        if reply.get("caption"):
                            send_text_message(from_user, reply["caption"])
                    else:
                        send_text_message(from_user, reply)
                else:
                    send_text_message(from_user, f"❌ 处理失败: {result.stderr[:100]}")
            
            except Exception as e:
                send_text_message(from_user, f"❌ 错误: {str(e)[:100]}")
        
        return "success"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
PYEOF
    
    # Create instant_processor.py
    log_info "创建消息处理器 instant_processor.py..."
    
    cat > "$WECOM_BOT_DIR/instant_processor.py" << 'PYEOF'
#!/usr/bin/env python3
"""Process WeCom messages - intelligent dispatcher with direct execution."""
import sys
import json
import subprocess
import asyncio
import os
from pathlib import Path

# Add roboagent to path - use dynamic path
WORKSPACE_DIR = Path.home() / ".openclaw" / "workspace"
sys.path.insert(0, str(WORKSPACE_DIR / "roboagent-repo"))

def handle_robot_status():
    """Get robot status directly."""
    try:
        from dotenv import load_dotenv
        load_dotenv(WORKSPACE_DIR / "roboagent-repo" / ".env")
        
        from roboagent.robot_client import RobotAPIClient
        
        async def get_status():
            base_url = os.getenv("ROBOT_API_BASE_URL")
            username = os.getenv("ROBOT_USERNAME")
            password_hash = os.getenv("ROBOT_PASSWORD_HASH")
            
            client = RobotAPIClient(base_url=base_url, username=username, password_hash=password_hash)
            
            result = []
            for robot_id in ["Go2_021", "Go2_001"]:
                try:
                    status = await client.get_status(robot_id)
                    result.append(f"🐕 {robot_id}:")
                    result.append(f"  状态: {status.get('status', '未知')}")
                    result.append(f"  电量: {status['battery']['percentage']}%")
                    result.append(f"  位置: x={status['location']['x']}, y={status['location']['y']}")
                    result.append(f"  地图: {status['mapData']['mapDataName']}")
                except Exception as e:
                    result.append(f"❌ {robot_id}: {e}")
            
            return '\n'.join(result)
        
        return asyncio.run(get_status())
    except Exception as e:
        return f"❌ 获取状态失败: {str(e)[:200]}"

def handle_robot_snapshot(robot_id="Go2_021"):
    """Capture snapshot from robot camera."""
    try:
        from dotenv import load_dotenv
        load_dotenv(WORKSPACE_DIR / "roboagent-repo" / ".env")
        
        from roboagent.robot_client import RobotAPIClient
        from roboagent.vision import ffmpeg_snapshot_jpeg
        
        async def capture():
            base_url = os.getenv("ROBOT_API_BASE_URL")
            username = os.getenv("ROBOT_USERNAME")
            password_hash = os.getenv("ROBOT_PASSWORD_HASH")
            
            client = RobotAPIClient(base_url=base_url, username=username, password_hash=password_hash)
            
            # Get camera stream
            streams = await client.get_streams(robot_id)
            rtsp = streams.get("front_camera", {}).get("rtsp")
            
            if not rtsp:
                return None, f"❌ {robot_id} 无相机流"
            
            # Capture snapshot
            jpg_bytes = await ffmpeg_snapshot_jpeg(rtsp, timeout_s=10.0)
            
            # Save to output dir
            output_dir = WORKSPACE_DIR / "robot-snapshots"
            output_dir.mkdir(exist_ok=True)
            output_path = output_dir / f"{robot_id}_wecom.jpg"
            output_path.write_bytes(jpg_bytes)
            
            return str(output_path), f"📷 {robot_id} 拍照成功"
        
        return asyncio.run(capture())
    except Exception as e:
        return None, f"❌ 拍照失败: {str(e)[:200]}"

def handle_robot_action(action, robot_ids=None):
    """Execute robot action (stand, lie down, etc)."""
    try:
        from dotenv import load_dotenv
        load_dotenv(WORKSPACE_DIR / "roboagent-repo" / ".env")
        
        from roboagent.robot_client import RobotAPIClient
        
        if robot_ids is None:
            robot_ids = ["Go2_021", "Go2_001"]
        
        async def execute_action():
            base_url = os.getenv("ROBOT_API_BASE_URL")
            username = os.getenv("ROBOT_USERNAME")
            password_hash = os.getenv("ROBOT_PASSWORD_HASH")
            
            client = RobotAPIClient(base_url=base_url, username=username, password_hash=password_hash)
            
            result = []
            for robot_id in robot_ids:
                try:
                    resp = await client.action_do(robot_id, action=action)
                    result.append(f"✅ {robot_id}: {resp.get('action', action)}")
                except Exception as e:
                    result.append(f"❌ {robot_id}: {e}")
            
            return '\n'.join(result)
        
        return asyncio.run(execute_action())
    except Exception as e:
        return f"❌ 执行动作失败: {str(e)[:200]}"

def handle_robot_move(robot_id, distance_meters=2.0, direction="forward"):
    """Move robot by relative distance."""
    try:
        from dotenv import load_dotenv
        load_dotenv(WORKSPACE_DIR / "roboagent-repo" / ".env")
        
        from roboagent.robot_client import RobotAPIClient
        import math
        
        async def move():
            base_url = os.getenv("ROBOT_API_BASE_URL")
            username = os.getenv("ROBOT_USERNAME")
            password_hash = os.getenv("ROBOT_PASSWORD_HASH")
            
            client = RobotAPIClient(base_url=base_url, username=username, password_hash=password_hash)
            
            # Get current status
            status = await client.get_status(robot_id)
            current_x = status['location']['x']
            current_y = status['location']['y']
            yaw = status['location'].get('yaw', 0.0)
            
            # Extract map_id
            map_id = 1
            if 'mapData' in status and 'imageAddress' in status['mapData']:
                import re
                match = re.search(r'/mapping/(\d+)/', status['mapData']['imageAddress'])
                if match:
                    map_id = int(match.group(1))
            
            # Calculate target position
            distance_units = distance_meters * 100
            
            if direction == "forward":
                target_x = current_x + distance_units * math.cos(yaw)
                target_y = current_y + distance_units * math.sin(yaw)
            elif direction == "backward":
                target_x = current_x - distance_units * math.cos(yaw)
                target_y = current_y - distance_units * math.sin(yaw)
            else:
                return f"❌ 不支持的方向: {direction}"
            
            # Send navigation command
            task_name = f"move_{direction}_{int(distance_meters)}m"
            resp = await client.navigation_indoor(
                robot_id,
                task_name=task_name,
                map_id=map_id,
                x=target_x,
                y=target_y
            )
            
            return f"✅ {robot_id} 开始移动 {distance_meters}米\n起点: ({int(current_x)}, {int(current_y)})\n目标: ({int(target_x)}, {int(target_y)})"
        
        return asyncio.run(move())
    except Exception as e:
        return f"❌ 移动失败: {str(e)[:200]}"

def handle_robot_turn(robot_id, degrees=90.0, direction="right"):
    """Rotate robot in place."""
    try:
        from dotenv import load_dotenv
        load_dotenv(WORKSPACE_DIR / "roboagent-repo" / ".env")
        
        from roboagent.robot_client import RobotAPIClient
        
        async def turn():
            base_url = os.getenv("ROBOT_API_BASE_URL")
            username = os.getenv("ROBOT_USERNAME")
            password_hash = os.getenv("ROBOT_PASSWORD_HASH")
            
            client = RobotAPIClient(base_url=base_url, username=username, password_hash=password_hash)
            
            # Clamp degrees to API limits
            degrees_clamped = max(1.0, min(360.0, degrees))
            
            # Determine command
            command = "turn_right" if direction == "right" else "turn_left"
            
            # Send handle command
            resp = await client.handle(robot_id, command=command, step=degrees_clamped)
            
            direction_zh = "右转" if direction == "right" else "左转"
            return f"✅ {robot_id} {direction_zh} {int(degrees_clamped)}度"
        
        return asyncio.run(turn())
    except Exception as e:
        return f"❌ 转向失败: {str(e)[:200]}"

def process_wecom_message(user_id, message):
    """Process message with intelligent routing."""
    
    msg_lower = message.lower().strip()
    
    # Simple greetings
    if msg_lower in ["你好", "hello", "hi", "nihao"]:
        return "🐺 你好！有什么可以帮你的？"
    
    # Robot snapshot
    if any(kw in message for kw in ["拍照", "照片", "拍张", "snapshot", "photo", "相机", "镜头"]):
        robot_id = "Go2_021"
        if "001" in message:
            robot_id = "Go2_001"
        elif "021" in message or "21" in message:
            robot_id = "Go2_021"
        
        image_path, reply = handle_robot_snapshot(robot_id)
        if image_path:
            return {"type": "image", "path": image_path, "caption": reply}
        else:
            return reply
    
    # Parse robot IDs
    def get_robot_ids(msg):
        if "001" in msg:
            return ["Go2_001"]
        elif "021" in msg or "21" in msg:
            return ["Go2_021"]
        elif "都" in msg or "两" in msg or "all" in msg:
            return ["Go2_021", "Go2_001"]
        return None
    
    # Robot actions
    if any(kw in message for kw in ["站", "起来", "stand"]):
        return handle_robot_action("stand_up", get_robot_ids(message))
    
    if any(kw in message for kw in ["趴", "lie", "down", "躺"]):
        return handle_robot_action("lie_down", get_robot_ids(message))
    
    if any(kw in message for kw in ["坐", "sit"]):
        return handle_robot_action("sit", get_robot_ids(message))
    
    if any(kw in message for kw in ["招呼", "挥手", "wave", "hello"]) and "打" in message:
        return handle_robot_action("wave", get_robot_ids(message))
    
    if any(kw in message for kw in ["伸", "懒腰", "stretch"]):
        return handle_robot_action("stretch", get_robot_ids(message))
    
    if any(kw in message for kw in ["舞", "跳舞", "dance"]):
        if "2" in message:
            return handle_robot_action("dance2", get_robot_ids(message))
        else:
            return handle_robot_action("dance1", get_robot_ids(message))
    
    # Robot status
    if any(kw in message for kw in ["机器狗", "状态", "robot", "status", "狗"]):
        return handle_robot_status()
    
    # Movement commands
    if any(kw in message for kw in ["走", "移动", "前进", "move", "walk", "forward"]):
        robot_id = "Go2_021"
        if "001" in message:
            robot_id = "Go2_001"
        elif "021" in message or "21" in message:
            robot_id = "Go2_021"
        
        distance = 2.0
        if "一步" in message or "1步" in message:
            distance = 1.0
        elif "两步" in message or "2步" in message:
            distance = 2.0
        elif "三步" in message or "3步" in message:
            distance = 3.0
        elif "米" in message:
            import re
            match = re.search(r'(\d+(?:\.\d+)?)\s*米', message)
            if match:
                distance = float(match.group(1))
        
        return handle_robot_move(robot_id, distance, "forward")
    
    if any(kw in message for kw in ["后退", "倒退", "backward"]):
        robot_id = "Go2_021"
        if "001" in message:
            robot_id = "Go2_001"
        elif "021" in message or "21" in message:
            robot_id = "Go2_021"
        
        distance = 2.0
        if "一步" in message or "1步" in message:
            distance = 1.0
        elif "两步" in message or "2步" in message:
            distance = 2.0
        
        return handle_robot_move(robot_id, distance, "backward")
    
    # Rotation commands
    if any(kw in message for kw in ["转", "旋转", "turn", "rotate"]):
        robot_id = "Go2_021"
        if "001" in message:
            robot_id = "Go2_001"
        elif "021" in message or "21" in message:
            robot_id = "Go2_021"
        
        direction = "right"
        if any(kw in message for kw in ["左", "left"]):
            direction = "left"
        elif any(kw in message for kw in ["右", "right"]):
            direction = "right"
        
        degrees = 90.0
        import re
        match = re.search(r'(\d+(?:\.\d+)?)\s*度', message)
        if match:
            degrees = float(match.group(1))
        elif re.search(r'(\d+)', message):
            match = re.search(r'(\d+)', message)
            degrees = float(match.group(1))
        
        return handle_robot_turn(robot_id, degrees, direction)
    
    # Default
    return "🐺 收到你的消息。我可以帮你查看机器狗状态、控制机器人等。"

if __name__ == "__main__":
    data = json.load(sys.stdin)
    user_id = data["user_id"]
    message = data["message"]
    
    reply = process_wecom_message(user_id, message)
    print(json.dumps({"user_id": user_id, "reply": reply}, ensure_ascii=False))
PYEOF
    
    chmod +x "$WECOM_BOT_DIR/instant_processor.py"
    
    log_info "✓ WeCom 机器人配置完成"
}

# ============================================
# 7. Create Systemd Service
# ============================================
create_systemd_service() {
    log_info "创建 systemd 服务..."
    
    sudo tee /etc/systemd/system/wecom-bot.service > /dev/null << EOF
[Unit]
Description=WeCom Queue Bot - OpenClaw Integration
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$WECOM_BOT_DIR
ExecStart=$WECOM_BOT_DIR/venv/bin/python app_instant_real.py
Restart=always
RestartSec=10
Environment="PATH=$WECOM_BOT_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin"

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable wecom-bot.service
    
    log_info "✓ Systemd 服务创建完成"
}

# ============================================
# 8. Start Services
# ============================================
start_services() {
    log_info "启动服务..."
    
    # Start OpenClaw gateway
    prompt_input "START_OPENCLAW" "是否启动 OpenClaw Gateway? (y/n)" "y"
    if [ "$START_OPENCLAW" == "y" ]; then
        openclaw gateway start
        log_info "✓ OpenClaw Gateway 已启动"
    fi
    
    # Start WeCom bot
    prompt_input "START_WECOM_BOT" "是否启动 WeCom Bot? (y/n)" "y"
    if [ "$START_WECOM_BOT" == "y" ]; then
        sudo systemctl start wecom-bot.service
        sudo systemctl status wecom-bot.service --no-pager -l
        log_info "✓ WeCom Bot 已启动"
    fi
}

# ============================================
# 9. Display Summary
# ============================================
display_summary() {
    log_info "========================================"
    log_info "部署完成！"
    log_info "========================================"
    echo
    log_info "已安装组件:"
    log_info "  - OpenClaw Gateway"
    log_info "  - WeCom Bot (systemd service)"
    log_info "  - Robot Agent (roboagent)"
    echo
    log_info "配置文件位置:"
    log_info "  - OpenClaw: ${HOME}/.openclaw/config.json"
    log_info "  - WeCom Bot: $WECOM_BOT_DIR/.env"
    log_info "  - Robot Agent: $ROBOT_REPO_DIR/.env"
    echo
    log_info "服务管理:"
    log_info "  - OpenClaw: openclaw gateway start/stop/status"
    log_info "  - WeCom Bot: sudo systemctl start/stop/status wecom-bot.service"
    echo
    log_info "日志查看:"
    log_info "  - OpenClaw: openclaw logs"
    log_info "  - WeCom Bot: sudo journalctl -u wecom-bot.service -f"
    echo
    log_info "下一步:"
    log_info "  1. 配置企业微信回调 URL"
    log_info "  2. 测试机器人命令"
    log_info "  3. 查看日志确认运行状态"
    echo
}

# ============================================
# Main Execution
# ============================================
main() {
    log_info "========================================"
    log_info "OpenClaw + WeCom + Robot 部署脚本"
    log_info "========================================"
    echo
    
    check_prerequisites
    install_system_deps
    install_openclaw
    configure_openclaw
    setup_robot_repo
    setup_wecom_bot
    create_systemd_service
    start_services
    display_summary
    
    log_info "🎉 所有步骤完成！"
}

# Run main function
main
