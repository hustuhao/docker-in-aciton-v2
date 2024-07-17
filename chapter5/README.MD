
基本知识：协议，接口和端口

深入知识：网络，NAT和端口转发


Docker 利用虚拟网络将所有正在运行的容器连接到本地计算机，这种虚拟网络又称为网桥。

打印所有网络：
docker network ls

Docker 架构中的三种网络：本地，全局，集群类型。


# 5.2 Docker 容器网络

## 构建名为 user-network 的本地桥接网络
```shell
docker network create \
--driver bridge \
--label project=dockerinaction \
--attachable \
--scope local \
--subnet 10.0.42.0/24 \
--ip-range 10.0.42.128/25 \
user-network
```

- label: 方便识别资源
- attachable: 可对容器和网络进行连接或者分离
- scope: 网络范围，默认值就是 local
- subnet： 网络自定义子网掩码
- ip-range 可分配的IP地址范围，10.0.42.128 ~ 10.0.42.255


## 探索桥接网络

连接桥接网络

创建容器 network-explore 并连接进入容器的终端
```shell
docker run -it \
    --network user-network \
    --name network-explore \
    alpine:3.8 \
    sh
```

查看容器内可用的 IPv4 地址列表：
```shell
ip -f inet -4 -o addr

结果
/ # ip -f inet addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
67: eth0@if68: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    inet 10.0.42.129/24 brd 10.0.42.255 scope global eth0
       valid_lft forever preferred_lft forever

```

创建另外一个网络 user-network2
```shell
docker network create \
    --driver bridge \
    --label project=dockerinaction \
    --label chapter=5 \
    --attachable \
    --scope local \
    --subnet 10.0.43.0/24 \
    --ip-range 10.0.43.128/25 \
    user-network2
```

容器 network-explore 连接 user-network2 网络：
```shell
docker network connect \
    user-network2 \
    network-explore

```

在容器中查看网络接口配置：发现容器已经连接上新创建的 user-network2 接口
```shell 
/ # ip -f inet addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
67: eth0@if68: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    inet 10.0.42.129/24 brd 10.0.42.255 scope global eth0
       valid_lft forever preferred_lft forever
70: eth1@if71: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    inet 10.0.43.129/24 brd 10.0.43.255 scope global eth1
       valid_lft forever preferred_lft forever
```

容器内安装：nmap
```shell
apk update && apk add nmap
```

容器内执行
```shell
nmap -sn 10.0.42.* -sn 10.0.43.* -oG /dev/stdout | grep Status 

# 输出

# 由桥接网络驱动程序创建的网关适配器
Host: 10.0.42.128 ()	Status: Up
# 连接到网关适配器的容器
Host: 10.0.42.129 (584ae9d8f398)	Status: Up
Host: 10.0.43.128 ()	Status: Up
Host: 10.0.43.129 (584ae9d8f398)	Status: Up
```

再创建一个容器，连接到网络 user-network2
```shell
docker run -d \
    --name lighthouse \
    --network user-network2 \
    alpine:3.8 \
    sleep 86400
```

再渐入 network-explore 容器，对网络端口进行扫描：
```shell
/ # nmap -sn 10.0.42.* -sn 10.0.43.* -oG /dev/stdout | gr
ep Status

# 输出：
Host: 10.0.42.128 ()	Status: Up
Host: 10.0.42.129 (584ae9d8f398)	Status: Up
Host: 10.0.43.128 ()	Status: Up
Host: 10.0.43.130 (lighthouse.user-network2)	Status: Up
Host: 10.0.43.129 (584ae9d8f398)	Status: Up
```


# 5.3 特殊容器网络

主机网络和 none 网络

host 和 none 并不是真正的网络，而是有特殊含义的网络连接类型。

```shell
docker run --rm \
    --network host \
    alpine:3.8 ip -o addr
```


```shell
docker run --rm \
    --network none \
    alpine:3.8 ip -o addr

#输出

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
3: ip6tnl0@NONE: <NOARP> mtu 1452 qdisc noop state DOWN qlen 1000
    link/tunnel6 00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00 brd 00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00

```


结论：在使用 --network none 选项启动容器时，容器没有任何外部网络连接，仅有 lo (loopback) 接口是活动的，其他接口 tunl0 和 ip6tnl0 处于 DOWN 状态。lo 接口用于容器自身的环回网络通信，具有 127.0.0.1 地址。

```shell
docker run --rm \
    --network none \
    alpine:3.8 \
    ping -w 2  114.114.114.114

# 输出
ping: sendto: Network unreachable
PING 114.114.114.114 (114.114.114.114): 56 data bytes
```

# 5.4 NodePort publishing 节点端口发布

容器需要通过 NAT 才能连接到外部网络，因此容器的端口需要通过节点端口发布到外部。


```shell

# 随机选择一个主机端口作为发送端口，转发流量到容器的8080端口
docker run --rm \
    -p 8080 \
    alpine:3.8 echo "forward ephemeral TCP -> container TCP 8080"

# 指定主机的8088端口，转发流量到容器的8080端口 
docker run --rm \
    -p 8088:8080/udp \
    alpine:3.8 echo "host UDP 8088 -> container UDP 8080"

# 指定多个端口
docker run --rm \
    -p 127.0.0.1:8080:8080/tcp \
    -p 127.0.0.1:3000:3000/tcp \
    alpine:3.8 echo "forward multiple TCP ports from localhost"
```

发布多个端口
```shell
docker run -d \
    -p 8080 \
    -p 3000 \
    -p 7500 \
    --name multi-listener \
    alpine:3.8 sleep 300
```

查看容器端口对应的主机端口
```shell
docker port multi-listener 

# 输出
0.0.0.0:53052
```

# 5.5 容器网络配置

注意：容器网络不提供任何访问控制或防火墙机制在容器之间 。

自定义 DNS 配置：

设置容器的主机名(hostname):
- 其他的容器可以通过主机名访问该容器
- 识别自己 IP 地址

```shell
docker run --rm \
    --hostname barker \
    alpine:3.8 \
    nslookup barker
```

报错：
nslookup: can't resolve '(null)': Name does not resolve

应该是 nslookup 参数有问题，需要指定 DNS server

```
docker run --rm \
    --hostname barker \
    alpine:3.8 \
    nslookup --help

# 输出
BusyBox v1.28.4 (2018-12-31 18:05:26 UTC) multi-call binary.

Usage: nslookup [HOST] [SERVER]

Query the nameserver for the IP address of the given HOST
optionally using a specified DNS server
```

修改命令后：
```shell
docker run --rm \
    --hostname barker \
    alpine:3.8 \
    nslookup barker 114.114.114.114

# 输出
Server:    114.114.114.114
Address 1: 114.114.114.114 public1.114dns.com

Name:      barker
Address 1: 172.17.0.2 barker

```

设置 DNS 服务器：
```shell
docker run -
-rm \
    --dns 114.114.114.114 \
    alpine:3.8 \
    nslookup docker.com 114.114.114.114

# 输出

Server:    114.114.114.114
Address 1: 114.114.114.114 public1.114dns.com

Name:      docker.com
Address 1: 108.160.165.139
Address 2: 2a03:2880:f12d:83:face:b00c::25de
```

设置 DNS 搜索前缀：--dns-search

原理：该参数会修改 /etc/resolv.conf 配置
用途：区分开发测试环境和线上环境的域名。
```
docker run --rm \
    --dns-search docker.com \
    --dns 1.1.1.1 \
    alpine:3.8 cat /etc/resolv.conf \

# 输出
search docker.com
nameserver 1.1.1.1
```

添加自定义 HOST 项：--add-host
```shell
docker run --rm \
    --hostname mycontainer \
    --add-host docker.com:127.0.0.1 \
    --add-host test:10.10.10.2 \
    alpine:3.8 \
    cat /etc/hosts

# 输出

127.0.0.1       localhost
::1     localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
127.0.0.1       docker.com
10.10.10.2      test
172.17.0.2      mycontainer
```


网络管理外部化:请参考 kubernates

当您使用外部化网络管理时，docker仍然负责为容器创建
网络名称空间，但它不会创建或管理任何网络接口。

