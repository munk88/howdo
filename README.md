# howdo.icu

Astro + Markdown 独立博客，**Docker Compose + Caddy** 部署，Caddy 自动申请和续期 HTTPS 证书。

- 正式域名：`howdo.icu`
- 源码：<https://github.com/munk88/howdo>

## VPS 首次部署

前提：服务器已有 Docker Engine、Docker Compose 插件和 Git；域名指向这台 VPS；80/443 TCP 对外可达且没有被其他服务占用。443 UDP 用于可选的 HTTP/3。

```sh
git clone https://github.com/munk88/howdo.git
cd howdo
sh deploy/preflight.sh
docker compose up -d --build
docker compose logs --tail=100 web
```

打开 **https://howdo.icu**。首次启动时，Caddy 会自动申请证书，之后自动续期并将 HTTP 跳转到 HTTPS。证书和 ACME 账户存放在 `howdo_caddy_data` 持久卷，重建容器会保留。

默认不需要 `.env`，域名已经配好。不要运行 `docker compose down -v`，它会删除证书持久卷。

构建在 Docker 内完成，VPS 不需要单独安装 Node.js。运行阶段只有一个 Caddy 容器，不需要数据库。

## 后续更新

本地写 Markdown → 提交 GitHub → 在 VPS 更新：

```sh
cd howdo
git pull --ff-only
docker compose up -d --build
```

更新前会先构建新镜像，构建失败不会直接替换已有容器。替换容器时可能有短暂中断；Caddy 的证书存储不变。

GitHub Actions 会构建 Docker 镜像并测试 Caddy、文章、RSS 和 HTTP 404；不需要 SSH 密钥，也不会修改 VPS。正式域名的证书签发仍须在 VPS 上实际验收。每次成功构建还会生成可导入的 Linux amd64 镜像包，适合 Docker Hub 不可达的服务器，见部署文档。

## 本地预览与写作

Node.js 22.13 或以上（建议 Node 22 LTS）：

```sh
npm ci
npm run dev
npm run new -- my-first-post "我的第一篇文章"
```

文章：`src/content/blog/<slug>/index.md`。图片放在同一目录，使用 `![说明](./image.png)`。

本地只有 Docker 时，也可以用 HTTP 查看：

```sh
DOMAIN=http://localhost HTTP_PORT=8080 HTTPS_PORT=8443 docker compose up -d --build
```

访问 `http://localhost:8080`。不要把这组测试环境变量用于正式域名部署。

## 已包含

首页、文章归档、主题、文章目录、关于页、404、手机排版、全文搜索、RSS、Sitemap、canonical、Open Graph 和 JSON-LD。初始 4 篇指南明确标为示例，不代表站主经历，可以替换或删除。

## 文档

- [WRITING.md](WRITING.md)：写文章、插入图片、草稿和发布。
- [DEPLOYMENT.md](DEPLOYMENT.md)：DNS、安全组、Docker 部署、HTTPS 和排障。
- [MIGRATION.md](MIGRATION.md)：备份、恢复和更换 VPS。

站点配置：`src/config.ts` 与 `astro.config.mjs`。静态构建产物在 `dist/`；成品和源码打包命令为 `npm run package`。域名不变时，更换 VPS 不需要修改文章链接。
