# This Dockerfile is reconstructed from docker history.
# It starts from the official NVIDIA CUDA 12.2.2 devel image for Ubuntu 22.04,
# which encapsulates the first several layers of the history.

FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive

ARG SYSTEM_DEPENDENCIES=" \
    # System utilities
    ca-certificates \
    curl \
    git \
    bash \
    htop \
    sudo \
    vim \
    nano \
    screen \
    tzdata \
    aria2 \
    openssh-server \
    software-properties-common \
    # Build tools
    build-essential \
    cmake \
    protobuf-compiler \
    # Audio libraries
    libasound-dev \
    portaudio19-dev \
    libportaudio2 \
    libportaudiocpp0 \
    libsox-dev \
    ffmpeg \
    # Image libraries
    libsm6 \
    libxext6 \
    libjpeg-dev \
    zlib1g-dev \
    # Python dependencies
    python3-dev \
    python3-pip \
    python3-venv \
    python3-setuptools \
    python3-wheel \
    "

# Install system dependencies
RUN set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends ${SYSTEM_DEPENDENCIES} && \
    rm -rf /var/lib/apt/lists/*

# Install uv for fast Python package management
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv

# Set the working directory for the application.
WORKDIR /opt/kisz-start

# zsh and oh-my-zsh are installed via devcontainer features.
# For development, we'll mount the workspace and install dependencies via postCreateCommand
# This allows for live code editing and proper development workflow.