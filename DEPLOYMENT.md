# Caddy 容器 + 宿主机静态网页

## 当前布局

部署根目录为 `/opt/howdo`：

```text
compose.yaml               容器配置
deploy/Caddyfile            Caddy 配置
.env                       可选的本机镜像配置，不提交 Git
site/releases/<版本>/       每次发布的完整静态网页
site/current                相对符号链接，指向正在使用的版本
```

Compose 将整个 `site/` 只读挂载到 `/srv`，Caddy 从 `/srv/current` 读取网页。必须挂载父目录，不能直接把 `site/current` 作为挂载源，否则切换符号链接时容器可能仍使用旧目录。

Caddy 容器负责 80/443 访问、HTTP→HTTPS 跳转、证书申请和续期。证书卷固定为 `howdo_caddy_data`、`howdo_caddy_config`。

## 直接发布文章

在电脑上安装 Node.js 22.13 或以上、Python 3、OpenSSH 和 curl。本地依赖首次安装使用 `npm ci`。

```sh
npm run publish:site -- --host <VPS地址> --key <本地SSH密钥路径> --known-hosts <已核实的known_hosts文件>
```

可选：`--user`、`--port`、`--site-dir`。默认用户 root、端口 22、站点目录 `/opt/howdo/site`；当前仅通过用户本地登录权限执行，不配置 GitHub 自动部署。

过程：

1. 构建并检查网页。
2. 将 `dist/` 和非敏感发布标记打包，通过 SSH 上传。
3. 在新版本目录解压，检查必要文件。
4. 原子切换 `current`，避免边上传边提供不完整文件。
5. 使用证书校验开启的 HTTPS 检查版本、首页、订阅、站点地图、搜索索引和真实 404。
6. 服务器端验收失败时恢复上一链接；成功后再检查公网发布标记。

公开的 `/__release.json` 只包含版本标记和内容摘要，不含凭据。发布脚本不会调用 Docker。

## 首次准备或更换服务器

1. 检查系统、Docker Compose、80/443 占用、DNS 和云安全组。
2. 将项目配置放在 `/opt/howdo`。
3. 创建 `site/releases/initial/`，将完整静态网页解压进去。
4. 创建相对链接：`ln -s releases/initial site/current`。
5. 网络正常时使用默认官方 Caddy 镜像，执行 `docker compose up -d`。
6. 验收可信 HTTPS 和网页，然后使用发布脚本更新。

当前 VPS 因 Docker Hub 超时复用了已安装的 Caddy 运行环境，在 `.env` 使用 `CADDY_IMAGE=howdo-caddy:existing`。此镜像来自此前部署，已有的内嵌网页被 `/srv` 挂载遮蔽，实际提供的是宿主机文件。迁移或重装时保留镜像备份，或在能拉取官方镜像的环境使用 `caddy:2-alpine`。

## 常用操作

```sh
cd /opt/howdo
docker compose ps
docker compose logs --tail=100 web
readlink site/current
```

日常文章更新不用运行 `docker compose up`、`restart` 或构建镜像。

保留了旧版本时，可以在 `site/` 目录创建新的相对链接，再通过 `mv -Tf` 替换 `current`，实现回退。检查目标版本完整、链接仍位于 `releases/` 中，并在回退后验收网站。

不要运行 `docker compose down -v` 删除证书卷。GitHub Actions 仅做静态检查，不负责部署。
