# docker build -t my-neovim-dev:v0.0.1 -f my-neovim-dev_arm64.dockerfile .
# Use Ubuntu as the base image
FROM --platform=linux/arm64 ubuntu:22.04

# Set environment variables for mirrors
ENV DEBIAN_FRONTEND=noninteractive
ENV UBUNTU_MIRROR=https://mirrors.aliyun.com
ENV UBUNTU_DEFAULT_MIRROR=http://ports.ubuntu.com
ENV PYTHON_VERSION=3.12.5
ENV GO_VERSION=1.22.6
ENV JAVA_VERSION=openjdk-22.0.2
ENV LUA_VERSION=5.4.6
ENV NODE_VERSION=16.20.2
ENV NEOVIM_VERSION=v0.10.0
ENV NERD_FONT_VERSION=2.3.3

# Update and install basic dependencies
RUN apt-get update && apt-get install -y ca-certificates  && \
	sed -i "s|${UBUNTU_DEFAULT_MIRROR}|${UBUNTU_MIRROR}|g" /etc/apt/sources.list && \
	echo "Updated /etc/apt/sources.list:" && cat /etc/apt/sources.list && \
	apt-get update && apt-get install -y \
	build-essential \
	curl \
	wget \
	git \
	ca-certificates \
	gnupg \
	lsb-release \
	sudo \
	unzip \
	locales \
	tzdata \
	zlib1g-dev \
	fontconfig \
	ninja-build \
	gettext \
	libtool \
	libtool-bin \
	autoconf \
	automake \
	cmake \
	g++ \
	pkg-config \
	doxygen && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# Set locale and timezone
RUN locale-gen en_US.UTF-8 && \
	update-locale LANG=en_US.UTF-8 && \
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
	echo "Asia/Shanghai" > /etc/timezone

# Install Python from source
RUN wget https://mirrors.aliyun.com/python-release/source/Python-${PYTHON_VERSION}.tgz && \
	tar -xf Python-${PYTHON_VERSION}.tgz && \
	cd Python-${PYTHON_VERSION} && \
	./configure --enable-optimizations && \
	make -j $(nproc) && \
	make altinstall && \
	cd .. && \
	rm -rf Python-${PYTHON_VERSION} Python-${PYTHON_VERSION}.tgz

# Install Go
RUN wget https://mirrors.aliyun.com/golang/go${GO_VERSION}.linux-arm64.tar.gz && \
	tar -C /usr/local -xzf go${GO_VERSION}.linux-arm64.tar.gz && \
	rm go${GO_VERSION}.linux-arm64.tar.gz && \
	ln -s /usr/local/go/bin/go /usr/bin/go

# Install OpenJDK 22
RUN wget https://d6.injdk.cn/openjdk/openjdk/22/${JAVA_VERSION}_linux-aarch64_bin.tar.gz && \
	tar -xzf ${JAVA_VERSION}_linux-aarch64_bin.tar.gz -C /usr/local && \
	rm ${JAVA_VERSION}_linux-aarch64_bin.tar.gz

# Set Java environment variables
ENV JAVA_HOME="/usr/local/jdk-22.0.2"
ENV PATH="${JAVA_HOME}/bin:${PATH}"

RUN java -version

# Install Lua
RUN wget https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz && \
	tar -zxf lua-${LUA_VERSION}.tar.gz && \
	cd lua-${LUA_VERSION} && \
	make linux test && \
	make install && \
	cd .. && \
	rm -rf lua-${LUA_VERSION}*

# Install Node.js
RUN curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz | tar -xJf - -C /usr/local --strip-components=1

# Install Neovim from source
RUN git clone https://github.com/neovim/neovim && \
	cd neovim && \
	git checkout ${NEOVIM_VERSION} && \
	make CMAKE_BUILD_TYPE=Release && \
	make install && \
	cd .. && \
	rm -rf neovim 

# Install Nerd Font
RUN wget https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONT_VERSION}/FiraCode.zip && \
	unzip FiraCode.zip -d ~/.fonts && \
	fc-cache -fv && \
	rm FiraCode.zip

# Set up environment variables
ENV PATH="/usr/local/go/bin:/usr/local/nvim/bin:$PATH"

# Create a non-root user 'neovim'
RUN groupadd -r neovim && useradd -r -g neovim -m -s /bin/bash neovim

# Change ownership of the neovim config folder
# RUN chown -R neovim:neovim /home/neovim/.config/nvim

# Set the non-root user as the default user
USER neovim

# Clone Neovim configuration
RUN git clone https://github.com/hustuhao/my-lazy-nvim.git ~/.config/nvim


# Set default shell
CMD ["/bin/bash"]

