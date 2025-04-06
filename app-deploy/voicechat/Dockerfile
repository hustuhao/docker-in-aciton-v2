# 
# 第一阶段：Node.js 构建
FROM node:20 AS nodebuilder

WORKDIR /app/frontend

# 复制前端代码
COPY ./frontend .

# 安装并构建前端
RUN npm install && \
	npm run build

# 第二阶段：Python 环境
FROM ubuntu:24.04

# 安装 Python
ARG PYTHON_VERSION=3.10

# 安装 Python
RUN apt-get update && \
	apt-get install -y curl && \
	apt-get install -y software-properties-common && \
	add-apt-repository ppa:deadsnakes/ppa && \
	apt-get update && \
	apt-get install -y "python${PYTHON_VERSION}" "python${PYTHON_VERSION}-distutils" && \
	rm -rf /var/lib/apt/lists/* && \
	curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
	"python${PYTHON_VERSION}" get-pip.py && \
	rm get-pip.py

WORKDIR /app


# 从 Node.js 镜像复制构建好的前端静态文件
COPY --from=nodebuilder /app/frontend/build ./frontend/build

# 复制后端代码和配置文件
COPY backend ./backend
COPY app.py .
COPY requirements.txt .
RUN mkdir uploads

# 安装 Python 运行时依赖
RUN "python${PYTHON_VERSION}" -m pip install --no-cache-dir -r requirements.txt

# 配置运行环境
# RUN useradd -m voicechat
# RUN chmod -R 755 /app
# RUN chown -R voicechat:voicechat /app
# USER voicechat

EXPOSE 8000 3000

# HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
# CMD curl -f http://localhost:8000/ || exit 1

# 运行启动命令 start.sh
CMD ["/bin/bash"]
# CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]

# TODO 运行前端  cd front && npm start
