#!/usr/bin/env bash
set -euo pipefail

# ============================================
# howdo.icu VPS 一键部署脚本（Docker + Nginx 版）
# 在 VPS 上执行：安装 Docker + 拉取代码 + 启动容器
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

[[ $EUID -eq 0 ]] || error "请使用 root 用户或 sudo 执行此脚本"

DOMAIN="howdo.icu"
DEPLOY_DIR="/opt/howdo"
REPO_URL="${1:-}"

info "=== howdo.icu VPS 部署脚本（Docker + Nginx）==="
info "域名: ${DOMAIN}"
info "部署目录: ${DEPLOY_DIR}"
echo ""

# ============================================
# 1. 安装 Docker
# ============================================
if ! command -v docker &> /dev/null; then
    info "安装 Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
    info "Docker 安装完成: $(docker --version)"
else
    info "Docker 已安装: $(docker --version)"
fi

# ============================================
# 2. 安装 Docker Compose v2 插件
# ============================================
if ! docker compose version &> /dev/null; then
    info "安装 Docker Compose 插件..."
    apt-get update -qq
    apt-get install -y -qq docker-compose-plugin
    info "Docker Compose 已就绪"
else
    info "Docker Compose 已就绪: $(docker compose version)"
fi

# ============================================
# 3. 克隆代码（或更新）
# ============================================
if [[ -z "${REPO_URL}" ]]; then
    warn "未提供 Git 仓库地址，假设代码已在 ${DEPLOY_DIR}"
    if [[ ! -d "${DEPLOY_DIR}" ]]; then
        error "部署目录 ${DEPLOY_DIR} 不存在。请先 clone 仓库或手动上传代码。"
    fi
else
    if [[ -d "${DEPLOY_DIR}/.git" ]]; then
        info "更新代码..."
        cd "${DEPLOY_DIR}"
        git pull origin main
    else
        info "克隆代码到 ${DEPLOY_DIR}..."
        mkdir -p "$(dirname "${DEPLOY_DIR}")"
        git clone "${REPO_URL}" "${DEPLOY_DIR}"
        cd "${DEPLOY_DIR}"
    fi
fi

cd "${DEPLOY_DIR}"

# ============================================
# 4. 构建并启动容器
# ============================================
info "构建 Docker 镜像并启动服务..."

# 构建博客镜像
docker compose build web

# 启动所有服务（博客 + Nginx 反向代理）
docker compose up -d

# 等待容器启动
sleep 3

# ============================================
# 5. 检查状态
# ============================================
info "检查容器状态..."
if docker compose ps | grep -q "howdo-blog.*Up"; then
    info "howdo-blog 容器运行中"
else
    error "howdo-blog 容器启动失败，运行 docker compose logs 查看日志"
fi

if docker compose ps | grep -q "howdo-nginx.*Up"; then
    info "howdo-nginx 容器运行中"
else
    warn "howdo-nginx 容器未就绪，首次启动需申请 SSL 证书，请等待 1-2 分钟"
fi

# ============================================
# 6. 防火墙提示
# ============================================
echo ""
info "=== 部署完成 ==="
echo ""
warn "请确保以下条件已满足："
echo ""
echo "  1. DNS 配置："
echo "     A     howdo.icu        →  本 VPS 公网 IP"
echo "     A     www.howdo.icu    →  本 VPS 公网 IP"
echo ""
echo "  2. 防火墙开放端口："
echo "     ufw allow 80/tcp"
echo "     ufw allow 443/tcp"
echo ""
echo "  3. 在 GitHub 仓库配置 Secrets："
echo "     VPS_SSH_KEY      — SSH 私钥"
echo "     VPS_HOST         — VPS 公网 IP"
echo "     VPS_USER         — SSH 用户名"
echo "     VPS_DEPLOY_PATH  — ${DEPLOY_DIR}"
echo ""
info "Let's Encrypt 证书会在容器启动后自动申请（需 DNS 已生效）"
info "查看日志: docker compose logs -f"
info "验证访问: https://${DOMAIN}"
echo ""
warn "首次部署如证书申请失败，检查："
echo "  - DNS 是否已指向本机（dig ${DOMAIN}）"
echo "  - 80 端口是否被占用（netstat -tlnp | grep :80）"
echo "  - jonasal/nginx-certbot 日志: docker compose logs nginx"
