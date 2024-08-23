第 11 章 Docker 和 Compose 服务 

服务的定义、管理。

# 11.1 启动一个 Docker 服务

Docker 服务仅在 Docker 以集群模式运行才可用
```sh
docker swarm init # 初始化 Docker 的 swarm 集群模式
docker service create \
	--publish 8080:80 \
	--name hello-world \
	dockerinaction/ch11_service_hw:v1
```

kubernates 和 swarm 区别?


更新镜像和服务：
```sh
docker service update \
	--image dockerinaction/ch11_service_hw:v2 \  # 新的镜像名
    --update-order stop-first \
	--update-parallelism 1 \
	--update-delay 30s \
	hello world # 等待更新的服务名
```

更新失败回滚：--rollback
```sh
docker update \
	--update-failure-action rollback \
	--update-max-failure-ratio 0.6 \
	--image dockerinaction/ch11_service_hw:start-failure \
	hello-world
```

增加健康检查：
```sh
docker service update \
	--health-cmd /bin/httping \
	--health-interval 5s \
	hello-world
```
# 11.2 使用 ComposeV3 声明服务环境

Docker 栈：服务、卷、网络、密钥和配置的命名集合。


使用 Compose 文件创建 Docker 栈
```sh
docker stack deploy -c database.yml my-databases
```

database.yml
```yml
version: "3.7" # 使用 Docker Compose 的版本 3.7
networks:
  foo:
    driver: overlay # 创建名为 "foo" 的网络，并使用 overlay 驱动器
volumes:
  pgdata: # 声明一个名为 "pgdata" 的卷，用于持久化数据库数据
services:
  postgress: # 定义 PostgreSQL 数据库服务
    image: dockerinaction/postgress:11-alpine # 使用 Docker 镜像 dockerinaction/postgress:11-alpine
    volumes:
      - type: volume # 定义卷的类型为 volume
        source: pgdata # 使用之前声明的 "pgdata" 卷
        target: /var/lib/postgress/data # 将卷挂载到容器内的 /var/lib/postgress/data 路径
    networks:
      - foo # 将该服务连接到名为 "foo" 的网络
    environment:
      POSTGRES_PASSWORD: example # 设置 PostgreSQL 数据库的密码为 "example"
  adminer: # 定义 Adminer 服务，用于管理 PostgreSQL 数据库
    image: dockerinaction/adminer # 使用 Docker 镜像 dockerinaction/adminer
    networks:
      - foo # 将该服务连接到名为 "foo" 的网络
    ports:
      - 8080:8080 # 映射主机的 8080 端口到容器内的 8080 端口，便于通过浏览器访问 Adminer
    deploy:
      replicas: 1 # 设置该服务的副本数量为 1，即只有一个容器实例在运行
```




# 11.3 带有状态的服务和保留的数据

持久化数据：对卷进行建模，使用 volumes 属性，指定 Compose 文件中服务可以使用的卷，另外需要明确服务和卷之间的依赖关系。

# 11.4 使用 Compose 进行负载均衡、服务发现和联网

针对服务创建虚拟IP(VIP)地址，接收来自外部的请求，在服务的所有副本之间进行负载均衡。
