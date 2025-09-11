#!/bin/bash

# Use the provided container image path.
CONTAINER_IMAGE=$2
# If no container image is specified, exit.
if [ -z "$CONTAINER_IMAGE" ]; then
    echo "Error: No container image specified." >&2
    exit 1
fi

# Handle /sc/projects paths by copying to home directory if needed
if [[ "$CONTAINER_IMAGE" =~ ^/sc/projects ]]; then
    # Extract filename from the path
    SQSH_FILENAME=$(basename "$CONTAINER_IMAGE")
    LOCAL_SQSH_PATH="$HOME/$SQSH_FILENAME"
    
    # If local copy doesn't exist, try to copy from /sc/projects
    if [ ! -f "$LOCAL_SQSH_PATH" ]; then
        echo "Copying $CONTAINER_IMAGE to $LOCAL_SQSH_PATH..."
        if cp "$CONTAINER_IMAGE" "$LOCAL_SQSH_PATH" 2>/dev/null; then
            echo "✅ Successfully copied sqsh file to home directory"
            CONTAINER_IMAGE="$LOCAL_SQSH_PATH"
        else
            echo "⚠️ Could not copy from /sc/projects, will try to use original path in container"
        fi
    else
        echo "ℹ️ Using existing sqsh file: $LOCAL_SQSH_PATH"
        CONTAINER_IMAGE="$LOCAL_SQSH_PATH"
    fi
else
    # Check if the container image exists for non-/sc/projects paths
    if [ ! -f "$CONTAINER_IMAGE" ]; then
        echo "Error: Container image not found at '$CONTAINER_IMAGE'" >&2
        exit 1
    fi
fi

# Define the marker string to check if already added
MARKER="# >>> Slurm-over-SSH (auto-added) <<<"

# Only add block if it doesn't already exist
if ! grep -Fxq "$MARKER" "$HOME/.bashrc"; then
  cat >> "$HOME/.bashrc" <<'EOF'

# >>> Slurm-over-SSH (auto-added) <<<
if ! command -v sinfo >/dev/null 2>&1; then
  export SLURM_LOGIN=10.130.0.6

  sinfo()  { ssh -q "$SLURM_LOGIN" sinfo  "$@"; }
  squeue() { ssh -q "$SLURM_LOGIN" squeue "$@"; }
  sbatch() { ssh -q "$SLURM_LOGIN" sbatch "$@"; }
  srun() { ssh -q "$SLURM_LOGIN" srun "$@"; }
  scancel(){ ssh -q "$SLURM_LOGIN" scancel "$@"; }
fi
# <<< Slurm-over-SSH (auto-added) >>>
EOF

  echo "✅ Slurm SSH aliases added to ~/.bashrc"
else
  echo "ℹ️ Slurm SSH aliases already present"
fi

enroot start \
  --rw \
  --mount /usr/bin/srun:/usr/bin/srun \
  --mount /usr/bin/sbatch:/usr/bin/sbatch \
  --mount /usr/bin/scancel:/usr/bin/scancel \
  --mount /usr/lib/x86_64-linux-gnu/libslurm.so.41:/usr/lib/x86_64-linux-gnu/libslurm.so.41 \
  --mount /usr/lib/x86_64-linux-gnu/libslurm.so.41.0.0:/usr/lib/x86_64-linux-gnu/libslurm.so.41.0.0 \
  --mount /usr/lib/x86_64-linux-gnu/slurm-wlm:/usr/lib/x86_64-linux-gnu/slurm-wlm \
  --mount /usr/lib/x86_64-linux-gnu/libmunge.so.2:/usr/lib/x86_64-linux-gnu/libmunge.so.2 \
  "$CONTAINER_IMAGE" bash -c '
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

