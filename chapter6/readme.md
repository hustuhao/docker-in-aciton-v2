资源控制和风险

构建 Docker 容器的的八个名称空间和特性:
- MNT：Filesystem access and structure
- NET
- UTS
- USR
- IPC
- PID
- Cgroups
- chroot

注意 Docker 和他是用的技术是在不断发展的，上述叙述可能也会改变。


## 6.1 设置资源配额

### 内存限制

只是防止过度使用内存的保护措施，并不能保证指定的内存都是可用的。

```shell
docker container run -d --name ch6_mariadb \
    --memory 256m \
    --cpu-shares 1024 \
    --cap-drop net_raw \
    -e MYSQL_ROOT_PASSWORD=test \
    mariadb:5.5
```

确定需要多少内存：docker stats

```shell
docker stats ch6_mariadb
```

可以设置超出主机内存大小的内存：swap space



### CPU 限制


cpu-shares 参数：设置 CPU 相对权重。

--cpu-shares 参数设置为1024和512区别：
cpu--shares 参数设置为1024的 mariadb, 对应参数设置为 512 的 wordpress; wordpress 每运行一个 cpu 周期，mariadb 会运行两个 cpu 周期。

```shell
docker container run -d -P --name ch6_wordpress \
    --memory 512m \
    --cpu-shares 512 \
    --cap-drop net_raw \
    --link ch6_mariadb:mysql \
    -e WORDPRESS_DB_PASSWORD=test \
    wordpress:5.0.0-php7.2-apache
```





cpus参数：限制容器可用的CPU的总量。通过配置 Linux 完全公平调度程序 CFS，cpus 选项给容器分配相应的 CPU 资源额度。
```shell
docker container run -d -P --name ch6_wordpress \
    --memory 512m \
    --cpus 0.75 \
    --cap-drop net_raw \
    --link ch6_mariadb:mysql \
    -e WORDPRESS_DB_PASSWORD=test \
    wordpress:5.0.0-php7.2-apache 
```

### 访问设备


将主机的设备 /dev/video0 映射到容器中的相同位置
```shell
docker container run -it --rm \
    --device /dev/video0:/dev/video0 \
    ubuntu:16.04 ls -al /dev
```


# 6.2 共享内存

IPC:  InterProcess Communication 进程间通信，以内存级速度进行通信。

IPC 命名空间: Docker 默认给每一个容器创建唯一的 IPC 命名空间，可防止一个容器中的进程访问主机或者其他容器的内存。

Linux IPC 命名空间
- 共享内存基本单元：命名的共享内存快、信号量以及消息队列。


在容器之间共享 IPC 基本单元：
```shell
# 创建消息队列，并广播消息
docker container run -d -u nobody --name ch6_ipc_producer 
    --platform=linux/amd64 \
    --ipc shareable \
    dockerinaction/ch6_ipc -producer
```


```shell
# 从消息队列中读取消息并将消息写入日志
docker container run -d -u nobody --name ch6_ipc_consumer \
    dockerinaction/ch6_ipc -consumer
```

查看日志：
```shell
docker logs ch6_ipc_producer

docker logs ch6_ipc_consumer
```

测试 IPC 命名空间：使用 --ipc 整合 IPC 命名空间。
```shell
# 删除原来的消费者
docker container run -v ch6_ipc_consumer

# 启动新的消费者
docker container run -d --name ch6_ipc_consumer --platform=linux/amd64 \
    --ipc container:ch6_ipc_producer \
    dockerinaction/ch6_ipc -consumer
```

# 6.3 理解用户

为什么要限制 container 运行的用户权限？


查看 busybox 镜像中定义的运行时用户：
```shell
docker image pull busybox:1.29
docker inspect busybox:1.29
docekr inspect --format "{{.Config.User}}" busybox:1.29
```



下面两条命令确认镜像的默认用户
```shell
docker container run --rm --entrypoint "" busybox:1.29 whoami
#  输出
root

docker container run --rm --entrypoint "" busybox:1.29 id
# 输出
uid=0(root) gid=0(root) groups=0(root),10(wheel)
```

获取镜像中可用的用户的列表：
```shell
docker container run --rm busybox:1.29 awk -F: '$0=$1' /etc/passwd

# 输出结果
root
daemon
bin
sys
sync
mail
www-data
operator
nobody
```

设置运行时用户和运行时用户组

```shell
docker container run --rm \
    -u nobody:nogroup \
    busybox:1.29 id
```

用户和卷

```shell

# 主机上创建新文件
echo "e=mc^2" > garbage

# 为文件拥有者设置只读权限
chmod 600 garbage 

# 把文件拥有者改为 root 用户
sudo chown root garbage

# 运行容器，挂载文件，并以 nobody 用户运行
docker container run --rm -v "$(pwd)"/garbage:/test/garbage \
    -u nobody \
    ubuntu:16.04 cat /test/garbage

# 尝试使用 root 用户运行
docker container run --rm -v "$(pwd)"/garbage:/test/garbage \
    -u root \
    ubuntu:16.04 cat /test/garbage
```

将目录所有这者设置为期望的用户和组
```shell
#创建目录
mkdir logFiles

#修改目录的用户和组
sudo chown 2000:2000 logFiles

# 输出重要的日志文件
docker container run --rm -v "${PWD}"/logFiles:/logFiles \
    -u 2000:2000 ubuntu:16.04 \
    /bin/bash -c "echo this is important info > /logFiles/important.log"

# 从另外一个容器中向日志文件添加内容
docker container run --rm -v "${PWD}"/logFiles:/logFiles \
    -u 2000:2000 ubuntu:16.04 \
    /bin/bash -c "echo More info >> /logFiles/important.log"

# 清理文件
sudo rm -r logFiles

```

要读取或者写入 Docker 守护进程API，程序需要满足两个前提条件：
- 由具有入去或者写入 docker.sock 套接字权限的用户或者组运行管理程序（下面的命令使用 root 用户）
- 将 /var/run/docker.sock 套接字挂在到容器中（下面的命令将主机上的 docker.sock套接字以只读文件的形式绑定到容器中）
```shell
docker container run --rm -it \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -u root monitoringtool
```

用户命名空间和 UID 重新映射：
- 搜索 dockremap：https://docs.docker.com/engine/security/userns-remap/

# 6.4 根据功能集调整操作系统功能访问范围

```shell
docker container run --rm -u nobody \
    ubuntu:16.04 \
    /bin/bash -c "capsh --print | grep net_raw"
```

删除 NET_RAW 功能：
```shell
docker container run --rm -u nobody \
    --cap-drop net_raw \
    ubuntu:16.04 \
    /bin/bash -c "capsh --print | grep net_raw"
```

添加 sys_admin 功能

```shell
docker container run --rm -u nobody \
    --cap-add sys_admin \
    ubuntu:16.04 \
    /bin/bash -c "capsh --print | grep sys_admin"
```

# 6.5 以完全特权运行容器

```shell
docker container run --rm \
    --privileged \
    ubuntu:16.04 id
```


