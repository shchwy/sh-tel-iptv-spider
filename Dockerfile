# 阶段 1: 编译
FROM golang:1.21-alpine AS builder

# 安装 git，因为 go mod download 某些包需要用到
RUN apk add --no-cache git

WORKDIR /app

# 复制依赖定义文件
COPY go.mod ./
# 注意：如果仓库里有 go.sum，我们也拷贝；如果没有，这一行也不会报错
COPY go.sum* ./

# 关键修正：设置代理，并关闭极其严格的校验 (GOSUMDB=off)
RUN go env -w GOPROXY=https://goproxy.cn,direct && \
    go env -w GOSUMDB=off && \
    go env -w GO111MODULE=on

# 强制清理缓存并下载依赖
# 如果 go mod download 依然失败，尝试执行 go mod tidy 重新生成
RUN go mod download || (go mod tidy && go mod download)

# 复制源码并编译
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -v -o iptv-spider main.go

# 阶段 2: 运行
FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Shanghai
WORKDIR /root/
COPY --from=builder /app/iptv-spider .
ENTRYPOINT ["./iptv-spider"]
