#!/bin/bash

# Use the provided container image path.
CONTAINER_IMAGE=$2

# If no container image is specified, exit.
if [ -z "$CONTAINER_IMAGE" ]; then
    echo "Error: No container image specified." >&2
    exit 1
fi

# Check if the container image exists
if [ ! -f "$CONTAINER_IMAGE" ]; then
    echo "Error: Container image not found at '$CONTAINER_IMAGE'" >&2
    exit 1
fi

enroot start --rw "$CONTAINER_IMAGE" bash -c '
if [ ! -d "${HOME:-~}.ssh" ]; then
    mkdir -p ${HOME:-~}/.ssh
fi

if [ ! -f "${HOME:-~}/.ssh/vscode-remote-hostkey" ]; then
    ssh-keygen -t ed25519 -f ${HOME:-~}/.ssh/vscode-remote-hostkey -N ""
fi

if [ -f "/usr/sbin/sshd" ]; then
    sshd_cmd=/usr/sbin/sshd
else
    sshd_cmd=sshd
fi
$sshd_cmd -D -p '$1' -f /dev/null -h ${HOME:-~}/.ssh/vscode-remote-hostkey
'