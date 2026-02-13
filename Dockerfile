# 阶段 1: 编译
FROM golang:1.21-alpine AS builder
WORKDIR /app
# 复制源码
COPY . .
# 设置代理（国内环境编译更快）并编译
RUN go env -w GOPROXY=https://goproxy.cn,direct && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o iptv-spider main.go

# 阶段 2: 运行
FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Shanghai
WORKDIR /root/
# 从编译阶段拷贝二进制文件
COPY --from=builder /app/iptv-spider .
# 拷贝配置文件
COPY --from=builder /app/config.yaml .

# 启动命令
ENTRYPOINT ["./iptv-spider"]
