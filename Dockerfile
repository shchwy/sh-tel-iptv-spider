# 阶段 1: 编译
FROM golang:1.21-alpine AS builder

# 安装构建必需工具
RUN apk add --no-cache git gcc musl-dev

WORKDIR /app

# 设置环境变量
RUN go env -w GOPROXY=https://goproxy.cn,direct && \
    go env -w GO111MODULE=on && \
    go env -w GOSUMDB=off

# 1. 复制所有文件
COPY . .

# 2. 核心修正：强制重置 mod 并修正代码中的引用路径
# 很多报错是因为代码里写的是 'import "sh-tel-iptv-spider/model"' 但 mod 名不一致
RUN rm -f go.mod go.sum || true && \
    go mod init github.com/shchwy/sh-tel-iptv-spider && \
    # 这一行会将代码中所有错误的包引用指向当前 mod 名
    grep -rl "sh-tel-iptv-spider/" . | xargs sed -i 's|sh-tel-iptv-spider/|github.com/shchwy/sh-tel-iptv-spider/|g' || true && \
    go mod tidy

# 3. 执行编译（指定输出为 iptv-spider）
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -v -o iptv-spider main.go

# 阶段 2: 运行
FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Shanghai
WORKDIR /root/
COPY --from=builder /app/iptv-spider .
# 即使本地没有也确保有一个配置文件模板
COPY --from=builder /app/config.yaml* ./

ENTRYPOINT ["./iptv-spider"]
