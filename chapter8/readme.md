使用 Dockerfile 构建镜像

# 8.1 使用 Dockerfile 打包 Git 程序

编写 Dockerfile：

```Dockerfile
FROM ubuntu:latest
LABEL maintainer="dia@allingeek.com"
RUN apt-get update && apt-get install -y git
ENTRYPOINT ["git"]
```

打包镜像：在包含 Dockerfile 同一目录中执行下面的命令：

````

观察最近创建的镜像：
```shell
docker image ls
````

使用新镜像执行 Git 命令：

```shell
docker container run --rm ubuntu-git:auto version
```

输出

```shell
[+] Building 3.9s (4/5)
[+] Building 122.2s (6/6) FINISHED
 => [internal] load build definition from Dockerfile                                                          0.0s
 => => transferring dockerfile: 162B                                                                          0.0s
 => [internal] load .dockerignore                                                                             0.0s
 => => transferring context: 2B                                                                               0.0s
 => [internal] load metadata for docker.io/library/ubuntu:latest                                              0.0s
 => [1/2] FROM docker.io/library/ubuntu:latest                                                                0.0s
 => [2/2] RUN apt-get update && apt-get install -y git                                                      121.8s
 => exporting to image                                                                                        0.3s
 => => exporting layers                                                                                       0.3s
 => => writing image sha256:4287df33d5f46f247e85302697f462ef713c03548d5c26809ac89e8c637412b7                  0.0s
 => => naming to docker.io/library/ubuntu-git:auto

```

# 8.2 Dockerfile 入门

深入了解：https://docs.docker.com/reference/dockerfile/

每天 Dockerfile 指令都会导致一个新的层级被创建，应该尽可能合并指令。·

创建 .dockerignore 文件，定义不被复制到镜像中的文件

```.dockerignore
mailer-base.df
mailer-logging.df
mailer-live.df
```

mailer-base.df

```dockerfile
FROM debian:buster-20190910
LABEL maintainer="dia@allingeek.com"
RUN groupadd -r -g 2000 example && \
    useradd -rM -g example -u 2200 example
ENV APPROOT="/app" \
    APP="mailer.sh" \
    VERSION="0.6"
LABEL base.name="Mailer Archetype" \
    base.version ="${VERSION}"
WORKDIR $APPROOT
ADD . $APPROOT
ENTRYPOINT ["/app/mailer.sh"]
EXPOSE 33333
```

根据上述的 .df 文件构建镜像：

```shell
docker build -t dockerinaction/mailer.sh:0.6 -f mailer-base.df .
```

Dockerfile 命名：默认名称是 Dockerfile, 也可以使用扩展名，这样就可以在单个目录中定义多个镜像的构建文件

How Dockerfile Layers/Caching Work:https://www.youtube.com/watch?v=RP-z4dqRTZA&ab_channel=BenjaminPorter

第一个版本实现：mailer-logging.df

```dockerfile
# 指定基础镜像
FROM dockerinaction/mailer-base:0.6
RUN apt-get update && \
    apt-get install -y netcat

# 拷贝 log-impl 目录到镜像中的${APPROOT}目录
COPY ["./log-impl", "${APPROOT}"]

# 修改文件权限：（COPY指令在复制完后，文件的所有权限会被重置为 root）
RUN chmod a+x ${APPROOT}/${APP} && \
    chown example:example /var/log

# 设置镜像的用户和用户组
USER example:example

# 为镜像的 /var/log 目录创建一个卷，
VOLUME ["/var/log"]
# 设执行 mailer 应用的默认命令
CMD ["/var/log/mailer.log"]
```

对应的 mailer.sh 文件

```sh
#!/bin/bash
# 该脚本的功能：在端口3333上启动一个邮件守护程序，将收到的每条消息写到指定的文件中
printf "Loggin Mailer has started.\n"
while true
    MESSAGE=${nc -l -p 33333}
    printf "[Message]:%s \n" "$MESSAGE" > $1
    sleep 1
```

构建镜像：

```sh
docker image build -t dockerinaction/mailer-logging -f mailer-logging.df .
```

运行容器：

```sh
docker run -d --name loggin-mailer dockerinaction/mailer-logging
```

第二版实现：mailer-live.df

```dockerfile
FROM dockerinaction/mailer-base:0.6
ADD ["./live-impl", "${APPROOT}"]
RUN apt-get update && \
    apt-get install -y curl netcat python && \
    python get-pip.py && \
    pip install awscli && \
    rm get-pip.py && \
    chmod a+x "${APPROOT}/${APP}"
USER example:example
CMD ["mailer@dockerinaction.com", "pager@dockerinaction.com"]
```

对应的程序：mailer.sh

```sh
#!/bin/bash
# 该脚本的功能：在端口33333上启动一个邮件守护程序，将收到的每条消息发送到指定的邮箱中
printf "Live Mailer has started.\n"
while true
do
    MESSAGE=${nc -l -p 33333}
    aws ses send-email --from $1 \
    --destination {\"ToAddress\":[\"$2\"]} \
    --message "{\"Subject\"={\"Data\":\"Mailer Alert\"},Body={\"Text\":{\"Data\":\"$MESSAGE\"}}}"
```

编译镜像和运行容器

```sh
docker image build -t dockerinaction/mailer-live -f mailer-live.df

docker run -d --name live-mailer dockerinaction/mailer-live
```

# 8.3 注入下游构建时行为

```df
ONBUILD COPY [".", "/var/myapp"]
ONBUILD RUN go build /var/myapp
```

创建上游镜像 df 文件：base.df

```dockerfile
FROM busybox:latest
WORKDIR /app
RUN touch /app/base-evidence
ONBUILD RUN ls -al /app
```

```df
docker image build -t dockerinaction/ch8_onbuild -f base.df
```

创建下游的镜像

```df
FROM dockerinaction/ch8_onbuild
RUN touch downstream-evidence
RUN ls -al
```

```df
docker image build -u dockerinaction/ch8_onbuild_down -f downstream.df
```

# 8.4

```Dockerfile
FROM debian:buster-20190910
ARG VERSION=unknown
LABEL maintainer="dia@allingeek.com"
RUN groupadd -r -g 2200 example && \
useradd -rM -g example -u 2200 example
ENV APPROOT="/app" \
APP="mailer.sh" \
VERSION="${VERSION}"
LABEL base.name="Mailer Archetype" \
base.version="${VERSION}"
WORKDIR $APPROOT
ADD . $APPROOT
ENTRYPOINT ["/app/mailer.sh"]
EXPOSE 33333
```

传递 version 参数：

```sh
version=0.6
docker image build -t dockerinaction/mailer-base:${version} \
	-f mailer-base.df \
	--build-arg VERSION=${version}
```

检查 version 参数：

```sh
docker image inspect --format '{{ json .Config.Labels }}' \
dockerinaction/mailer-base:0.6
```

```json
{
  "base.name": "Mailer Archetype",
  "base.version": "0.6",
  "maintainer": "dia@allingeek.com"
}
```

多阶段构建：多阶段 dockerfile

http-client.df

```df
#################################################
# Define a Builder stage and build app inside it
FROM golang:1-alpine as builder

# Install CA Certificates
RUN apk update && apk add ca-certificates

# Copy source into Builder
ENV HTTP_CLIENT_SRC=$GOPATH/src/dia/http-client/
COPY . $HTTP_CLIENT_SRC
WORKDIR $HTTP_CLIENT_SRC

# Build HTTP Client
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
go build -v -o /go/bin/http-client

#################################################
# Define a stage to build a runtime image.
FROM scratch as runtime
ENV PATH="/bin"

# Copy CA certificates and application binary from builder stage
COPY --from=builder \
/etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /go/bin/http-client /http-client
ENTRYPOINT ["/http-client"]
```

# 8.5 使用启动脚本和多进程容器

```sh
#!/bin/bash
set -e
if [ -n "$WEB_PORT_80_TCP" ]; then
	if [ -z "$WEB_HOST" ]; then
		WEB_HOST='web'
	else
		echo >&2 '[WARN]: Linked container, "web" overridden by $WEB_HOST.'
		echo >&2 "===> Connecting to WEB_HOST ($WEB_HOST)"
	fi
fi
if [ -z "$WEB_HOST" ]; then
	echo >&2 '[ERROR]: specify container to link; "web" or WEB_HOST env var'
	exit 1
fi
exec "$@" # run the default commandexec "$@" # run the default command
```

NGINX Web 服务器健康检查命令
```dockerfile
FROM nginx:1.13-alpine

HEALTHCHECK --interval=5s --retries=2 \
    CMD nc -vz -w 2 localhost  80 || exit 1
```

```sh
docker image build -t dockerinaction/healthcheck .
docker container run --name healthcheck_ex -d cockerinaction/heathcheck
```

在启动容器时指定健康检查命令：
```sh
docker container run --name=heathcheck_ex -d \
	--heath-cmd='nc -vz -w 2 localhost 80 || exit 1' \
	nginx:1.13-alpine
```

# 8.6 构建加固的应用程序镜像

镜像标识符

- 包括摘要（Digest）成分的镜像ID：内容可寻址惊醒标识符（CAIID）,可防止镜像在你不知情的情况下被更改。

- 限制镜像的攻击面：
    - 用户权限
    - 减少SUID和SGID的权限。


```dockerfile
FROM ubuntu:latest
RUN adduser --system -no-create-home --disabled-password --disabled-login \
    --shell /bin/sh example USER example
CMD printf "Container running as:%s\n" $(id -u -n) && \
    printf "Effectively running whoami as: %s\n" $(whoami)
```

执行下面命令：
```sh 
docker image build -t dockerinaction/ch8_whoami
docker run dockerinaction/ch8_whoami
```

输出结果:
```text
Container running as: example
Effectively runnig whoami as: root
```
