#!/bin/bash

# 设置å~O~Xé~G~O
IMAGE_NAME="my-neovim-dev:v0.0.2"
DOCKERFILE="Dockerfile"
REMOTE_HOSTS_URL="https://hosts.gitcdn.top/hosts.txt"
TEMP_HOSTS_FILE="./temp_hosts"
BUILD_GITHUB_MIRROR_URL="https://ghfast.top/https://github.com"

# æ~[´æ~V° hosts æ~V~G件
echo "Updating hosts file..."
curl -s $REMOTE_HOSTS_URL >$TEMP_HOSTS_FILE

if [ $? -ne 0 ]; then
	echo "Error: Failed to download hosts file from $REMOTE_HOSTS_URL"
	exit 1
fi

# æ~I~Så~M°æ~[´æ~V°å~P~Nç~Z~D hosts æ~V~G件
echo "Updated hosts file:"
cat $TEMP_HOSTS_FILE

# æ~^~D建é~U~\å~C~O
echo "Building Docker image..."
docker build --build-arg HOSTS_FILE=$TEMP_HOSTS_FILE --build-arg GIT_HUB_MIRROR_URL=$BUILD_GITHUB_MIRROR_URL -t $IMAGE_NAME -f $DOCKERFILE .

if [ $? -eq 0 ]; then
	echo "Docker image $IMAGE_NAME built successfully!"
else
	echo "Error: Docker image build failed."
	exit 1
fi
