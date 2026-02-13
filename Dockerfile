# 阶段 1: 编译环境
FROM golang:1.21-alpine AS builder
RUN apk add --no-cache git
WORKDIR /app

# 利用 Docker 缓存机制，先下载依赖
COPY go.mod go.sum ./
RUN go env -w GOPROXY=https://goproxy.cn,direct
RUN go mod download

# 复制源码并编译
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o iptv-spider main.go

# 阶段 2: 运行环境
FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Shanghai
WORKDIR /root/

# 从编译阶段拷贝文件
COPY --from=builder /app/iptv-spider .
# 拷贝示例配置文件（作为模板）
COPY --from=builder /app/config.yaml.example ./config.yaml

ENTRYPOINT ["./iptv-spider"]
