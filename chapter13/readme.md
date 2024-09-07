第 13 章 使用 Swarm 在 Docker 主机集群上编排服务


# 13.1 使用 Docker Swarm 集群

跨主机部署的优势：
- 提供冗余性：某台主机故障，其他的主机继续提供服务。
- 更多计算资源：允许应用程序使用相比单台主机能够提供的更多的计算资源。

[official doc: swarm](https://docs.docker.com/engine/swarm/)

# 13.2 将应用程序部署到 Swarm 集群

关键的 Docker Swarm 集群资源类型如下：
- Docker 服务
- 任务
- 网络
- 卷
- 配置和机密信息

```yaml
version: '3.7' # 指定 Docker Compose 文件的版本，决定了可以使用的功能和语法
# 网络配置部分
networks:
  public:
    driver: overlay # 使用 overlay 网络驱动，适用于多主机的 Docker 集群，允许不同主机上的容器互相通信
    driver_opts:
      encrypted: 'true' # 启用网络加密，确保网络上传输的数据被加密，提高安全性
  private:
    driver: overlay # 使用 overlay 网络驱动，同样适用于多主机的 Docker 集群
    driver_opts:
      encrypted: 'true' # 启用网络加密，保护数据传输安全
    attachable: 'true' # 允许容器在运行时附加到此网络，方便服务间的网络通信
# 卷配置部分
volumes:
  db-data: # 定义一个名为 db-data 的卷，用于存储 PostgreSQL 数据库的数据文件
  # 这个卷用于持久化数据，即使容器被删除或重建，数据仍然保留
# 密钥配置部分
secrets:
  ch13_multi_tier_app-POSTGRES_PASSWORD:
    external: true # 指明这个密钥由外部系统创建并管理，Docker Compose 不负责创建或更新它
    # 适用于需要在多个服务间安全传递敏感数据的场景
# 服务配置部分
services:
  postgres:
    image: postgres:9.6.6 # 使用 PostgreSQL 数据库的 9.6.6 版本的 Docker 镜像
    networks:
      - private # 将 postgres 服务连接到名为 private 的网络，这个网络通常用于数据库间的安全通信
    volumes:
      - db-data:/var/lib/postgresql/data # 将名为 db-data 的本地卷挂载到容器内的 /var/lib/postgresql/data 目录
      # 这样 PostgreSQL 的数据库文件会存储在卷中，保证数据的持久化
    secrets:
      - source: ch13_multi_tier_app-POSTGRES_PASSWORD # 使用外部定义的密钥 ch13_multi_tier_app-POSTGRES_PASSWORD
        target: POSTGRES_PASSWORD # 在容器内部将密钥挂载到 /run/secrets/POSTGRES_PASSWORD
        uid: '999' # 设置密钥文件的用户 ID 为 999，通常用于确保文件权限
        gid: '999' # 设置密钥文件的组 ID 为 999
        mode: 0400 # 设置密钥文件的权限为 0400，即只有文件所有者可以读取，其他人不能访问
    environment:
      POSTGRES_USER: 'exercise' # PostgreSQL 数据库用户，指定用于连接数据库的用户名
      POSTGRES_PASSWORD_FILE: '/run/secrets/POSTGRES_PASSWORD' # 指定密码文件的路径，容器启动时读取此文件中的密码
      POSTGRES_DB: 'exercise' # PostgreSQL 默认创建的数据库名称
    deploy:
      replicas: 1 # 部署一个 PostgreSQL 实例，确保只有一个副本运行
      update_config:
        order: 'stop-first' # 更新配置时，先停止旧的容器，再启动新的容器
      rollback_config:
        order: 'stop-first' # 回滚配置时，先停止有问题的容器，再重新启动旧的容器
      resources:
        limits:
          cpus: '1.00' # 限制容器最多使用 1 个 CPU 核心
          memory: 50M # 限制容器最多使用 50MB 内存
        reservations:
          cpus: '0.25' # 预留 0.25 个 CPU 核心，以确保容器在运行时有足够的计算资源
          memory: 50M # 预留 50MB 内存
  api:
    image: ${IMAGE_REPOSITORY:-dockerinaction/ch13_multier_app}:api # 使用环境变量 IMAGE_REPOSITORY 指定的镜像，或默认使用 dockerinaction/ch13_multier_app 镜像的 api 标签
    networks:
      - public # 将 api 服务连接到名为 public 的网络，允许外部访问
      - private # 同时连接到名为 private 的网络，用于与数据库等内部服务的通信
    ports:
      - '8080:80' # 将主机的 8080 端口映射到容器的 80 端口，允许外部访问 api 服务
    secrets:
      - source: ch13_multi_tier_app-POSTGRES_PASSWORD # 使用与 postgres 服务相同的密钥
        target: POSTGRES_PASSWORD # 在容器内部将密钥挂载到 /run/secrets/POSTGRES_PASSWORD
        mode: 0400 # 设置密钥文件的权限为 0400
    environment:
      POSTGRES_HOST: 'postgres' # 指定 PostgreSQL 数据库的主机名，容器中 API 服务用来连接数据库
      POSTGRES_PORT: '5432' # 指定 PostgreSQL 数据库的端口号，默认 PostgreSQL 使用 5432 端口
      POSTGRES_USER: 'example' # 数据库用户名，API 服务用来连接数据库
      POSTGRES_DB: 'exercise' # 默认数据库名
      POSTGRES_PASSWORD_FILE: '/run/secrets/POSTGRES_PASSWORD' # 指定密码文件的路径
    deploy:
      replicas: 2 # 部署两个 API 实例，以提高可用性和负载均衡
      restart_policy:
        condition: on-failure # 仅在容器失败时自动重启
        max_attempts: 10 # 最大重启尝试次数为 10 次
        delay: 5s # 重启失败后的延迟时间为 5 秒
      update_config:
        parallelism: 1 # 每次更新一个容器，确保逐步更新
        delay: 5s # 每次更新之间的延迟时间为 5 秒
      resources:
        limits:
          cpus: '0.50' # 限制容器最多使用 0.50 个 CPU 核心
          memory: 15M # 限制容器最多使用 15MB 内存
        reservations:
          cpus: '0.25' # 预留 0.25 个 CPU 核心
          memory: 15M # 预留 15MB 内存
```

# 13.3 与 Swarm 集群内运行的服务通信

主要内容：Docker 服务如何通过 Swarm 的服务发现机制和覆盖网络功能相互通信


## 13.3.1 使用 Swarm 路由网格将客户端请求路由到服务
Swarm 利用 Linux iptables 和 ipvs 功能实现监听器
- iptables: 将流量重定向到为服务分配的虚拟IP（VIP）
- ipvs: 作为传输层的负载均衡器，将TCP/UDP流量分发到服务的真实端点
- 入口网络(ingress): Swarm 使用 ipvs 为服务端口创建 VIP, 将VIP绑定到入口网络，入口网络在整个 Swarm 集群都可以用
- 路由网格：对外处理来自客户端的链接，将客户端的请求数据转发到服务任务。


## 13.3.2 使用覆盖网络

作用：逻辑上与其他网络分隔，并运行在基础网络上，覆盖网络内部的通信和外部的网络通信是隔离的。


## 13.3.3 在覆盖网络上使用服务发现

Docker 服务使用域名系统DNS在共享的Docker网络上查找其他的 Docker 服务


# 13.4 将服务任务放置在集群中

如何在群集汇总放置任务？

如何声明的约束条件内运行期望数量的服务副本？
