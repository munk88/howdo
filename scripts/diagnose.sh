#!/usr/bin/env bash
set -euo pipefail

# ============================================
# howdo.icu 诊断脚本
# 在 VPS 上执行，排查 Connection reset by peer 问题
# 用法: bash diagnose.sh
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()   { echo -e "${GREEN}  [✓]${NC} $1"; }
fail() { echo -e "${RED}  [✗]${NC} $1"; }
warn() { echo -e "${YELLOW}  [!]${NC} $1"; }
info() { echo -e "${BLUE}  [i]${NC} $1"; }

echo ""
echo "=========================================="
echo "  howdo.icu 部署诊断"
echo "=========================================="
echo ""

# ============================================
# 1. Docker 容器状态
# ============================================
echo "1. 检查 Docker 容器状态"
echo "------------------------------------------"
if docker compose ps 2>/dev/null | grep -q "howdo"; then
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker compose ps
    echo ""
    # 检查每个容器是否真的在运行
    if docker compose ps 2>/dev/null | grep -q "howdo-blog.*Up"; then
        ok "howdo-blog 容器运行中"
    else
        fail "howdo-blog 容器未运行"
    fi
    if docker compose ps 2>/dev/null | grep -q "howdo-nginx.*Up"; then
        ok "howdo-nginx 容器运行中"
    else
        fail "howdo-nginx 容器未运行（证书申请可能正在进行中）"
    fi
else
    fail "未找到 howdo 容器，请先运行 docker compose up -d"
fi
echo ""

# ============================================
# 2. 端口监听
# ============================================
echo "2. 检查端口监听"
echo "------------------------------------------"
PORT80=$(ss -tlnp 2>/dev/null | grep ':80 ' || echo "")
PORT443=$(ss -tlnp 2>/dev/null | grep ':443 ' || echo "")

if [[ -n "$PORT80" ]]; then
    ok "80 端口已监听"
    info "$PORT80"
else
    fail "80 端口未监听（Let's Encrypt 需要此端口验证）"
fi

if [[ -n "$PORT443" ]]; then
    ok "443 端口已监听"
    info "$PORT443"
else
    fail "443 端口未监听（HTTPS 不可用）"
fi
echo ""

# ============================================
# 3. DNS 解析
# ============================================
echo "3. 检查 DNS 解析"
echo "------------------------------------------"
VPS_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ip.sb 2>/dev/null || echo "unknown")
info "本机公网 IP: $VPS_IP"

DOMAIN_IP=$(dig +short howdo.icu A 2>/dev/null | head -1 || echo "")
if [[ -n "$DOMAIN_IP" ]]; then
    info "howdo.icu 解析到: $DOMAIN_IP"
    if [[ "$DOMAIN_IP" == "$VPS_IP" ]]; then
        ok "DNS 正确指向本机"
    else
        fail "DNS 指向 $DOMAIN_IP，与本机 IP $VPS_IP 不一致"
        warn "请检查域名 DNS A 记录配置"
    fi
else
    fail "howdo.icu 无法解析，DNS 可能尚未生效"
    warn "DNS 生效通常需要 5-30 分钟"
fi
echo ""

# ============================================
# 4. 防火墙
# ============================================
echo "4. 检查防火墙"
echo "------------------------------------------"
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(ufw status 2>/dev/null || echo "")
    if echo "$UFW_STATUS" | grep -q "inactive"; then
        ok "UFW 未启用（所有端口开放）"
    else
        if echo "$UFW_STATUS" | grep -q "80/tcp.*ALLOW"; then
            ok "80 端口已放行"
        else
            fail "80 端口未放行，运行: ufw allow 80/tcp"
        fi
        if echo "$UFW_STATUS" | grep -q "443/tcp.*ALLOW"; then
            ok "443 端口已放行"
        else
            fail "443 端口未放行，运行: ufw allow 443/tcp"
        fi
    fi
else
    warn "未安装 ufw，请手动检查 iptables / firewalld"
fi
echo ""

# ============================================
# 5. Nginx 日志（最关键）
# ============================================
echo "5. 检查 Nginx 容器日志（最近 30 行）"
echo "------------------------------------------"
docker compose logs nginx --tail=30 2>/dev/null || echo "无法获取日志"
echo ""

# ============================================
# 6. 证书状态
# ============================================
echo "6. 检查 SSL 证书"
echo "------------------------------------------"
if docker compose exec -T nginx ls /etc/letsencrypt/live/ 2>/dev/null; then
    ok "证书目录存在"
    docker compose exec -T nginx ls -la /etc/letsencrypt/live/howdo-icu/ 2>/dev/null || warn "howdo-icu 证书目录不存在（可能还在申请中）"
else
    fail "无法访问证书目录（容器可能未运行）"
fi
echo ""

# ============================================
# 7. 本机连通性测试
# ============================================
echo "7. 本机连通性测试"
echo "------------------------------------------"
echo "  测试 HTTP (80):"
HTTP_RESULT=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://127.0.0.1 2>/dev/null || echo "failed")
if [[ "$HTTP_RESULT" != "failed" && "$HTTP_RESULT" != "000" ]]; then
    ok "HTTP 返回状态码: $HTTP_RESULT"
else
    fail "HTTP 连接失败"
fi

echo "  测试 HTTPS (443):"
HTTPS_RESULT=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 5 https://127.0.0.1 2>/dev/null || echo "failed")
if [[ "$HTTPS_RESULT" != "failed" && "$HTTPS_RESULT" != "000" ]]; then
    ok "HTTPS 返回状态码: $HTTPS_RESULT"
else
    fail "HTTPS 连接失败（证书可能尚未申请成功）"
fi
echo ""

# ============================================
# 8. 常见问题提示
# ============================================
echo "=========================================="
echo "  常见问题排查"
echo "=========================================="
echo ""
echo "如果 443 端口未监听或 HTTPS 连接失败："
echo "  → 证书申请可能失败，检查 Nginx 日志中的 certbot 输出"
echo "  → 确认 DNS 已指向本机（dig howdo.icu）"
echo "  → 确认 80 端口可从公网访问（Let's Encrypt 需要验证）"
echo ""
echo "如果证书申请失败："
echo "  → 1. 设置 STAGING=1 先用暂存环境测试"
echo "  → 2. 设置 DEBUG=1 查看详细日志"
echo "  → 3. 清除旧证书重新申请:"
echo "       docker compose down"
echo "       docker volume rm howdo-astro_nginx-certs"
echo "       docker compose up -d"
echo ""
echo "重新部署:"
echo "  docker compose down"
echo "  docker compose up -d --build"
echo "  docker compose logs -f nginx"
echo ""
