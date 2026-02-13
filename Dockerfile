# 阶段 1: 编译
FROM golang:1.21-alpine AS builder

# 安装构建必需品
RUN apk add --no-cache git gcc musl-dev

WORKDIR /app

# 1. 设置环境变量，关闭严格校验
RUN go env -w GOPROXY=https://goproxy.cn,direct && \
    go env -w GO111MODULE=on && \
    go env -w GOSUMDB=off

# 2. 复制所有文件
COPY . .

# 3. 核心策略：强制初始化并手动拉取核心依赖
# 该项目主要依赖 mysql 驱动和 yaml 解析器
RUN rm -f go.mod go.sum || true && \
    go mod init github.com/denymz/sh-tel-iptv-spider && \
    go get github.com/go-sql-driver/mysql && \
    go get gopkg.in/yaml.v2 && \
    go mod tidy || true

# 4. 执行编译（改用直接指定文件名，绕过包名解析）
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -v -o iptv-spider main.go

# 阶段 2: 运行
FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Shanghai
WORKDIR /root/
COPY --from=builder /app/iptv-spider .
COPY --from=builder /app/config.yaml* ./
RUN touch config.yaml

ENTRYPOINT ["./iptv-spider"]
