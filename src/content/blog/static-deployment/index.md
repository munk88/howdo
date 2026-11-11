---
title: "把博客装进 Docker，HTTPS 交给 Caddy"
description: "一次构建得到完整网站，文章、图片与自动 HTTPS 一起迁移。"
date: 2026-11-08
tags: [工具与方法, 独立博客]
example: true
---

静态博客的核心产物是一份普通文件目录。Docker 把构建环境和运行环境整理在一起，换一台服务器后可以使用同样的配置。

## 两个阶段，各自做一件事

Dockerfile 的构建阶段使用 Node.js，安装锁定版本的依赖，并将 Markdown 和模板生成静态网页。

运行阶段使用 Caddy 镜像，只包含网页产物和 Web 服务配置，不需要数据库，也不需要在 VPS 上单独安装 Node.js。

```text
Markdown + 图片 + 页面模板
           ↓ Node 构建
          dist/
           ↓ 放入镜像
     Caddy + 自动 HTTPS
```

## 先确认域名和端口

域名的 A 记录需要指向 VPS 的公网 IPv4。如果配置了 AAAA，它也必须指向可达的正确服务器。

Caddy 默认通过公网 80/443 端口处理访问和证书验证。云安全组与系统防火墙都需要允许 TCP 80、443。已有服务占用了端口时，先确认共用入口的方案。

## 一条命令启动

在已经安装 Docker Engine、Compose 插件和 Git 的服务器上：

```sh
git clone https://github.com/munk88/howdo.git
cd howdo
sh deploy/preflight.sh
docker compose up -d --build
```

预检脚本只显示系统、Docker、端口和域名解析，不会安装软件或修改防火墙。

## HTTPS 不需要手动续期

Caddy 根据配置中的 `howdo.icu` 自动申请证书，并负责后续续期和 HTTP 跳转。

证书与 ACME 账户保存在持久卷 `howdo_caddy_data`。重建容器时保留这个卷，就能保留已有证书。

```sh
docker compose logs --tail=100 web
curl -I https://howdo.icu
```

容器启动成功不等于证书签发成功。应当看到客户端正常信任的 HTTPS 响应，再检查文章、图片和订阅。

## 写文章之后怎样更新

本地编辑 Markdown，提交到 GitHub 后，在 VPS 上运行：

```sh
git pull --ff-only
docker compose up -d --build
```

GitHub Actions 会检查 Docker 构建与 HTTP 服务，不自动登录服务器。正式域名的证书需要在实际 VPS 上验收。

## 迁移时带走什么

保存源码、文章和图片；额外保存 Caddy 证书卷。证书备份含私钥，应放在私有位置，不要上传公开仓库。

新服务器准备好后，用相同配置启动，切换域名解析，并检查 HTTPS、文章链接和真实 HTTP 404。

如果域名和文章路径保持不变，旧链接就可以继续使用。具体操作见仓库中的 `DEPLOYMENT.md` 与 `MIGRATION.md`。
