#!/bin/sh
# 只检查，不安装软件、不修改防火墙、不停止已有服务。
set -eu
printf '系统与身份\n'
uname -s
id
if [ -f /etc/os-release ]; then cat /etc/os-release; fi
printf '\nDocker\n'
if ! command -v docker >/dev/null 2>&1; then
    printf '未找到 Docker。请先按系统安装 Docker Engine 与 Compose 插件。\n' >&2
    exit 1
fi
docker version --format 'Client: {{.Client.Version}}; Server: {{.Server.Version}}'
docker compose version
printf '\n端口监听（部署需要 80/tcp、443/tcp；443/udp 为可选 HTTP/3）\n'
if command -v ss >/dev/null 2>&1; then
    ss -ltnp 'sport = :80 or sport = :443'
    ss -lunp 'sport = :443'
else
    printf '没有 ss，请自行确认 80/443 是否已被其他服务占用。\n'
fi
printf '\n域名解析（应指向你的 VPS 公网 IP；如使用 CDN，请同时检查源站设置）\n'
if command -v getent >/dev/null 2>&1; then
    getent ahosts howdo.icu || true
fi
printf '\n当前容器\n'
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
printf '\nCompose 配置\n'
docker compose config --quiet
printf '\n检查完成。请核对端口、DNS 与云安全组，再执行 docker compose up -d。\n'
