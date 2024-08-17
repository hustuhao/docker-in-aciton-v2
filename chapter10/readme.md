第 10 章 镜像构建管道


# 10.1 镜像构建管道的目标
管道的目标：使构建、测试和发布镜像的过程完全自动化，将镜像自动部署到运行时环境。


# 10.2 构建镜像的模式
构建镜像的模式：
- 多合一镜像: 包含所需的多种环境。
- 构建 + 运行时版本：构建和运行时环境分离。
- 构建 + 多运行时版本：多阶段构建，支持不同的运行环境（调试、专用测试或性能分析）


定义 app-image 阶段
```dockerfile
FROM openjdk:11-jdk-slim as app-image
```

基于 app-image 定义 app-image-debug 阶段
```dockerfile
FROM app-image as app-image-debug
```

# 10.3 在构建镜像时记录元数据

使用元数据对镜像进行数据：LABEL 命令

# 10.4 在镜像构建管道中测试镜像

类似软件开发中的测试用例，在镜像构建过程中对镜像进行测试，确保镜像符合预期。

使用工具：[container-structure-test](https://github.com/GoogleContainerTools/container-structure-test)

# 10.5 标记镜像的模式

镜像应该打上标签，以便消费者找到并使用。
