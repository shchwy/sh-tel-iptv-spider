# 阶段 1: 编译
FROM golang:1.21-alpine AS builder

# 安装所有可能的构建工具，避免因为缺少 git 或 gcc 导致 go mod 崩溃
RUN apk add --no-cache git gcc musl-dev

WORKDIR /app

# 设置最强兼容性的环境变量
RUN go env -w GOPROXY=https://goproxy.cn,direct && \
    go env -w GO111MODULE=on && \
    go env -w GOSUMDB=off

# 1. 复制所有文件（先不依赖 go.mod）
COPY . .

# 2. 强制重新生成依赖树
# 即使原有的 go.mod 有错，我们也直接删掉重新初始化
RUN rm -f go.mod go.sum || true && \
    go mod init github.com/shchwy/sh-tel-iptv-spider && \
    go mod tidy

# 3. 直接编译。如果 main.go 在根目录，用下面的命令
# -v 可以让我们在 GitHub Actions 日志里看到具体的编译过程
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -v -o iptv-spider main.go

# 阶段 2: 运行
FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Shanghai
WORKDIR /root/
COPY --from=builder /app/iptv-spider .
# 运行阶段不需要源码，只保留二进制文件
ENTRYPOINT ["./iptv-spider"]
