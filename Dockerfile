# ============ 构建阶段（在 GitHub Actions 的云端跑，NAS 不承担编译）============
FROM node:24-bookworm-slim AS builder
WORKDIR /app

# 跳过 husky 的 git hook 安装（容器里没有 .git，装了会报错）
ENV HUSKY=0

# 先只拷贝依赖清单，利用 Docker 层缓存：源码变了也不会重装依赖
COPY package*.json ./
RUN npm ci

# 拷贝全部源码并构建前端
COPY . .
# 这个项目游戏数据量大，给 Node 提高堆内存上限，避免构建时 OOM
RUN NODE_OPTIONS=--max-old-space-size=4096 npm run build:app

# ============ 运行阶段（NAS 上只跑这个轻量 nginx）============
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
# 注意：前端产物在 dist/client，不是 dist
COPY --from=builder /app/dist/client /usr/share/nginx/html
EXPOSE 80
