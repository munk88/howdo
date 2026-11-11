# 备份、恢复和更换 VPS

源码仓库：<https://github.com/munk88/howdo>。域名：`howdo.icu`。

## 需要保存什么

1. 源码：Markdown、同目录图片、主题、配置、`package-lock.json`、Dockerfile、Compose 和 Caddyfile。保存在 Git 仓库，并额外保留一份离线备份。
2. 可选的成品：`dist/` 或 `npm run package` 生成的静态压缩包。
3. Caddy 数据：`howdo_caddy_data` 卷中的证书、私钥与 ACME 账户；`howdo_caddy_config` 是 Caddy 配置状态卷。
4. 如果使用 `.env`，单独保存；不要提交 Git。

## 源码与成品打包

有 Node.js 的电脑上：

```sh
npm ci
npm run package
```

`release/` 生成源码包与静态网页包。源码包不含 node_modules、Git 历史、`.env`、缓存或 release 本身。Docker 证书卷不在源码包内。

只有 Docker 的 VPS 可以用 `docker cp` 从运行容器提取静态网页，或直接从 Git 克隆源码在新机器构建。

## 证书卷备份

先在本项目目录创建 `backups/`。以下操作会短暂停止网站，完成后恢复：

```sh
mkdir -p backups
chmod 700 backups
docker compose stop web
docker run --rm -v howdo_caddy_data:/data:ro -v "$PWD/backups:/backup" alpine:3 sh -c 'umask 077; tar czf /backup/caddy-data.tar.gz -C /data .'
docker run --rm -v howdo_caddy_config:/config:ro -v "$PWD/backups:/backup" alpine:3 sh -c 'umask 077; tar czf /backup/caddy-config.tar.gz -C /config .'
docker compose start web
```

任一步备份失败也应及时执行 `docker compose start web` 恢复服务。备份文件含证书私钥，只保存在私有位置，不上传 GitHub 或公开下载链接。`backups/` 已被 Git 与 Docker 构建上下文排除。

## 新 VPS 恢复

1. 安装 Docker Engine、Compose 与 Git，确认 80/443 无端口冲突。
2. 克隆仓库到新服务器。
3. 可选：将证书备份放到项目的 `backups/`，在首次启动前恢复卷。

```sh
docker volume create howdo_caddy_data
docker volume create howdo_caddy_config
docker run --rm -v howdo_caddy_data:/data -v "$PWD/backups:/backup:ro" alpine:3 sh -c 'tar xzf /backup/caddy-data.tar.gz -C /data'
docker run --rm -v howdo_caddy_config:/config -v "$PWD/backups:/backup:ro" alpine:3 sh -c 'tar xzf /backup/caddy-config.tar.gz -C /config'
```

4. 运行 `docker compose up -d --build`。
5. 将 `howdo.icu` 的 A 记录切换到新 IP；同步检查 AAAA、云安全组和系统防火墙。
6. 检查 HTTPS、文章、图片、搜索、RSS、Sitemap 与真实 404。

没有证书备份也可以重新申请，但签发需要 DNS 指向新服务器并满足 ACME 验证条件，同时可能受 CA 的频率限制。迁移时保留证书卷能减少重复签发。

域名和文章路径不变，旧文章链接就能保留。旧 VPS 到期前提前迁移，尽量留出验证和回退时间。
