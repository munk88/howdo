#!/usr/bin/env bash
# ============================================================
# VPS 一次性初始化脚本（仅首次部署时在 VPS 上运行一次）
# 用法： bash setup-vps.sh
# 说明： 适配普通用户（如 ubuntu）运行；需要 sudo 权限。
#        Docker 安装 + 部署目录授权 + 用户加入 docker 组
# ============================================================
set -euo pipefail

# 实际用户（支持 sudo 场景）
RUN_USER="${SUDO_USER:-$USER}"
echo "==> 当前操作用户：${RUN_USER}"

echo "==> 1/3 安装 Docker（若未安装）"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sudo sh
else
  echo "Docker 已安装："
fi
docker --version

echo "==> 2/3 创建部署目录并授权给 ${RUN_USER}"
sudo mkdir -p /opt/blog
sudo chown -R "${RUN_USER}:${RUN_USER}" /opt/blog
ls -ld /opt/blog

echo "==> 3/3 将 ${RUN_USER} 加入 docker 组（避免每次 sudo docker）"
if groups "${RUN_USER}" | grep -q docker; then
  echo "已在 docker 组"
else
  sudo usermod -aG docker "${RUN_USER}"
  echo "已加入 docker 组（新登录才生效）"
fi

echo ""
echo "============================================================"
echo "完成！接下来（详见 README）："
echo "  1) 把部署公钥加入本机（ubuntu 用户）~/.ssh/authorized_keys："
echo "     mkdir -p ~/.ssh && echo '<公钥>' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
echo "  2) 在 GitHub 仓库 Settings → Secrets 添加："
echo "     VPS_HOST = 你的VPS公网IP"
echo "     VPS_USER = ubuntu"
echo "     VPS_SSH_KEY = 部署私钥内容"
echo "  3) 把域名 A 记录指向本 VPS 公网 IP"
echo "  4) 在仓库 Actions 页点击 Run workflow 触发部署"
echo "============================================================"
