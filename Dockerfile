# 阶段 1: 编译
FROM golang:1.21-alpine AS builder

# 安装必要工具
RUN apk add --no-cache git gcc musl-dev

WORKDIR /app

# 1. 复制所有源码
COPY . .

# 2. 设置 Go 环境变量
RUN go env -w GOPROXY=https://goproxy.cn,direct && \
    go env -w GO111MODULE=on && \
    go env -w GOSUMDB=off

# 3. 核心修正逻辑：强制删除旧 mod 并根据代码目录重新构建
# 这里不使用 iptv-spider 这个假名字，而是尝试匹配原作者可能使用的路径
RUN rm -f go.mod go.sum && \
    go mod init github.com/denymz/sh-tel-iptv-spider && \
    go mod tidy

# 4. 执行编译
# 使用 -o 指定输出，同时确保 main.go 在当前路径
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -v -o iptv-spider .

# 阶段 2: 运行
FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Shanghai
WORKDIR /root/
COPY --from=builder /app/iptv-spider .
# 即使本地没有，也创建一个空的以防万一
RUN touch config.yaml
COPY --from=builder /app/config.yaml* ./

ENTRYPOINT ["./iptv-spider"]
