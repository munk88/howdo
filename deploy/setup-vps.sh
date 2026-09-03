#!/usr/bin/env bash
# ============================================================
# VPS 一次性初始化脚本（仅首次部署时在 VPS 上运行一次）
# 用法： bash setup-vps.sh
# 前置： 你已能通过 SSH 登录 VPS（root 或你的用户）
# ============================================================
set -euo pipefail

echo "==> 1/2 安装 Docker（若未安装）"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi
docker --version

echo "==> 2/2 创建部署目录"
mkdir -p /opt/blog
echo "目录已就绪：/opt/blog"

echo ""
echo "============================================================"
echo "完成！接下来（详见 README）："
echo "  1) 把 GitHub Actions 的部署公钥加入本机 ~/.ssh/authorized_keys"
echo "  2) 在 GitHub 仓库 Settings → Secrets 添加 VPS_HOST / VPS_USER / VPS_SSH_KEY"
echo "  3) 把域名 A 记录指向本 VPS 公网 IP"
echo "  4) 在仓库 Caddyfile 与 astro.config.mjs 中写入真实域名后推送 main"
echo "  5) 首次推送后，GitHub Actions 会自动构建并部署到 /opt/blog"
echo "============================================================"
