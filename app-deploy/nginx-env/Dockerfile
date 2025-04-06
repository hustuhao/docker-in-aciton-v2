# docker build -t optimized-nginx-neovim .
# Use Ubuntu as the base image
FROM ubuntu:24.04

# Set environment variables to reduce unnecessary interactions
ENV DEBIAN_FRONTEND=noninteractive

# Update and install Nginx, Neovim, essential network tools, and sudo
RUN apt-get update && apt-get install -y \
	nginx \
	neovim \
	iputils-ping \
	curl \
	dnsutils \
	git \
	sudo && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# Create a non-root user 'neovim' and add to sudoers with no password requirement
RUN groupadd -r neovim && \
	useradd -r -g neovim -m -s /bin/bash neovim && \
	echo "neovim ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/neovim

# Set the non-root user as the default user
USER neovim

# Set default command to launch bash
CMD ["/bin/bash"]

