#!/usr/bin/env python3
"""
howdo.icu Webhook 接收器
监听 GitHub Push 事件，触发本地构建部署
无 SSH 密钥，无外部连接，纯本地 HTTP 服务

安全机制：
1. HMAC-SHA256 签名验证（GitHub Webhook Secret）
2. 只接受 POST /webhook
3. 只处理 main 分支的 push 事件
4. 部署日志写入文件，可审计
"""

import hashlib
import hmac
import json
import os
import subprocess
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler

# ============================================
# 配置
# ============================================
PORT = 9000
WEBHOOK_SECRET = os.environ.get("WEBHOOK_SECRET", "CHANGE_ME_TO_RANDOM_STRING")
DEPLOY_DIR = "/opt/howdo"
LOG_FILE = "/var/log/howdo-webhook.log"

# ============================================
# 日志
# ============================================
def log(msg):
    with open(LOG_FILE, "a") as f:
        from datetime import datetime
        f.write(f"[{datetime.now().isoformat()}] {msg}\n")
    print(f"[{datetime.now().isoformat()}] {msg}")

# ============================================
# 部署函数
# ============================================
def deploy():
    """在后台线程执行部署，避免 HTTP 请求超时"""
    try:
        log("=== 开始部署 ===")

        # 拉取最新代码
        log("git pull...")
        result = subprocess.run(
            ["git", "pull", "origin", "main"],
            cwd=DEPLOY_DIR, capture_output=True, text=True, timeout=60
        )
        log(f"git pull: {result.stdout.strip()}")
        if result.returncode != 0:
            log(f"git pull FAILED: {result.stderr}")
            return

        # 构建并重启
        log("docker compose build + restart...")
        result = subprocess.run(
            ["docker", "compose", "up", "-d", "--build"],
            cwd=DEPLOY_DIR, capture_output=True, text=True, timeout=300
        )
        log(f"docker compose: {result.stdout.strip()}")
        if result.returncode != 0:
            log(f"docker compose FAILED: {result.stderr}")
            return

        # 清理旧镜像
        subprocess.run(["docker", "image", "prune", "-f"], capture_output=True, timeout=30)

        log("=== 部署完成 ===")
    except Exception as e:
        log(f"部署异常: {str(e)}")

# ============================================
# HTTP Handler
# ============================================
class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        # 只接受 /webhook 路径
        if self.path != "/webhook":
            self.send_error(404)
            return

        # 读取请求体
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length)

        # 验证 GitHub 签名
        signature = self.headers.get("X-Hub-Signature-256", "")
        if not self.verify_signature(body, signature):
            log("签名验证失败，拒绝请求")
            self.send_error(403)
            return

        # 检查事件类型
        event = self.headers.get("X-GitHub-Event", "")
        if event != "push":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'{"status":"ignored"}')
            return

        # 解析 payload，检查分支
        payload = json.loads(body)
        ref = payload.get("ref", "")
        if ref != "refs/heads/main":
            log(f"忽略非 main 分支推送: {ref}")
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'{"status":"ignored"}')
            return

        # 立即返回 200，后台异步部署
        log(f"收到 main 分支推送，触发部署")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"status":"deploying"}')

        # 后台线程执行部署
        threading.Thread(target=deploy, daemon=True).start()

    def verify_signature(self, body, signature):
        """验证 GitHub HMAC-SHA256 签名"""
        if not signature.startswith("sha256="):
            return False
        expected = "sha256=" + hmac.new(
            WEBHOOK_SECRET.encode(),
            body,
            hashlib.sha256
        ).hexdigest()
        return hmac.compare_digest(signature, expected)

    def do_GET(self):
        """健康检查端点"""
        if self.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'{"status":"ok"}')
        else:
            self.send_error(404)

    def log_message(self, format, *args):
        pass  # 静默默认日志

# ============================================
# 启动
# ============================================
if __name__ == "__main__":
    # 确保日志文件存在
    open(LOG_FILE, "a").close()

    server = HTTPServer(("127.0.0.1", PORT), WebhookHandler)
    log(f"Webhook 服务启动，监听 127.0.0.1:{PORT}")
    log(f"部署目录: {DEPLOY_DIR}")
    log(f"健康检查: http://127.0.0.1:{PORT}/health")
    server.serve_forever()
