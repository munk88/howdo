# howdo.icu

Astro + Markdown 静态博客。**在电脑上构建网页，直接上传 VPS；Caddy 容器读取宿主机目录并管理 HTTPS。日常更新文章不重启容器。**

网站：<https://howdo.icu/>。源码备份：<https://github.com/munk88/howdo>。

## 日常写作与发布

用户把文章和图片交给当前博客工作目录中的助手，助手整理 Markdown、构建检查、直接上传 VPS 并验收。明确要求草稿时不发布。

```sh
npm ci
npm run dev
npm run new -- my-first-post "我的第一篇文章"
```

文章：`src/content/blog/<slug>/index.md`。图片放在同一目录，使用相对路径。

发布脚本在使用者自己的电脑上执行，通过本地 SSH 密钥连接 VPS：

```sh
npm run publish:site -- --host <VPS地址> --key <本地密钥路径> --known-hosts <已核实的known_hosts文件>
```

脚本会构建和检查网站、上传完整版本、切换 `site/current`、检查 HTTPS 与版本标记；服务器端检查失败时恢复上一版。不执行 Docker 重建或重启，也不把密钥发送到 GitHub。

## 运行结构

```text
电脑：Markdown + 图片 → Astro 构建 → dist/
                                  ↓ SSH 上传
VPS：/opt/howdo/site/releases/<版本>/
     /opt/howdo/site/current → releases/<版本>
                 ↓ 父目录只读挂载为 /srv
Docker：Caddy 从 /srv/current 提供网页，自动 HTTPS
```

`howdo_caddy_data` 和 `howdo_caddy_config` 持久保存证书和 Caddy 状态。只有改动容器参数、升级 Caddy 等运维操作才需要更新容器。

当前 VPS 到 Docker Hub 的连接曾超时，所以切换时复用已有 Caddy 运行镜像，通过服务器 `.env` 中的 `CADDY_IMAGE` 指定。网页目录和 Caddyfile 都由宿主机只读挂载，镜像内旧网页不会被使用。新的、网络正常的 VPS 可以直接使用官方 `caddy:2-alpine`。

## GitHub 的用途

GitHub 保存源码，Actions 仅做静态构建和检查、保留静态产物，不连接 VPS、不保存服务器部署密钥。网站发布通过上面的本地脚本完成。

## 文档

- [WRITING.md](WRITING.md)：写文章与草稿。
- [DEPLOYMENT.md](DEPLOYMENT.md)：部署结构、直接上传、回退和常用操作。
- [MIGRATION.md](MIGRATION.md)：备份、恢复与迁移。

初始示例文章可替换或删除，不代表站主的个人经历。
