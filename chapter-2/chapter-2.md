目的：使用 Docker 并安装 Web 服务器。

什么是镜像？运行软件所需文件和指令的集合，包含计算机运行软件的一切。可以理解为用于在世界各地运输货物的集装箱。


## 1.创建和启动新容器

安装并启动一个在运行的 NGINX 软件,容器唯一标识：
```shell
docker run --detach \
--name web nginx:latest
```

--detach 表示分离式容器，会创建守护进程或者服务，让程序在后台运行，

返回:
```shell
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
3ae0c06b4d3a: Pull complete 
efe5035ea617: Pull complete 
a9b1bd25c37b: Pull complete 
f853dda6947e: Pull complete 
38f44e054f7b: Pull complete 
ed88a19ddb46: Pull complete 
495e6abbed48: Pull complete 
Digest: sha256:08bc36ad52474e528cc1ea3426b5e3f4bad8a130318e3140d6cfe29c8892c7ef
Status: Downloaded newer image for nginx:latest
```

## 启动邮件进程

```shell
docker run --detach \
--name mailer \
dockerinaction/ch2_mailer
```

注意：此程序运行的平台架构是 linux/amd64，不是 linux/arm64/v8
```shell
Unable to find image 'dockerinaction/ch2_mailer:latest' locally
latest: Pulling from dockerinaction/ch2_mailer
Image docker.io/dockerinaction/ch2_mailer:latest uses outdated schema1 manifest format. Please upgrade to a schema2 image for better future compatibility. More information at https://docs.docker.com/registry/spec/deprecated-schema-v1/
a3ed95caeb02: Pull complete 
1db09adb5ddd: Pull complete 
fd22002b688a: Pull complete 
b50bdc71da50: Pull complete 
290aad86b00b: Pull complete 
Digest: sha256:a6937a6871ecf9d96d93ae77863d07efb5f35d1523d67590f5be43e9c5f8c9dc
Status: Downloaded newer image for dockerinaction/ch2_mailer:latest
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
de55d4f7aea840c3a638bd7ccfb480a2546100eee8e6d54c8e40cb424224aa4e
```

## 2.运行交互式容器

启动一个精简 linux 工具箱，用于快速测试验证。
```shell
docker run --interactive --tty \
--link web:web \
--name web_test \
busybox /bin/sh
```
--interactive 告诉 Docker，即时没有连接中断，也要将容器的标准输入流（stdin）保持为打开状态。
--tty 告诉 Docker 为容器分配虚拟中断，允许用户将信号传递给容器。
--link  


```shell
wget -o - http://web:80
```

启动监视器代理程序
```shell
docker run --interactive --tty \
--name agent \
--link web:insideweb \
--link mailer:insidemailer \
dockerinaction/ch2_agent
```

离开监视器代理程序，并保持其继续执行
```shell
# 先按住 ctrl 键，再按 P 键，再按 Q 键
ctrl -> P -> Q
```


## 查看容器信息

```shell
# 查看正在运行的容器
docker ps
# 重启容器
docker restart {容器名}
# 停止容器，用于命令容器中进程编号为1的程序停止。
docker stop {容器名}
# 查看日志
docker logs {容器名}

```

```shell
docker restart web
docker restart mailer
docker restart agent

```

```shell
docker logs web
# 输出运行日志
172.17.0.4 - - [10/Jul/2023:00:02:00 +0000] "GET / HTTP/1.0" 200 615 "-" "-" "-"
172.17.0.4 - - [10/Jul/2023:00:02:01 +0000] "GET / HTTP/1.0" 200 615 "-" "-" "-"
172.17.0.4 - - [10/Jul/2023:00:02:02 +0000] "GET / HTTP/1.0" 200 615 "-" "-" "-"
```

```shell
# 持续观察日志情况 --follow
docker logs mailer --follow
docker logs agent  --follow
```

停止 WEB 服务器
```shell
docker stop web
```

查看 mailer 日志，已发送邮件通知
```shell
docker logs mailer
```

输出
```shell
CH2 Example Mailer has started.
Sending email: To: admin@work  Message: The service is down!
```

## 3.容器间的网络连接

如何识别容器？
- 容器名称 NAME：便于人记忆。
- 容器ID CONTAINER ID：唯一标识符，便于程序使用。

创建一个名为 webid 的容器
```shell
docker run --detach --name webid nginx
# 该命令返回容器id:2bf6e658cd40ec309ae8f0d4e2e2bd5c2f784e8366433c20631c7d3af5601479
```

在容器中执行 `echo hello`
```shell
docker exec webid echo hello
docker exec 2bf6e658cd40e echo hello
```

```shell
MAILER_CID=$(docker run --detach dockerinaction/ch2_mailer)

WEB_CID=$(docker run --detach nginx)

AGENT_CID=$(docker run --detach \
--link $WEB_CID:insideweb \
--link $MAILER_CID:insidemailer \
dockerinaction/ch2_agent
)
```

查看正在运行的容器: docker ps 
```shell
CONTAINER ID   IMAGE                       COMMAND                  CREATED          STATUS          PORTS                                   NAMES
57492f87e70e   dockerinaction/ch2_agent    "/watcher/watcher.sh"    11 minutes ago   Up 11 minutes                                           intelligent_sanderson
9febd8294c34   nginx                       "/docker-entrypoint.…"   11 minutes ago   Up 11 minutes   80/tcp                                  musing_chaplygin
1267c9463f48   dockerinaction/ch2_mailer   "/mailer/mailer.sh"      11 minutes ago   Up 11 minutes   33333/tcp                               keen_easley
```
注意这里的 cid（CONTAINER ID） 是经过截断的，因为同一台计算机上的 cid 前12个字符不大可能相等。
如果想查看完整的cid，加上 --no-trunc 参数即可

```shell
docker ps --no-trunc
```



```shell
# 进入 watcher
docker exec  --interactive --tty intelligent_sanderson /bin/sh
```

检查网络是否连通
```shell
ping insidemailer
ping insideweb
```

注意: docker 官方文档上警告 --link 是一个旧的功能，建议使用用户定义网络网络代替。

[--link 参数](https://docs.docker.com/network/links/)

## 4.构建与环境无关的系统

```shell
docker run --detach --name wp --read-only \
wordpress:5.0.0-php7.2-apache
```

```shell
docker inspect --format "{{.State.Running}}" wp
```

```shell
docker logs wp
```

以只读文件系统运行 WordPress 时, Apache Web 服务器进程将报告无法创建锁文件。
```shell
WordPress not found in /var/www/html - copying now...
Complete! WordPress has been successfully copied to /var/www/html
AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.17.0.6. Set the 'ServerName' directive globally to suppress this message
AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.17.0.6. Set the 'ServerName' directive globally to suppress this message
Tue Jul 11 23:39:06 2023 (1): Fatal Error Unable to create lock file: Bad file descriptor (9)
```

```shell
docker run --detach --name wp_writable \
wordpress:5.0.0-php7.2-apache
```

检查容器系统上的文件或者文件夹变化。
```shell
docker container diff wp_writable
# docker diff wp_writable
```

允许容器使用从主机挂载的可写卷进行写操作：

[--volumes 参数](https://docs.docker.com/storage/volumes/)
[--tmpfs 参数](https://docs.docker.com/storage/tmpfs/)
```shell
# --read-only 仅读
# --volume 从主机挂载一个可读写的目录 
# --tmpfs 给容器提供常驻内存的临时文件系统 
docker run --detach --name wp2 \
--read-only \
--volume /run/apache2 \
--tmpfs /tmp \
wordpress:5.0.0-php7.2-apache
```

```shell
docker run --detach --name wpdb \
--env MYSQL_ROOT_PASSWORD=ch2demo \
mysql:5.7
```
[--env 参数](https://docs.docker.com/engine/reference/commandline/run/#env)



注意使用 mysql:5.7 会报错:
```shell
Unable to find image 'mysql:5.7' locally
5.7: Pulling from library/mysql
docker: no matching manifest for linux/arm64/v8 in the manifest list entries.
See 'docker run --help'.
```


```shell
docker run --detach --name wpdb \
--env MYSQL_ROOT_PASSWORD=ch2demo \
liupeng0518/mysql:5.7-arm64
```

再创建使用 MySQL 数据库作为存储的 WordPress:
```shell
docker run --detach --name wp3 \
--link wpdb:mysql \
-p 8000:80 \
--read-only \
--volume /run/apache2 \
--tmpfs /tmp \
wordpress:5.0.0-php7.2-apache
```

```shell
docker inspect --format "{{.State.Running}}" wp3
```

在主机上执行，访问 WordPress
```shell
curl -L https://127.0.0.1:8000
```

完整脚本：创建一个 WordPress 应用
```shell
#!/bin/sh
# 创建并启动mysql 容器
DB_CID=$(docker create --env MYSQL_ROOT_PASSWORD=ch2demo liupeng0518/mysql:5.7-arm64)

docker start $DB_CID

# 创建并启动邮件服务器
MAILER_CID=$(docker create dockerinaction/ch2_mailer)

docker start $MAILER_CID

# 创建并启动 WordPress
WP_CID=$(docker create --link $DB_CID:mysql --publish 8000:80 \
--read-only \
--volume /run/apache2/ \
--tmpfs /tmp \
wordpress:5.0.0-php7.2-apache
)
  
docker start $WP_CID

# 创建并启动
AGENT_CID=$(docker create --link $WP_CID:insideweb --link $MAILER_CID:insidemailer \
dockerinaction/ch2_agent)

docker start $AGENT_CID
```

## 5.优化创建 WordPress 脚本

启动共享数据库和邮件程序容器
```shell
export DB_CID=$(docker run --detach --env MYSQL_ROOT_PASSWORD=ch2demo liupeng0518/mysql:5.7-arm64)
export MAILER_CID=$(docker run --detach dockerinaction/ch2_mailer)
```



脚本: start-wp-for-client.sh

作用: 为每个客户创建并启动 WordPress容器和监视器代理程序
```shell
#!/bin/sh

if [ ! -n "$CLIENT_ID" ]; then
    echo "Client ID not set"
    exit 1
fi 


WP_CID=$(docker crete \ 
--link $DB_CID:mysql
--name $wp_$CLIENT_ID \
--publish 80:80 \
--read-only --volume /run/apache2 --tmpfs /tmp/ \
--env WORDPRESS_DB_NAME=$CLIENT_ID \
--read-only wordpress:5.0.0-php7.2-apache
)
  
docker start $WP_CID

AGENT_CID=$(docker create \
--name agent_$CLIENT_ID \
--link $WP_CID:insideweb \
--link $MAILER_CID:insidemailer \
dockerinaction/ch2_agent
)
  
docker start $AGENT_CID
```

执行脚本

给脚本运行环境设置变量：
https://stackoverflow.com/questions/10856129/setting-an-environment-variable-before-a-command-in-bash-is-not-working-for-the

## 6.建立持久的容器

docker 自动重启容器：
```shell
docker run --detach --name backoff-detector --restart always busybox:1.29 date
```

查看重启次数
```shell
docker logs --follow backoff-detector 
```
[--restart 参数](https://docs.docker.com/engine/reference/commandline/run/#restart)

删除容器:(注意这只清楚容器，没有清除与容器关联的匿名卷)
```shell
#删除容器前需要停止容器，或者使用 --force
#清理与容器关联的匿名卷 --volumes
docker rm wp -vf
```

设置容器运行退出后自动删除
```shell
docker run --rm --name aoto-exit-test busybox:1.29 echo hello
```
查看容器是否删除
```shell
docker ps - a | grep aoto-exit-test
```

使用 init 系统:容器内运行多个进程或者正在运行的进程包含子进程的时候，推荐使用。
可以在容器内使用多个 这个样的 init 系统。

常用的 init 系统: runit,Yelp/dump-init,tini,supervisord,tianon/gosu,systemd

启动 LAMP 软件战镜像，测试其中的 supervisord功能
```shell
docker run --detach --publish 80:80 --name lamp-test tutum/lamp
```
查看 LAMP 中的进程
```shell
docker exec lamp-test ps
```

输出结果:
```text
  PID TTY          TIME CMD
    1 ?        00:00:00 supervisord
  991 ?        00:00:00 mysqld_safe
  993 ?        00:00:00 apache2
 1871 ?        00:00:00 ps
```

杀死 apache2 对应的进程
```shell
docker exec lamp-test kill 993

```

注意:如果使用 kill -9 杀死进程，supervisord 会重启子进程 apache2 失败，具体原因待查证。
```text
2023-07-15 00:55:51,746 INFO exited: apache2 (terminated by SIGKILL; not expected)
2023-07-15 00:55:52,770 INFO spawned: 'apache2' with pid 961
2023-07-15 00:55:52,961 INFO exited: apache2 (exit status 1; not expected)
2023-07-15 00:55:53,971 INFO spawned: 'apache2' with pid 965
2023-07-15 00:55:54,157 INFO exited: apache2 (exit status 1; not expected)
2023-07-15 00:55:56,166 INFO spawned: 'apache2' with pid 969
2023-07-15 00:55:56,348 INFO exited: apache2 (exit status 1; not expected)
2023-07-15 00:55:59,377 INFO spawned: 'apache2' with pid 973
2023-07-15 00:55:59,567 INFO exited: apache2 (exit status 1; not expected)
2023-07-15 00:56:00,572 INFO gave up: apache2 entered FATAL state, too many start retries too quickly
```

设置入口点程序(entry point)。
```shell
docker run --entrypoint ="cat" \
wordpress-5.0.0-php7.2-apache \
/usr/local/bin/docker-entrypoint.sh
```


[docker run](https://docs.docker.com/engine/reference/commandline/run/)
[docker run 额外参数](https://docs.docker.com/engine/reference/run/#operator-exclusive-options)

