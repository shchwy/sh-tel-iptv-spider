# 阶段1：构建依赖（多阶段构建，减小最终镜像体积）
FROM node:18-alpine AS builder
WORKDIR /app
# 先拷贝依赖文件，利用镜像缓存（修改代码不重新装依赖）
COPY package.json package-lock.json ./
# 安装依赖（添加--registry解决npm源问题，alpine需装git等依赖）
RUN npm config set registry https://registry.npmmirror.com \
    && npm install --production --ignore-scripts
# 拷贝源码
COPY . .
# 构建项目（如前端vue/react打包，后端nest/express无需此步）
RUN npm run build

# 阶段2：运行阶段（精简基础镜像）
FROM node:18-alpine
WORKDIR /app
# 解决alpine时区问题（可选）
RUN apk add --no-cache tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone
# 非root用户运行（提升安全性）
RUN addgroup -g 1001 -S nodejs \
    && adduser -S appuser -u 1001
# 从构建阶段拷贝依赖和构建产物
COPY --from=builder --chown=appuser:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:nodejs /app/dist ./dist  # 前端/后端构建产物目录
COPY --from=builder --chown=appuser:nodejs /app/package.json ./

# 暴露端口（根据项目调整）
EXPOSE 3000
# 切换非root用户
USER appuser
# 启动命令（根据项目调整，如node dist/server.js）
CMD ["node", "dist/index.js"]
