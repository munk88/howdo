# howdo.icu

> 记录每一件「如何做」的事。

基于 Astro 构建的个人博客，Docker 容器化部署，Nginx 反向代理 + 自动 HTTPS。

## 技术栈

| 层 | 技术 | 说明 |
|----|------|------|
| **框架** | Astro 4.x | 静态站点生成器，Markdown → HTML |
| **字体** | Spectral + Inter + JetBrains Mono | Google Fonts |
| **容器** | Docker + Docker Compose | 多阶段构建，环境隔离 |
| **Web 服务器** | Nginx | 静态文件服务 + 反向代理 |
| **HTTPS** | jonasal/nginx-certbot | Let's Encrypt 自动申请续期 |
| **CI/CD** | GitHub Actions | git push 自动构建部署 |

## 架构

```
                    GitHub 仓库
                        │
                        │ git push (main)
                        ▼
                GitHub Actions
                        │
            ┌───────────┴───────────┐
            │  1. docker build      │
            │  2. docker save       │
            │  3. scp → VPS         │
            │  4. ssh: load + up    │
            └───────────────────────┘
                        │
                        ▼
            ┌──── VPS (Docker) ─────┐
            │                       │
            │  ┌─ howdo-nginx ────┐ │
            │  │  Nginx :80/:443  │ │
            │  │  + 自动 HTTPS    │ │
            │  │  + 反向代理      │ │
            │  └────────┬─────────┘ │
            │           │           │
            │  ┌────────▼─────────┐ │
            │  │  howdo-blog      │ │
            │  │  Nginx :80       │ │
            │  │  静态文件        │ │
            │  └──────────────────┘ │
            │                       │
            └───────────────────────┘
                        │
                        ▼
                   howdo.icu
```

## 项目结构

```
howdo-astro/
├── src/
│   ├── content/
│   │   ├── config.ts              # 文章 schema（Zod 校验）
│   │   └── blog/                  # ← 你的文章（.md 文件）
│   ├── layouts/
│   │   └── BaseLayout.astro
│   ├── pages/
│   │   ├── index.astro            # 首页
│   │   ├── archive.astro          # 归档页
│   │   ├── about.astro            # 关于页
│   │   ├── 404.astro
│   │   ├── rss.xml.js             # RSS 订阅
│   │   └── blog/
│   │       └── [...slug].astro    # 文章详情（自动路由）
│   ├── components/
│   │   ├── Header.astro
│   │   └── Footer.astro
│   └── styles/
│       └── global.css
├── nginx/
│   ├── default.conf               # 容器内 Nginx 配置（HTTP）
│   └── nginx-ssl.conf             # 反向代理 Nginx 配置（HTTPS）
├── scripts/
│   └── setup-vps.sh               # VPS 一键部署脚本
├── .github/workflows/
│   └── deploy.yml                 # GitHub Actions
├── Dockerfile                     # 多阶段构建
├── docker-compose.yml             # 容器编排
├── .dockerignore
├── astro.config.mjs
├── package.json
└── README.md
```

## 写新文章

在 `src/content/blog/` 下新建 `.md` 文件：

```markdown
---
title: "文章标题"
description: "一句话摘要"
pubDate: 2026-07-05
tags: ["技术"]
readingTime: 10
---

正文用 Markdown 写，支持所有标准语法。

## 二级标题

> 引用块自动加红色左边线

```js
console.log('代码块自动高亮');
```

1. 有序列表
2. 第二项
```

### Frontmatter 字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `title` | string | ✅ | 标题 |
| `description` | string | ✅ | 摘要 |
| `pubDate` | date | ✅ | 发布日期 `YYYY-MM-DD` |
| `tags` | string[] | ✅ | 标签 |
| `readingTime` | number | ✅ | 阅读时间（分钟） |
| `updatedDate` | date | ❌ | 更新日期 |
| `draft` | boolean | ❌ | 草稿不构建 |

## 本地开发

```bash
# 安装依赖
npm install

# 开发服务器 http://localhost:4321
npm run dev

# 构建生产版本到 dist/
npm run build

# 预览构建产物
npm run preview
```

## Docker 本地测试

```bash
# 构建镜像
docker build -t howdo-blog .

# 运行容器（仅 HTTP，无证书）
docker run -d -p 8080:80 --name howdo-blog howdo-blog

# 访问 http://localhost:8080
```

## 部署流程

### 首次部署

**1. VPS 初始化**（在 VPS 上执行）：

```bash
# 上传部署脚本
scp scripts/setup-vps.sh root@your-vps-ip:/tmp/

# SSH 登录并执行（传入你的 Git 仓库地址）
ssh root@your-vps-ip
bash /tmp/setup-vps.sh https://github.com/你的用户名/howdo-astro.git
```

脚本会自动：
- 安装 Docker + Docker Compose
- 克隆代码到 `/opt/howdo`
- 构建镜像并启动容器
- 申请 Let's Encrypt SSL 证书

**2. DNS 配置**：

```
A     howdo.icu       →  VPS 公网 IP
A     www.howdo.icu   →  VPS 公网 IP
```

**3. 防火墙**：

```bash
ufw allow 80/tcp
ufw allow 443/tcp
```

**4. GitHub Secrets**（仓库 Settings → Secrets and variables → Actions）：

| Secret 名 | 值 |
|-----------|-----|
| `VPS_SSH_KEY` | VPS 的 SSH 私钥（完整内容） |
| `VPS_HOST` | VPS 公网 IP |
| `VPS_USER` | SSH 用户名（如 root） |
| `VPS_DEPLOY_PATH` | `/opt/howdo` |

### 日常发布

```bash
# 写文章
vim src/content/blog/my-new-post.md

# 提交推送
git add .
git commit -m "新文章：XXX"
git push

# GitHub Actions 自动：
# 1. docker build
# 2. docker save → scp 到 VPS
# 3. ssh: docker load + docker compose up
# 4. 30 秒后 howdo.icu 更新
```

## 运维命令

```bash
# 查看容器状态
docker compose ps

# 查看日志
docker compose logs -f
docker compose logs -f nginx      # 只看 Nginx
docker compose logs -f web        # 只看博客

# 重启服务
docker compose restart

# 更新代码后重新部署
git pull
docker compose up -d --build

# 停止所有服务
docker compose down

# 手动续期证书（通常自动完成）
docker compose exec nginx certbot renew
```

## 设计系统

| 变量 | 值 | 用途 |
|------|-----|------|
| `--bg` | `#FBFAF7` | 暖纸背景 |
| `--ink` | `#1A1A1A` | 主文字 |
| `--accent` | `#C0392B` | 印刷红 |
| `--border` | `#E5E1D7` | 分隔线 |
| `--serif` | Spectral | 标题/正文 |
| `--sans` | Inter | 元信息 |
| `--mono` | JetBrains Mono | 代码 |

## License

内容版权归作者所有。
