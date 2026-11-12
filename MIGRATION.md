# 备份与迁移

## 保存这些内容

- GitHub 源码和独立离线副本：文章、图片、主题、配置和依赖锁文件。
- VPS `/opt/howdo/site/`：当前网页、相对链接和需要保留的历史版本。
- `/opt/howdo/compose.yaml`、`deploy/`，以及单独保存的 `.env`。
- Docker 证书卷 `howdo_caddy_data` 和 `howdo_caddy_config`。
- 如果使用了无法重新拉取的本地 Caddy 镜像，额外导出镜像。

有 Node.js 的电脑可运行 `npm run package`，得到源码与静态成品两份压缩包。此命令不包含服务器证书卷。

## 服务器备份示例

在 `/opt/howdo` 执行，备份放在仅自己可访问的位置：

```sh
mkdir -p backups
chmod 700 backups
tar czf backups/site.tar.gz site compose.yaml deploy
# 如果有 .env，请单独私下保存。
docker save howdo-caddy:existing | gzip > backups/caddy-runtime.tar.gz
```

镜像导出命令适用于当前复用本地镜像的 VPS；使用官方镜像时调整镜像名。

证书卷包含私钥，不能上传公开仓库。当前运行镜像带有 tar 工具，可在短暂停站时备份：

```sh
docker compose stop web
docker run --rm --entrypoint sh -v howdo_caddy_data:/data:ro -v "$PWD/backups:/backup" howdo-caddy:existing -c 'umask 077; tar czf /backup/caddy-data.tar.gz -C /data .'
docker run --rm --entrypoint sh -v howdo_caddy_config:/config:ro -v "$PWD/backups:/backup" howdo-caddy:existing -c 'umask 077; tar czf /backup/caddy-config.tar.gz -C /config .'
docker compose start web
```

任一步失败时也应及时恢复 `docker compose start web`。

## 新 VPS 恢复

1. 安装 Docker Compose，检查 DNS、80/443、已有服务和可用空间。
2. 恢复 `/opt/howdo` 配置和 `site/`，确保 `site/current` 是指向 `releases/<版本>` 的相对链接。
3. 必要时用 `docker load -i` 导入 Caddy 镜像；或者拉取官方 Caddy 镜像。
4. 创建同名证书卷，私下传输并恢复证书备份。
5. 启动 Compose，检查 HTTPS、文章、图片、搜索、RSS、Sitemap 和 404。
6. 切换域名解析到新 IP，公网验收通过后再处理旧服务器。

域名和文章路径不变，旧链接可以继续使用。没有证书备份也可重新申请，但需要满足签发条件，并可能受到签发频率限制。

以后继续从电脑直接上传网页，不必在新 VPS 安装 Node.js，也不依赖 GitHub 自动部署。
