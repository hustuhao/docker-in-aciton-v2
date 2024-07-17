# docker-in-aciton-v2

本仓库手巧了一遍 docker-in-action 2th 书籍的代码。

相关环境:
- 计算机: MacBookPro 
- 芯片: Apple M1 Pro
- OS: macOS Ventura 13.1

因为使用的是 MacBookPro，所以需要对书中的代码略微进行修改。
例如：书中的某些镜像没有支持 linux/arm/v8 平台，所以使用--platform 参数指定平台为 M1 芯片 支持的平台 linux/amd64

参考
- https://yeasy.gitbook.io/docker_practice
