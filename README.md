# howdo.icu

> 记录每一件「如何做」的事。

基于 Astro 构建的个人博客，Docker 容器化部署，Webhook 自动更新（无 SSH 密钥）。

## 技术栈

| 层 | 技术 | 说明 |
|----|------|------|
| **框架** | Astro 4.x | 静态站点生成器 |
| **容器** | Docker + Docker Compose | 多阶段构建 |
| **Web 服务器** | Nginx | 静态文件 + 反向代理 + HTTPS |
| **自动部署** | GitHub Webhook + 本地接收器 | 无 SSH 密钥，最安全 |
| **HTTPS** | jonasal/nginx-certbot | Let's Encrypt 自动续期 |

## 架构（Webhook 方案）

```
你的电脑                GitHub                 VPS
   │                       │                    │
   │ git push              │                    │
   ├──────────────────────►│                    │
   │                       │                    │
   │              GitHub Actions                 │
   │              构建 Docker 镜像                │
   │              保存为 artifact                │
   │                       │                    │
   │                       │ webhook (POST)     │
   │                       ├───https://howdo.icu/webhook──►
   │                       │                    │
   │                       │         webhook-server.py 验证签名
   │                       │                    │
   │                       │         git pull + docker compose up
   │                       │                    │
   │                       │         howdo.icu 更新 ◄─┘
   │                       │                    │
```

**关键：VPS 不需要向 GitHub 开放任何端口，GitHub 不需要 SSH 密钥。**

## 项目结构

```
howdo-astro/
├── src/
│   ├── content/blog/          # ← 写文章的地方（.md 文件）
│   ├── layouts/
│   ├── pages/                 # 页面路由
│   ├── components/
│   └── styles/global.css
├── scripts/
│   ├── webhook-server.py      # Webhook 接收器
│   ├── howdo-webhook.service  # systemd 服务
│   ├── setup-webhook.sh       # 一键安装
│   └── setup-vps.sh           # 首次 VPS 初始化
├── nginx/
│   ├── default.conf           # 容器内 Nginx
│   └── nginx-ssl.conf         # HTTPS + Webhook 代理
├── .github/workflows/
│   └── deploy.yml             # 构建 Docker 镜像
├── Dockerfile
├── docker-compose.yml
└── package.json
```

## 写新文章

```bash
# 1. 写文章
vim src/content/blog/my-new-post.md

# 2. 推送
git add . && git commit -m "新文章" && git push

# 3. 30 秒后 howdo.icu 自动更新
```

### Frontmatter 字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `title` | string | ✅ | 标题 |
| `description` | string | ✅ | 摘要 |
| `pubDate` | date | ✅ | `YYYY-MM-DD` |
| `tags` | string[] | ✅ | 标签 |
| `readingTime` | number | ✅ | 阅读时间（分钟） |
| `draft` | boolean | ❌ | 草稿不发布 |

## 首次部署

### 1. VPS 初始化

```bash
# 上传代码到 VPS
scp -r howdo-astro root@VPS_IP:/opt/howdo
ssh root@VPS_IP

# 安装 Docker + 启动博客
cd /opt/howdo
bash scripts/setup-vps.sh
```

### 2. 配置 Webhook

```bash
# 在 VPS 上执行
bash scripts/setup-webhook.sh
```

脚本会输出一个 **Webhook Secret**，记下来。

### 3. 在 GitHub 添加 Webhook

打开 https://github.com/munk88/howdo/settings/hooks/new

| 字段 | 值 |
|------|-----|
| Payload URL | `https://howdo.icu/webhook` |
| Content type | `application/json` |
| Secret | 上一步输出的 Secret |
| Events | Just the push event |

### 4. 完成

每次 `git push` 后，GitHub 自动发 webhook，VPS 自动构建部署。

## 安全机制

| 层 | 机制 |
|----|------|
| 传输 | HTTPS 端到端加密 |
| 签名 | HMAC-SHA256 验证，伪造请求被拒绝 |
| 事件 | 只处理 main 分支的 push 事件 |
| 隔离 | webhook-server 以 systemd 服务运行，资源受限 |
| 审计 | 所有部署记录写入 /var/log/howdo-webhook.log |
| 无密钥 | VPS 不存放任何 GitHub 凭证，GitHub 不存放 SSH 密钥 |

## 运维命令

```bash
# 查看 webhook 服务状态
systemctl status howdo-webhook

# 查看部署日志
tail -f /var/log/howdo-webhook.log

# 重启 webhook 服务
systemctl restart howdo-webhook

# 查看 Nginx 日志
docker compose logs -f nginx

# 手动重新部署
cd /opt/howdo && git pull && docker compose up -d --build

# 测试 webhook 健康检查
curl https://howdo.icu/webhook/health
```

## License

内容版权归作者所有。
