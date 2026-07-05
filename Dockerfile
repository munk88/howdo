# ============================================
# howdo.icu Dockerfile
# 多阶段构建：Astro 构建 → Nginx 提供静态文件
# ============================================

# ---------- Stage 1: 构建 Astro ----------
FROM node:22-alpine AS builder

WORKDIR /app

# 利用 Docker 缓存：先拷贝依赖文件
COPY package.json package-lock.json* ./
RUN npm ci

# 拷贝源码并构建
COPY . .
RUN npm run build

# ---------- Stage 2: Nginx 提供静态文件 ----------
FROM nginx:alpine

# 拷贝 Nginx 自定义配置
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# 从构建阶段拷贝产物到 Nginx 静态目录
COPY --from=builder /app/dist /usr/share/nginx/html

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
