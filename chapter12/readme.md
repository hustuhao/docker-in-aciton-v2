第 12 章 一流的配置


# 部署问候程序

docker-compose-yml
```yml
version: '3.7'
configs:
  env_specific_config: # 定义配置资源的映射关系
    file: ./api/config/config.${DEPLOY_ENV:-prod}.yml
services:
  api: # 服务名
    image: ${IMAEGE_REPOSITORY:-dockerinaction/ch12_greeting}:api
    ports:
      - '8080:8080'
      - '8443:8443'
    user: '1000'
    configs:
        - source: env_specific_config
        target: /config/config.${DEPLOY_ENV:-prod}.yml # 堵盖默认的目标文件路径 
        uid: '1000'
        gid: '1000'
        mode: 0400
    secrets: []
    environment: # 定义环境变量
      DEPLOY_ENV: ${DEPLOY_ENV:-prod}
```

部署应用程序：
```sh
DEPLOY_ENV=dev docker stack deploy \
	--compose-file docker-compose.yml greetings_dev
```

curl http://localhost:8080

curl htpp://localhost:8080/greeting

# 部署支持 HTTPS 的 WEB 服务

为什么不是用环境变量作为机密信息传输载体？
- 不能将访问控制机制分配的环境变量
- 应用程序执行的任何进程都可以访问这些环境变量
- 许多应用程序可能把环境变量打印到日志文件中，导致环境变量被公开。


`Configs` 用于存储和分发不敏感的配置数据，而 `Secrets` 专为安全存储和管理敏感信息设计。

使用 [secrets](https://docs.docker.com/engine/swarm/secrets/) 来传递私钥

注意：Docker secrets 只对集群服务可用，而对独立容器无效。要使用此特性，请考虑调整容器以使其作为服务运行。有状态容器通常可以在不更改容器代码的情况下以1的比例运行。
```yml
version: '3.7'
configs:
  ch12_greetings_svc-prod-TLS_CERT_V1:
    external: true
secrets:
  ch12_greetings-svc-prod-TLS_PRIVATE_KEY_V1:
    external: true
services:
  api:
    environment:
      CERT_PRIVATE_KEY_FILE: '/run/secrets/cert_private_key.pem'
      CERT_FILE: '/config/svc.crt'
    configs: # 将source挂载为target
      - source: ch12_greetings_svc-prod-TLS_CERT_V1
        target: /config/svc.crt
        uid: '1000'
        gid: '1000'
        mode: 0400
    secrets: # 将source挂载为target
      - source: ch12_greetings-svc-prod-TLS_PRIVATE_KEY_V1
        target: cert_private_key.pem
        uid: '1000'
        gid: '1000'
        mode: 0400
```

定义证书的配置资源：
```sh 
docker config create \
    ch12_greetings_svc-prod-TLS_CERT_V1 api/config/insecure.crt 5a1lybiyjnaseg0jlwj2s1v5m
```

定义机密信息：
```sh 
cat api/config/insecure.key | \
docker secret create ch12_greetings-svc-prod-TLS_PRIVATE_KEY_V1 vnyy0gr1a09be0vcfvvqogeoj
```


查看机密资源信息：
```sh
docker secret inspect ch12_greetings-svc-prod-TLS_PRIVATE_KEY_V1
```

部署命令：
```sh
DEPLOY_ENV=prod docker stack deploy \
	--compose-file docker-compose.yml \
	--compose-file docker-compose.prod.yml \
	greetings_prod
```

检查服务日志：
```sh 
docker service logs --since 1m greetings_prod_api
```
