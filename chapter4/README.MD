存储和卷

注意：如果在 mac 上执行docker run 报错: `docker: no matching manifest for linux/arm64/v8 in the manifest list entries.`
可以尝试加`--platform` 参数,指定使用 linux/amd64 架构, 尝试获取 amd64 架构的镜像。

## 4.1 文件树和挂载点

什么是文件树？

什么是挂载点？

挂载在容器中的三种常见的存储类型:
- 绑定挂载
- 常驻内存挂载
- Docker 卷

## 4.2 绑定挂载

绑定挂载：用于将文件树的一部分重新挂载到其他位置的一些挂载点。

```shell
# CONF_SRC 为主机文件树上的配置文件
# CONF_DST 为容器文件树中的挂载点，注意必须使用绝对路径来指定位置
CONF_SRC=~/example.conf; \
CONF_DST=/etc/nginx/conf.d/default.conf; \

# 下面同理。
LOG_SRC=~/example.log; \
LOG_DST=/var/log/nginx/custom.host.access.log; \
docker run -d --name diaweb-1 \
--mount type=bind,src=${CONF_SRC},dst=${CONF_DST},readonly=true \
--mount type=bind,src=${LOG_SRC},dst=${LOG_DST} \
--publish 80:80 \
nginx:latest
```

发送请求: > curl http://localhost:80
查看日志: 可以在主机上看到日志内容
```
> cat ~/example.log
172.17.0.1 - - [16/Jul/2023:16:25:48 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/7.85.0" "-"
172.17.0.1 - - [16/Jul/2023:16:25:57 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/7.85.0" "-"
```

安全问题: 需要保证 NGINX Web 服务器只读，不能修改配置卷的内容: 启用 `readonly=true` 参数, 利用 Linux 使得挂载点只读。

进入容器中, 尝试向配置文件末尾写入 "hello", 提示写入失败, default.conf 为只读文件系统。
```shell
> docker exec --interactive --tty  diaweb /bin/sh
> echo hello > /etc/nginx/conf.d/default.conf  

# output                 
/bin/sh: 1: cannot create /etc/nginx/conf.d/default.conf: Read-only file system
```

## 4.3 常驻内存存储

进一步提高安全性，请勿将敏感数据写入磁盘中，可以使用常驻内存，通过特殊挂载类型将常驻内存存储在容器中。

方法1:
- 创建空的 tmpfs 设置，并附加在容器中的 /tmp 位置，该位置下的所有所有文件将写入内存。
- tmpfs 设备默认没有大小限制，并且是可写的。
- 可选参数 tmpfs-size 和 tmpfs-mode 可以限制添加设备的大小和修改文件权限。
  - tmpfs-mode=1770表示其他用户无法读取，默认权限是1777（八进制的文件权限：可写）
```shell
docker run --rm \
--mount type=tmpfs,dst=/tmp,tmpfs-size=16k,tmpfs-mode=1770 \
--entrypoint mount \
alpine:latest -v

# output
Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
9fda8d8052c6: Pull complete 
Digest: sha256:7144f7bab3d4c2648d7e59409f15ec52a18006a128c733fcff20d3a4a54ba44a
Status: Downloaded newer image for alpine:latest
overlay on / type overlay (rw,relatime,lowerdir=/var/lib/docker/overlay2/l/T356AB3YF7ZRYJGWL2X4KQF2U5:/var/lib/docker/overlay2/l/2WBMW2KLOHYPCJBKLCONPTSVTO,upperdir=/var/lib/docker/overlay2/706c51fdd71ac798eddb0ca499a3553962caf253c4cf1e3e383dc9b2dbc3dcf2/diff,workdir=/var/lib/docker/overlay2/706c51fdd71ac798eddb0ca499a3553962caf253c4cf1e3e383dc9b2dbc3dcf2/work)
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
tmpfs on /dev type tmpfs (rw,nosuid,size=65536k,mode=755)
devpts on /dev/pts type devpts (rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=666)
sysfs on /sys type sysfs (ro,nosuid,nodev,noexec,relatime)
cgroup on /sys/fs/cgroup type cgroup2 (ro,nosuid,nodev,noexec,relatime)
mqueue on /dev/mqueue type mqueue (rw,nosuid,nodev,noexec,relatime)
shm on /dev/shm type tmpfs (rw,nosuid,nodev,noexec,relatime,size=65536k)
tmpfs on /tmp type tmpfs (rw,nosuid,nodev,noexec,relatime)
/dev/vda1 on /etc/resolv.conf type ext4 (rw,relatime)
/dev/vda1 on /etc/hostname type ext4 (rw,relatime)
/dev/vda1 on /etc/hosts type ext4 (rw,relatime)
proc on /proc/bus type proc (ro,nosuid,nodev,noexec,relatime)
proc on /proc/fs type proc (ro,nosuid,nodev,noexec,relatime)
proc on /proc/irq type proc (ro,nosuid,nodev,noexec,relatime)
proc on /proc/sys type proc (ro,nosuid,nodev,noexec,relatime)
proc on /proc/sysrq-trigger type proc (ro,nosuid,nodev,noexec,relatime)
tmpfs on /proc/kcore type tmpfs (rw,nosuid,size=65536k,mode=755)
tmpfs on /proc/keys type tmpfs (rw,nosuid,size=65536k,mode=755)
tmpfs on /proc/timer_list type tmpfs (rw,nosuid,size=65536k,mode=755)
tmpfs on /sys/firmware type tmpfs (ro,relatime)
```
容器的挂载点说明: 例如 tmpfs on /tmp type tmpfs (rw,nosuid,nodev,noexec,relatime)，从左到右各个字段含义：
- tmpfs 设备被挂载到文件树的 /tmp 位置
- 设备具有 tmpfs 文件系统
- 文件树是可读/写的
- 文件树中所有文件的 suid 位都被忽略
- 文件树中所有文件都为非特殊设备
- 文件树中所有文件非可执行文件
- 文件树中的文件实时更新(如果文件树中的文件访问时间早于当前修改时间，则会更新文件树)


## 4.4 Docker 卷

> 理解卷的相关只是对在生产环境中使用容器至关重要。

Docker 卷被命名为由 Docker 管理的文件系统树，是一种对容器存储与主机文件系统中通过绑定怪哉指定的专用位置进行解耦的方法。

Docker 卷的所有操作可以经由 docker volume 子命令集来完成。

下面的命令将传播构建一个名为 local-example 的卷，并显示该卷在主机文件系统树中的位置:
```shell
# docker volume create --help
# docker volume inspect --help
docker volume create --driver local --label example=location location-example

# 检查卷
docker volume inspect \
--format "{{json .Mountpoint}}" \
location-example
```
### 4.4.1 卷提供容器无关的数据管理

语义上：卷是一种用于划分和共享一定范围或者生命周期内数据的工具，这些数据的范围和生命周期与单个容器无关。

作为工具 Docker 对主机一无所知，只知道容器应该使用哪些文件，自身无法充分利用特定主机的功能（比如使用固态硬盘取代机械硬盘）

### 4.4.2 在 NoSQL 数据库中使用卷

创建名为 cass-shared 的卷:
```shell
docker volume create \
--driver local \
--label example=cassandra \
cass-shared
```

创建容器，在容器的文件系统 /var/lib/cassandra/data 中挂载卷 cass-shared。
```shell
# --platform linux/amd64
docker run --detach --platform linux/amd64 \
--volume cass-shared:/var/lib/cassandra/data \
--name cass1 \
cassandra:2.2
```

启动过程有报错:https://hub.docker.com/_/cassandra
https://stackoverflow.com/questions/27004773/cassandra-cqlsh-unable-to-connect-to-any-servers-127-0-0-19160-closed-is-a

```shell
ERROR 05:16:06 Exception encountered during startup: If rpc_address is set to a wildcard address (0.0.0.0), then you must set broadcast_rpc_address to a value other than 0.0.0.0
```
根据错误提示设置环境变量 CASSANDRA_BROADCAST_ADDRESS 后，上述错误消失。但是随后出现其他错误：看提示是启动失败，检测到不可读的 [sstables](https://cassandra.apache.org/doc/latest/cassandra/architecture/storage_engine.html#sstables), 修改 cassandra 镜像版本为 4.1 后正常启动。

```shell
ERROR 15:08:33 Detected unreadable sstables /opt/cassandra/data/data/system/sstable_activity_v2-62efe31f3be8310c8d298963439c1288/nb-1-big-Filter.db,
please check NEWS.txt and ensure that you have upgraded through all required intermediate versions, running upgradesstables
```

最终代码：
```shell
docker run --interactive --tty --rm --platform linux/amd64 --env CASSANDRA_BROADCAST_ADDRESS=127.0.0.1  \
--volume cass-shared:/var/lib/cassandra/data \
--name cass1 \
cassandra:4.1
```

```shell
docker run --interactive --tty --rm --platform linux/amd64 \
--link cass1:cass \
cassandra:4.1 cqlsh cass
```

在客户端中查看名为 docker_hello_world 的键空间
```sql
# 书上的实例代码
select *
from system.schema_keyspaces
where keyspace_name = 'docker_hello_world';

# 使用 cassandra:4.1 后,需要替换为
select * from system_schema.keyspaces where keyspace_name = 'docker_hello_world'
```

创建 docker_hello_world 键空间:
```sql
create keyspace docker_hello_world
with replication = {
    'class': 'SimpleStrategy',
    'replication_factor': 1
};
```

再次执行上面的查询请求，验证写请求是否执行成功, 输入结果:
```text
 keyspace_name      | durable_writes | replication
--------------------+----------------+-------------------------------------------------------------------------------------
 docker_hello_world |           True | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '1'}

```

删出容器后再查询.
```shell
docker stop cass1
docker rm --volumes --force cass1
```

清理挂载卷：`docker rm --volumes --force cass1 cass-shared`


ref:https://docs.docker.com/network/links/


## 4.5 共享挂载点和共享文件

绑定挂载示例:
```shell
# 设置一个已知位置
LOG_SRC=~/web-logs-example
mkdir ${LOG_SRC}

# 将刚才的位置绑定挂载到用于读取的容器
docker run --name plath --detach \
--mount type=bind,src=${LOG_SRC},dst=/data \
dockerinaction/ch4_writer_a

# 将相同的位置绑定挂载到用于读取的容器
docker run --rm \
--mount type=bind,src=${LOG_SRC},dst=/data \
alpine:latest \
head /data/logA

# 查看主机的日志
cat ${LOG_SRC}/logA
sleep 10s
# 停止将日志写入容器
docker rm --force plath
```


命名卷共享示例:
```shell
# 设置卷名
docker volume create \
--driver local \
logging-example

# 将卷挂载到容器(日志写入容器)
docker run --name plath --detach \
--mount type=volume,src=logging-example,dst=/data \
--platform linux/amd64 \
dockerinaction/ch4_writer_a

# 将卷挂载到容器（日志读取容器）
docker run --rm \
--mount type=volume,src=logging-example,dst=/data \
alpine:latest \
head /data/logA

# 从主机上查看日志
cat "$(docker volume inspect \
--format "{{json .Mountpoint}}" logging-example)"/logA

# 停止写入容器
docker stop plath
```

注意在 Mac 系统中，Docker 运行在 VM 上，所以 docker volume 中的地址是 VM 中的地址，是在 Mac 上无法直接访问的。

https://forums.docker.com/t/host-path-of-volume/12277

https://forums.docker.com/t/where-is-docker-volume-in-mac/134145

