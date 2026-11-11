# Docker 部署 howdo.icu

目标：`howdo.icu` → 你的 VPS → Docker 内的 Caddy → Astro 静态网页。

## 1. DNS 与端口

在域名 DNS 控制台添加或修改：

| 类型 | 名称 | 值 |
| --- | --- | --- |
| A | @ | 你的 VPS 公网 IPv4 |

如果已有 AAAA 记录，必须指向这台 VPS 可达的 IPv6；没有可用 IPv6 就移除不正确的 AAAA，避免部分访问和 ACME 验证走错服务器。不要改动邮件等无关记录。

首次排障建议直连源站。若使用 CDN/代理，需确保验证请求可抵达 Caddy，且源站 HTTPS 和 CDN TLS 模式一致。可在 DNS 与证书正常后再启用 CDN。

本版只配置裸域名 `howdo.icu`，没有启用 `www`，不需要为未配置的 `www` 申请证书。

如果 VPS 使用腾讯云安全组或其他云防火墙，放行入站 **TCP 80、TCP 443**。UDP 443 为可选 HTTP/3。系统防火墙也需要允许相同端口，保留现有 SSH 入口。

80/443 若被已有 Nginx、Caddy 或容器占用，应先规划共用入口，不要直接停用其他业务。

## 2. 检查系统与 Docker

登录 VPS 后先查看：

```sh
uname -s
cat /etc/os-release
id
command -v docker
docker version
docker compose version
ss -ltnp 'sport = :80 or sport = :443'
```

若没有 Docker，请按实际系统参考官方安装说明：

- https://docs.docker.com/engine/install/
- https://docs.docker.com/compose/install/linux/

不要在不知道系统和已有服务状态时直接套用安装脚本。

## 3. 部署

```sh
git clone https://github.com/munk88/howdo.git
cd howdo
sh deploy/preflight.sh
docker compose up -d --build
docker compose ps
docker compose logs --tail=100 web
```

初次构建需要从 Docker Hub 拉取 Node/Caddy 镜像，并从 npm 获取锁定版本的依赖。网络受限时先解决镜像和 npm 连通性；不要因下载失败反复删库或重置 Docker。

无需 `.env`。`compose.yaml` 默认使用 `DOMAIN=howdo.icu`，发布 80/443 TCP 和 443 UDP。

Dockerfile 分两阶段：Node 构建并检查网站，Caddy 镜像只带静态网页和 Web 配置。

## 4. 自动 HTTPS

Caddyfile 使用域名作为站点地址，默认开启自动 HTTPS。证书的申请、续期和 HTTP→HTTPS 跳转由 Caddy 管理，不需要另装 Certbot 或 cron。

证书成功的条件是 DNS 正确、80/443 对公网可达、服务器出站可联系 ACME CA、持久卷可写，以及 CAA 等域名策略允许签发。容器启动成功不代表证书已经签发成功。

通过以下方式验证：

```sh
curl -I http://howdo.icu
curl -I https://howdo.icu
curl -s -o /dev/null -w '%{http_code}\n' https://howdo.icu/this-page-does-not-exist/
docker compose logs --tail=100 web
```

预期 HTTP 跳转 HTTPS；HTTPS 首页返回 200，证书由客户端正常信任；不存在的路径返回 404。还应打开文章、图片、搜索、`/rss.xml` 和 `/sitemap-index.xml`。

不要用 `curl -k` 作为 HTTPS 成功证明。

## 5. 写作和更新

在本地编辑文章并推送 GitHub，VPS 上运行：

```sh
cd howdo
git pull --ff-only
docker compose up -d --build
```

初次从空仓库发布后，默认 `main` 上的 GitHub Actions 负责 Docker 构建与 HTTP 冒烟测试，不自动登录服务器。无需把服务器密码或私钥放进仓库。

容器重建不影响 `howdo_caddy_data` 和 `howdo_caddy_config`。正常停用可执行 `docker compose down`；不要添加 `-v`，除非确实准备删除证书数据。

## 6. 常用排障

```sh
docker compose ps
docker compose logs --tail=200 web
docker compose config
ss -ltnp 'sport = :80 or sport = :443'
```

- `address already in use`：先确认占用者，决定共用入口或调整部署，不要强杀未知服务。
- ACME timeout：检查 DNS、AAAA、云安全组、系统防火墙与公网端口。
- 构建下载失败：区分 Docker Hub 镜像拉取与容器内 npm 下载，两者走的网络配置可能不同。
- 更新后内容没变：检查 Git 提交、Docker 构建结果，以及浏览器/CDN 缓存。

## 官方参考

- Caddy 自动 HTTPS：https://caddyserver.com/docs/automatic-https
- Caddy 容器运行与持久卷：https://caddyserver.com/docs/running
