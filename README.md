# 三皮的时光折叠 · Astro 个人博客

一个由 **Markdown 驱动的静态博客**：本地写 `.md` 文章，提交到 GitHub 后**自动渲染、自动部署**到你的 VPS，无需任何后端。

- 站点域名：`https://howdo.icu`
- 技术栈：Astro 5 + Markdown 内容集合 + Docker（Caddy 容器托管） + GitHub Actions 自动部署

---

## 一、本地预览

```bash
npm install        # 首次安装依赖
npm run dev        # 本地开发预览，浏览器打开 http://localhost:4321
npm run build      # 构建静态站（产物在 dist/）
npm run preview    # 本地预览构建产物
```

## 二、写文章（核心日常操作）

1. 在 `src/content/posts/` 目录下**新建一个 `.md` 文件**，文件名就是文章链接（如 `hello-world.md` → `/posts/hello-world/`）；
2. 在文件头部写元信息（frontmatter），正文用 Markdown 写即可：

```markdown
---
title: '文章标题'
description: '一句话摘要（列表页展示）'
date: 2026-09-03
category: 随笔          # 取值：读书 / 技术 / 随笔 / 笔记 / 生活
tags: [标签1, 标签2]
---

正文……用 ## 分小节，会自动生成文章目录。
```

3. 本地 `npm run dev` 检查效果 → 提交推送 → 自动上线。

> 想隐藏某篇文章不发布？在 frontmatter 加 `draft: true` 即可。

## 三、修改站点信息

打开 `src/site.config.ts`，可改：站名、副标题、作者、简介、头像、栏目列表。
站点样式在 `src/styles/global.css`（含明暗主题、栏目配色）。

## 四、部署到你的 VPS（Docker + 自动 HTTPS）

整体流程：**你写文章 → push 到 GitHub → Actions 自动构建 → 部署到 VPS → 域名访问**。

> **部署架构**（适配 VPS 已有主机 Caddy 占用 80/443）：
> 博客容器只在 VPS 内网 `127.0.0.1:8090` 提供 HTTP 静态服务；
> VPS 主机上的 Caddy（负责你其他服务的那台）把 `howdo.icu` 反向代理到该端口并自动签发 HTTPS。
> 已部署上线：`https://howdo.icu`，你的现有服务不受影响。

### 第 1 步：配置 GitHub Secrets（一次性）

GitHub 仓库 → **Settings → Secrets and variables → Actions → New repository secret**，添加三个：

| Secret 名 | 值 |
| --- | --- |
| `VPS_HOST` | `62.234.53.137` |
| `VPS_USER` | `ubuntu` |
| `VPS_SSH_KEY` | 部署私钥全文（`~/.ssh/blog_deploy`，含 BEGIN/END） |

> 若尚未生成部署密钥：`ssh-keygen -t ed25519 -C "blog-deploy" -f ~/.ssh/blog_deploy`，
> 公钥（`.pub`）追加到 VPS 上 `ubuntu` 用户的 `~/.ssh/authorized_keys`。

### 第 2 步：VPS 一次性初始化

SSH 登录 VPS 后运行（装 Docker、建 `/opt/blog`、加入 docker 组）：

```bash
curl -fsSL https://raw.githubusercontent.com/munk88/howdo/main/deploy/setup-vps.sh | bash
```

### 第 3 步：确认域名解析

`howdo.icu` 已加 A 记录 → `62.234.53.137`。主机 Caddy 的 `howdo.icu` 反向代理站点（`/etc/caddy/acli.d/sites/howdo.caddy`）已配置好；若被面板重建，CI 会在下次部署时自动补回。

### 第 4 步：发布

```bash
git add .
git commit -m "update"
git push
```

推送后，GitHub Actions 自动：构建静态站 → 上传到 `/opt/blog` → 启动/更新博客容器。
稍等一两分钟，访问 `https://howdo.icu` 即可看到最新内容。

> 之后每次发布：**写文章 → git push**，其余全自动。

## 五、常见问题

- **GitHub Actions 部署失败？** 检查三个 Secret 是否填写正确、VPS 是否放行了 22 端口、`VPS_SSH_KEY` 私钥与 authorized_keys 公钥是否配对。
- **HTTPS 证书没生效？** 确认域名 A 记录已解析到 VPS 且 80/443 端口已放行，Caddy 会自动重试。
- **博客容器端口？** 博客容器绑定 `127.0.0.1:8090`（仅内网），不占用 80/443，与主机 Caddy 无冲突。
- **文章不显示？** 检查 frontmatter 是否有 `draft: true`，或文件是否在 `src/content/posts/` 下。

## 目录结构

```
astro-blog/
├── src/
│   ├── content/posts/     # 你的 Markdown 文章（写这里）
│   ├── components/        # 头部 / 页脚 / 文章卡片组件
│   ├── layouts/           # 页面布局（含全局脚本）
│   ├── pages/             # 首页 / 文章页 / 归档 / 关于 / RSS
│   ├── styles/global.css  # 全局样式（明暗主题）
│   └── site.config.ts     # 站点信息配置
├── public/                # 静态资源（favicon 等）
├── Dockerfile 相关
├── docker-compose.yml     # VPS 部署编排
├── Caddyfile              # 站点与 HTTPS 配置
├── deploy/setup-vps.sh    # VPS 一次性初始化
└── .github/workflows/     # 自动部署
```
