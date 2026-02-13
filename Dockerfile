# 阶段 1: 编译
FROM golang:1.21-alpine AS builder

# 安装构建必需的工具
RUN apk add --no-cache git gcc musl-dev

WORKDIR /app

# 设置环境变量
RUN go env -w GOPROXY=https://goproxy.cn,direct && \
    go env -w GO111MODULE=on && \
    go env -w GOSUMDB=off

# 1. 复制所有文件
COPY . .

# 2. 核心修正：如果 go.mod 损坏或缺失，我们只初始化不 tidy
# 有时候 tidy 会因为找不到某个小众库而报错，但 build 会自动处理
RUN if [ ! -f go.mod ]; then \
      go mod init github.com/shchwy/sh-tel-iptv-spider; \
    fi

# 3. 直接编译。-v 参数能让我们看到是哪个包下载失败
# 使用 . 编译整个目录，Go 会自动处理依赖
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -v -o iptv-spider .

# 阶段 2: 运行
FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Shanghai
WORKDIR /root/
COPY --from=builder /app/iptv-spider .
# 如果仓库里有 config.yaml.example，拷贝一份作为参考
COPY --from=builder /app/config.yaml.example* ./

ENTRYPOINT ["./iptv-spider"]
