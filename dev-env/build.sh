#!/bin/bash
# 用法 bash build.sh v0.0.3

# 从环境变量中读取配置
IMAGE_NAME=${IMAGE_NAME:-$1}
DOCKERFILE=${DOCKERFILE:-"DockerfileV3.df"}
REMOTE_HOSTS_URL=${REMOTE_HOSTS_URL:-"https://hosts.gitcdn.top/hosts.txt"}
TEMP_HOSTS_FILE=${TEMP_HOSTS_FILE:-"./temp_hosts"}
BUILD_GITHUB_MIRROR_URL=${BUILD_GITHUB_MIRROR_URL:-"https://ghfast.top/https://github.com"}
ALIYUN_REGISTRY=${ALIYUN_DOCKER_REGISTRY:-"registry.cn-hangzhou.aliyuncs.com"}
ALIYUN_NAMESPACE=${ALIYUN_DOCKER_NAMESPACE_TURATO:-"turato"}
ALIYUN_REPO_NAME=${ALIYUN_DOCKER_REPO_DEV:-"my-neovim-dev"}
ALIYUN_USERNAME=${ALIYUN_DOCKER_USERNAME:-"your_username"}
ALIYUN_PASSWORD=${ALIYUN_DOCKER_PASSWORD:-"your_pwd"}

# 根据环境变量生成镜像完整标签
ALIYUN_IMAGE_TAG="$ALIYUN_REGISTRY/$ALIYUN_NAMESPACE/$ALIYUN_REPO_NAME:$IMAGE_NAME"

ROOT_PASSWORD=${IMAGE_ROOT_PASSWORD:-"rootpassword"}

# 更新 hosts 文件
update_hosts_file() {
	echo "Updating hosts file..."
	curl -s $REMOTE_HOSTS_URL >$TEMP_HOSTS_FILE

	if [ $? -ne 0 ]; then
		echo "Error: Failed to download hosts file from $REMOTE_HOSTS_URL"
		exit 1
	fi

	echo "Updated hosts file:"
	cat $TEMP_HOSTS_FILE
}

# 构建 Docker 镜像
build_docker_image() {
	echo "Building Docker image..."
	docker build --build-arg HOSTS_FILE=$TEMP_HOSTS_FILE --build-arg GIT_HUB_MIRROR_URL=$BUILD_GITHUB_MIRROR_URL --build-arg ROOT_PASSWORD=$ROOT_PASSWORD -t $IMAGE_NAME -f $DOCKERFILE .

	if [ $? -eq 0 ]; then
		echo "Docker image $IMAGE_NAME built successfully!"
	else
		echo "Error: Docker image build failed."
		exit 1
	fi
}

# 登录到阿里云镜像仓库
login_to_aliyun() {
	echo "Logging in to Aliyun Docker registry..."
	docker login --username=$ALIYUN_USERNAME --password=$ALIYUN_PASSWORD $ALIYUN_REGISTRY

	if [ $? -ne 0 ]; then
		echo "Error: Failed to log in to Aliyun Docker registry."
		exit 1
	fi
}

# 为镜像打标签
tag_docker_image() {
	echo "Tagging Docker image..."
	docker tag $IMAGE_NAME $ALIYUN_IMAGE_TAG

	if [ $? -eq 0 ]; then
		echo "Docker image tagged as $ALIYUN_IMAGE_TAG successfully!"
	else
		echo "Error: Failed to tag Docker image."
		exit 1
	fi
}

# 推送镜像到阿里云
push_docker_image() {
	echo "Pushing Docker image to Aliyun registry..."
	docker push $ALIYUN_IMAGE_TAG

	if [ $? -eq 0 ]; then
		echo "Docker image pushed to Aliyun registry successfully!"
	else
		echo "Error: Failed to push Docker image to Aliyun registry."
		exit 1
	fi
}

# 清理临时文件
cleanup_temp_files() {
	rm -f $TEMP_HOSTS_FILE
	echo "Temporary hosts file removed."
}

# 主函数
main() {
	update_hosts_file
	build_docker_image
	login_to_aliyun
	tag_docker_image
	push_docker_image
	cleanup_temp_files
	echo "All tasks completed successfully!"
}

# 执行主函数
main
