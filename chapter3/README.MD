


Docker 安装软件的三个步骤:
- 1.识别想要安装的软件
  - a.使用 Docker 注册表
  - b.使用 Docker 命令操作镜像文件
  - c.使用 Dockerfile 构建镜像
- 2.定位要安装的软件
- 3.软件所需哪些文件以及文件的隔离

# 3.1 识别软件

什么是镜像？
- 镜像是包含两类的数据的文件
  - a.用于创建容器的文件
  - b.以及镜像的元数据:标签(tag)、环境变量、默认的执行上下文、镜像的命令操作记录等。
- 每个镜像都有全局唯一的标识符，但是用户难以记忆，通常用命名仓库取而代之。

命名仓库可以拦截为已命名的容纳了镜像文件的收纳箱，其名称在形式上类似 URL: {镜像所在主机的名称}/{用户名或者组织名}/{镜像简称}:{标签}，
比如 `quay.io/dockerinaction/ch3_hellp_registry:latest

标签:相当于镜像的版本，上述镜像名称中，latest 表示使用最新的版本。可以选择其他的版本，比如v1,v2。


## 3.2 寻找和安装软件


### 利用注册表安装软件

注册表:理解为镜像仓库。

```shell
docker pull quay.io/dockerinaction/ch3_hello_registry:latest
```

```shell
docker rmi ch3_hellp_registry:latest
```

`docker rmi` 命令是 docker image rm 简写。个人推荐刚接触这些命令的时候，不使用缩写，等到后面熟悉时再使用缩写。
```shell
docker image rm quay.io/dockerinaciton/ch3_hello_registry:latest
```

### 利用镜像文件安装软件

打包镜像文件，分发给需要的人:
```shell
docker save --output myfile.tar busybox:latest
```

删除镜像:
```shell
docker image rm busybox
```
有可能会出现面的错误:原因是有容器依赖该镜像，需要先把依赖的镜像删除或者使用强制删除参数。
```text
Error response from daemon: conflict: unable to remove repository reference "busybox" (must force) - container 354127391cb7 is using its referenced image 3772266d7498
```

从镜像文件加载镜像:
```shell
docker load --input myfile.tar
```

输出: 成功加载镜像 busybox:latest
```text
464371b65142: Loading layer [==================================================>]  4.273MB/4.273MB
Loaded image: busybox:latest
```


解压 myfile.tar 到当前目录下的 myfile 文件夹中
```shell
mkdir myfile 
tar -xf myfile.tar -C myfile 
```

查看 myfile 文件夹目录结构
```text
.
├── 3772266d7498c8df7461f1897f6961cdbc71c63c56c213829d56b9c88bea7634.json
├── a8e6ddc59118922948b79d8cc1689aa27557eeaad1f8d074196937e5a8ef68f6
│   ├── VERSION
│   ├── json
│   └── layer.tar
├── manifest.json
└── repositories
```

### 从 Dockerfile 安装软件

Dockerfile 是用来描述 Docker 构建新镜像步骤的脚本，可以理解为构建镜像的指南。（具体内容查看第8章）

下载网上的 Dockerfile 示例
```shell
git clone https://github.com/dockerinaction/ch3_dockerfile.git
```

```shell
docker build --tag dia_ch3/h3_dockerfile:latest ch3_dockerfile
```

清理工作区
```shell
docker image rm dia_ch3/h3_dockerfile
rm -rf ch3_dockerfile
```


## 安装和文件隔离

镜像层级
```shell
docker pull dockerinaction/ch3_myapp
```
输出：

```text
Using default tag: latest
latest: Pulling from dockerinaction/ch3_myapp
f5d23c7fed46: Pull complete 
eaa7ca9a16a1: Pull complete 
d7d34b884c95: Pull complete 
d0f024ff373b: Pull complete 
9384c9efb97d: Pull complete 
a7e74b426681: Pull complete 
6f1c51bc28c2: Pull complete 
ce0e70589db8: Pull complete 
df420ec9fa4c: Pull complete 
Digest: sha256:2e492fedd50d9d4ef5e8ea92c32795c3f53836199322cb85eafb93c2e139b3f1
Status: Downloaded newer image for dockerinaction/ch3_myapp:latest
docker.io/dockerinaction/ch3_myapp:latest
```
Docker 镜像可以由多个层组成，每一层都可以被镜像复用。有关映像、层和内容可寻址存储的更多信息，请参见官方文档:[理解映像、容器和存储驱动程序](https://docs.docker.com/storage/storagedriver/)。

在上面的例子中，镜像 dockerinaction/ch3_myapp 由多层组成;下面每一行都算作一层
```text
f5d23c7fed46: Pull complete 
eaa7ca9a16a1: Pull complete 
d7d34b884c95: Pull complete 
d0f024ff373b: Pull complete 
9384c9efb97d: Pull complete 
a7e74b426681: Pull complete 
6f1c51bc28c2: Pull complete 
ce0e70589db8: Pull complete 
df420ec9fa4c: Pull complete
```

https://docs.docker.com/engine/reference/commandline/pull/#options

参考：
https://docs.docker.com/get-started/09_image_best/#image-layering
https://docs.docker.com/build/guide/layers/
https://docs.docker.com/scout/image-details-view/