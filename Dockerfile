# 阶段 1: 编译
FROM golang:1.21-alpine AS builder

# 安装 git，部分 Go 插件下载需要它
RUN apk add --no-cache git

WORKDIR /app

# 先复制 mod 文件（利用 Docker 缓存层）
COPY go.mod ./
# 如果仓库里有 go.sum 就取消下面一行的注释
COPY go.sum ./ 

RUN go env -w GOPROXY=https://goproxy.cn,direct
# 如果没有 go.mod，这一步会报错，我们加个逻辑判断
RUN if [ -f go.mod ]; then go mod download; else go mod init iptv-spider && go mod tidy; fi

# 复制其余源码
COPY . .

# 执行编译（增加 -v 参数查看详细报错过程）
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -v -o iptv-spider main.go

# 阶段 2: 运行
FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Shanghai
WORKDIR /root/
COPY --from=builder /app/iptv-spider .
COPY --from=builder /app/config.yaml .

ENTRYPOINT ["./iptv-spider"]
