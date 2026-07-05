#!/usr/bin/env bash
set -euo pipefail

# ============================================
# howdo.icu Webhook 方案一键安装脚本
# 在 VPS 上执行，配置 webhook-server + Nginx 代理
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

DEPLOY_DIR="/opt/howdo"
WEBHOOK_SECRET=""

info "=== howdo.icu Webhook 方案安装 ==="
echo ""

# ============================================
# 1. 生成随机 Webhook Secret
# ============================================
WEBHOOK_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
info "生成 Webhook Secret: ${WEBHOOK_SECRET}"
echo ""
warn "请保存这个 Secret，稍后要填入 GitHub Webhook 配置"
echo ""

# ============================================
# 2. 更新 systemd 服务的 Secret
# ============================================
info "配置 systemd 服务..."
sed -i "s|CHANGE_ME_TO_RANDOM_STRING|${WEBHOOK_SECRET}|g" "${DEPLOY_DIR}/scripts/howdo-webhook.service"

# ============================================
# 3. 安装 systemd 服务
# ============================================
info "安装 systemd 服务..."
cp "${DEPLOY_DIR}/scripts/howdo-webhook.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable howdo-webhook
systemctl restart howdo-webhook

sleep 2
if systemctl is-active --quiet howdo-webhook; then
    info "webhook 服务运行中"
else
    error "webhook 服务启动失败，运行 journalctl -u howdo-webhook 查看日志"
fi

# ============================================
# 4. 更新 Nginx 配置并重启
# ============================================
info "重启 Nginx 容器以加载新配置..."
cd "${DEPLOY_DIR}"
docker compose restart nginx

sleep 3
info "Nginx 已重启"

# ============================================
# 5. 验证
# ============================================
info "验证 webhook 服务..."
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:9000/health 2>/dev/null || echo "failed")
if [[ "$HEALTH" == "200" ]]; then
    info "webhook 健康检查通过"
else
    warn "webhook 健康检查失败（状态码: $HEALTH），可能需要等几秒"
fi

# ============================================
# 6. 输出 GitHub Webhook 配置指引
# ============================================
echo ""
echo "=========================================="
echo "  安装完成 — 接下来配置 GitHub Webhook"
echo "=========================================="
echo ""
echo "1. 打开: https://github.com/munk88/howdo/settings/hooks/new"
echo ""
echo "2. 填写以下信息:"
echo "   Payload URL:  https://howdo.icu/webhook"
echo "   Content type: application/json"
echo "   Secret:       ${WEBHOOK_SECRET}"
echo "   Events:       Just the push event"
echo "   Active:       ✓"
echo ""
echo "3. 点 Add webhook"
echo ""
echo "4. 测试: 随便 push 一次代码，然后看部署日志:"
echo "   tail -f /var/log/howdo-webhook.log"
echo ""
warn "重要: 把上面的 Secret 记下来，GitHub 和 VPS 必须一致"
echo ""
info "日常发布流程不变:"
echo "   写 Markdown → git push → GitHub 发 webhook → VPS 自动构建部署"
echo ""
echo "=========================================="
echo "  SSH 密钥可以删除了（不再需要）"
echo "=========================================="
echo "  rm -f /root/.ssh/github_actions*"
echo "  然后在 GitHub Secrets 里删除 VPS_SSH_KEY / VPS_HOST / VPS_USER / VPS_DEPLOY_PATH"
echo "=========================================="
