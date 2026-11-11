# syntax=docker/dockerfile:1
FROM node:22-alpine AS build
WORKDIR /app
ENV ASTRO_TELEMETRY_DISABLED=1
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npm run build && npm run check:site

FROM caddy:2-alpine AS runtime
ENV DOMAIN=howdo.icu
COPY deploy/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/dist /srv
EXPOSE 80/tcp 443/tcp 443/udp
