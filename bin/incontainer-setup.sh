#!/usr/bin/env bash
set -e

# hard-code or export on the host before calling
SLURM_LOGIN="${SLURM_LOGIN:-10.130.0.6}"
PORT=$1

# ensure core tools work
export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

# 1) Install sshd & slurm-client if missing
if ! command -v sshd &>/dev/null; then
  if command -v apt-get &>/dev/null; then
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server slurm-client
  elif command -v yum &>/dev/null; then
    yum install -y openssh-server slurm-client
  fi
  mkdir -p /var/run/sshd
fi

# 2) Create SSH home and wrapper dir
mkdir -p "$HOME/.ssh" "$HOME/.local/bin"

# 3) Write Slurm-over-SSH wrappers
export PATH="$HOME/.local/bin:$PATH"
for cmd in sinfo squeue sbatch scancel; do
  cat > "$HOME/.local/bin/$cmd" <<EOX
#!/usr/bin/env sh
exec ssh -q $SLURM_LOGIN $cmd "\$@"
EOX
  chmod +x "$HOME/.local/bin/$cmd"
done

# 4) Generate VS Code host key
[ -f "$HOME/.ssh/vscode-remote-hostkey" ] || \
  ssh-keygen -t ed25519 -f "$HOME/.ssh/vscode-remote-hostkey" -N ''

# 5) Launch sshd on $PORT
exec /usr/sbin/sshd -D -p "$PORT" -h "$HOME/.ssh/vscode-remote-hostkey"
