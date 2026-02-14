# 阶段1：构建Go二进制文件（多阶段构建，减小最终镜像体积）
FROM golang:1.24.2-alpine AS builder

# 设置环境变量（解决Go模块下载、编译跨平台问题）
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64 \
    GOPROXY=https://goproxy.cn,direct

# 安装构建依赖（alpine基础镜像缺少git，拉取go mod依赖需要）
RUN apk add --no-cache git

# 设置工作目录
WORKDIR /app

# 先拷贝go.mod/go.sum，利用镜像缓存（修改代码不重新下载依赖）
COPY go.mod go.sum ./

# 下载所有依赖（包括间接依赖）
RUN go mod download

# 拷贝项目所有源码
COPY . .

# 编译二进制文件（-ldflags精简体积，指定输出路径）
RUN go build -ldflags="-s -w" -o iptv-spider-sh ./

# 阶段2：运行阶段（极简镜像，仅保留二进制文件）
FROM alpine:3.20

# 安装基础依赖（解决时区、CA证书问题，MySQL/HTTPS请求需要CA证书）
RUN apk add --no-cache tzdata ca-certificates \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone


# 设置工作目录
WORKDIR /app

# 从构建阶段拷贝二进制文件（仅拷贝编译产物，减小镜像体积）
COPY --from=builder /app/iptv-spider-sh ./

# 赋予执行权限
RUN chmod +x /app/iptv-spider-sh


# 暴露端口（根据你的iris服务端口调整，默认假设是8080）
EXPOSE 8080

# 启动命令（执行Go二进制文件）
CMD ["/app/iptv-spider-sh"]
