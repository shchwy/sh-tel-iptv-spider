# 阶段 1: 编译
FROM golang:1.21-alpine AS builder

# 关键：安装构建依赖
RUN apk add --no-cache git gcc musl-dev

WORKDIR /app

# 1. 先复制所有源码（确保 go.mod init 能找到代码文件）
COPY . .

# 2. 设置代理并确保环境清洁
RUN go env -w GOPROXY=https://goproxy.cn,direct && \
    go env -w GO111MODULE=on

# 3. 如果没有 go.mod，则初始化；否则同步依赖
RUN if [ ! -f go.mod ]; then \
      go mod init iptv-spider; \
    fi && \
    go mod tidy

# 4. 执行编译
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -v -o iptv-spider main.go

# 阶段 2: 运行
FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Shanghai
WORKDIR /root/
COPY --from=builder /app/iptv-spider .
COPY --from=builder /app/config.yaml .

ENTRYPOINT ["./iptv-spider"]
