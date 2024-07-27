将软件打包到镜像中

构建 Docker 镜像的两种方式：
- 通过修改容器中的现有镜像来构建镜像（本章内容）。
- 定义并执行 Dockerfile 脚本以构建镜像（第8章内容）。


# 7.1 从容器中构建镜像

打包 “hello world” 程序
```shell
# 1.修改容器中的文件
docker container run --name hw_container \
    ubuntu:latest \
    touch /HelloWorld

# 2.将更改提交给新的镜像
docker container commit hw_container hw_image

# 3.删除被修改的容器
docker container rm -vf hw_container

# 4.检查新容器中的文件
docker container run --rm \
    hw_image \
    ls -l /HelloWorld

# output
-rw-r--r-- 1 root root 0 Jul 27 02:25 /HelloWorld
```

准备打包 Git 程序
```shell
# 1.从基础镜像中创建容器
docker container  run -it --name image-dev ubuntu:latest /bin/bash

# 2.在容器中安装 Git 程序
apt-get update
apt-get -y install git

# 3.检查安装结果
git version

# 4.安装完成退出程序
exit

# 5.查看文件系统的修改
docker container diff image-dev

# 6.提交新的镜像,命名为 ubuntu-git
docker container commit -a "@ThisAuthorInfo" -m 'ThisIsCommitMessage' \
    image-dev ubuntu-git

# 7.在新建容器中测试 Git
docker container run --rm ubuntu-git git version
```

修改镜像入口
```shell
# 1.创建带有镜像入口点的容器
docker container run --name cmd-git --entrypoint git ubuntu-git

# 2.更新镜像
docker container commit -m "Set CMD git" \
    -a "@ThisAuthorInfo" cmd-git ubuntu-git

# 3.清理容器
docker container rm -vf cmd-git

# 4.测试
docker container run --name cmd-git unbuntu-git version
```

配置镜像的属性
```shell
# 1.创建带有环境变量的容器
docker container run --name rich-image-example \
    -e ENV_EXAMPLE1=Rich -e ENV_EXPLAMPLE2=Example

# 2.提交变更给镜像
docker container commit rich-image-example rie

# 3.检查环境变量是否设置正确
docker container run --rm rie \
    /bin/sh -c "echo \$ENV_EXAMPLE1 \$ENV_EXAMPLE2"
```


修改镜像，增加入口点设置。
```
docker container run --name rich-image-exmaple-2 \
    --entrypoint "/bin/sh" \
    rie \
    -c "echo \$ENV_EXAMPLE1 \$ENV_EXAMPLE2"

docker container commit rich-image-example-2 rie

docker container run --rm rie
```

# 7.2 深入研究 Docker 镜像和层级


深入理解容器的文件系统如何工作，理解 docker container commit
 命令实际的工作方式，能够帮助你成为更优秀的镜像作者。


联合文件系统
- 由层级组成，类似栈。（新层级总是被添加到栈的顶部）
- 写时复制机制

镜像就是由许多层级组合在一起的栈。


管理镜像大小和层级的限制

```shell
docker image tag
docker image ls 
docker image history
```

# 7.3 导入和导出平面文件系统

`docker container export` 命令用于导出 Docker 容器的文件系统，生成一个 tar 格式的文件。这对于备份容器的文件系统或将其转移到其他系统很有用。


# 7.4 版本控制的最佳实践

- 版本变化的最小单位级别定义和标记版本（明确使用的具体版本）
- 谨慎使用 latest 标签。
- 不仅要对软件进行版本控制，还要对软件的依赖进行版本控制。

