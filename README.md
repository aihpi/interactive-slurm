# Interactive SLURM SSH Sessions

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A set of scripts to simplify running interactive SSH sessions on SLURM compute nodes, particularly designed for use with tools like VSCode Remote-SSH. These scripts handle SLURM job submission, wait for the job to start, and proxy the connection, allowing you to seamlessly connect to a container on a compute node.

## Quick Start

For the impatient, here's a minimal setup:

```bash
# 1. Clone and install on HPC login node
git clone https://github.com/aihpi/interactive-slurm.git
mkdir -p ~/bin && cp interactive-slurm/bin/* ~/bin/
chmod +x ~/bin/*.bash

# 2. Add to your local ~/.ssh/config
Host slurm-cpu
    HostName YOUR_HPC_LOGIN_NODE
    User YOUR_USERNAME
    ProxyCommand ssh %h -l %u "bash ~/bin/start-ssh-job.bash cpu /sc/projects/sci-aisc/sqsh-files/pytorch_ssh.sqsh"

# 3. Connect from VSCode or terminal
ssh slurm-cpu
```

## Features

-   **Smart container management**: Automatically copies container images from shared locations (e.g., `/sc/projects`) to user home directories
-   **Full Slurm integration**: Containers have access to `srun`, `sbatch`, `scancel`, and other Slurm commands via SSH forwarding
-   **Architecture-aware scheduling**: CPU jobs target x86 nodes by default to avoid compatibility issues
-   **Automatic SSH setup**: Generates SSH host keys and configures SSH daemon within containers
-   **Resource-optimized defaults**: Sensible CPU (16GB, 4 cores) and GPU (32GB, 12 cores) job parameters
-   Start interactive jobs on CPU or GPU nodes
-   Automatically manages SLURM job submission (`sbatch`) and cancellation (`scancel`)
-   Provides a direct SSH connection into a container running on the compute node
-   Supports `enroot` containers (`.sqsh` files)
-   Configurable timeout for pending jobs
-   Helper commands to `list`, `cancel`, and `ssh` into running jobs
-   Easily configurable SLURM parameters for different job types

## Prerequisites

-   Access to a SLURM-managed HPC cluster.
-   `enroot` installed on the cluster's compute nodes.
-   An `enroot` container image (e.g., a `.sqsh` file) available on the cluster's filesystem.
-   SSH access to a login node of the cluster.

## Installation

### Option 1: Direct Installation on HPC (Recommended)

```bash
# On the HPC login node
cd ~/
git clone https://github.com/aihpi/interactive-slurm.git
mkdir -p ~/bin && cp interactive-slurm/bin/* ~/bin/
chmod +x ~/bin/*.bash
```

### Option 2: Local Clone + SCP Transfer

1.  **Clone the repository** to your local machine:
    ```bash
    git clone https://github.com/aihpi/interactive-slurm.git
    ```

2.  **Copy the scripts** to your HPC login node:
    ```bash
    # From your local machine
    scp interactive-slurm/bin/* <HPC_LOGIN_NODE>:~/bin/
    ```

3.  **Make scripts executable** on the HPC:
    ```bash
    # On the HPC login node
    chmod +x ~/bin/*.bash
    ```

**Note**: Ensure `~/bin` is in your `$PATH` on the login node. Add this to your `~/.bashrc` if needed:
```bash
export PATH="$HOME/bin:$PATH"
```

## Configuration

### Local SSH Config for VSCode Remote

To make this work seamlessly with VSCode, you need to configure your local `~/.ssh/config` file. This tells SSH how to connect to your SLURM jobs via the login node.

Add entries like the following to your `~/.ssh/config` on your **local machine**:

```ssh-config
# In your ~/.ssh/config on your LOCAL machine

Host slurm-cpu
    HostName <HPC_LOGIN_NODE_ADDRESS>
    User <YOUR_HPC_USERNAME>
    IdentityFile <PATH_TO_YOUR_SSH_KEY_FOR_HPC>
    ProxyCommand ssh %h -l %u "~/bin/start-ssh-job.bash cpu /sc/projects/sci-aisc/sqsh-files/pytorch_ssh.sqsh"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host slurm-gpu
    HostName <HPC_LOGIN_NODE_ADDRESS>
    User <YOUR_HPC_USERNAME>
    IdentityFile <PATH_TO_YOUR_SSH_KEY_FOR_HPC>
    ProxyCommand ssh %h -l %u "~/bin/start-ssh-job.bash gpu /sc/projects/sci-aisc/sqsh-files/pytorch_ssh.sqsh"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**Replace the placeholders:**
-   `<HPC_LOGIN_NODE_ADDRESS>`: The hostname or IP address of your HPC's login node.
-   `<YOUR_HPC_USERNAME>`: Your username on the HPC cluster.
-   `<PATH_TO_YOUR_SSH_KEY_FOR_HPC>`: The path to the private SSH key you use to log in to the HPC.
-   The container path `/sc/projects/sci-aisc/sqsh-files/pytorch_ssh.sqsh` is an example - replace with your actual container image path.

**Container Path Flexibility**: 
- Container images in `/sc/projects` are automatically copied to your home directory for faster access
- You can use paths like `/sc/projects/shared/pytorch.sqsh` - they'll be cached as `~/pytorch.sqsh`
- Local container files in your home directory are used directly

### Script Configuration

You can customize the SLURM job parameters and job timeout by editing the variables at the top of the `start-ssh-job.bash` script:

-   `SBATCH_PARAM_CPU`: sbatch parameters for CPU jobs.
-   `SBATCH_PARAM_GPU`: sbatch parameters for GPU jobs.
-   `TIMEOUT`: The time in seconds the script will wait for a job to start before giving up.

## Usage

All commands (except for the initial SSH connection) should be run on the **HPC login node**.

### Connecting with VSCode or SSH

Once your `~/.ssh/config` is set up, you can connect:

-   **From VSCode**: Use the "Remote Explorer" extension, find `slurm-cpu` or `slurm-gpu` in the list of SSH targets, and click the connect icon.
-   **From your terminal**:
    ```bash
    ssh slurm-cpu
    ```

This will trigger the `ProxyCommand`, which runs `start-ssh-job.bash` on the login node to request a compute node and establish the connection.

### Listing Running Jobs

To see your running interactive jobs managed by this script:

```bash
~/bin/start-ssh-job.bash list
```

### Cancelling Jobs

To cancel all running interactive jobs (both CPU and GPU):

```bash
~/bin/start-ssh-job.bash cancel
```

### SSH into a Compute Node

If you have a running job and want a direct shell on the compute node itself (not inside the container), you can use the `ssh` command:

```bash
~/bin/start-ssh-job.bash ssh
```

If you have both a CPU and a GPU job running, it will prompt you to choose which node to connect to.

## How It Works

1.  Your local SSH client connects to the HPC login node and executes the `ProxyCommand`.
2.  The `start-ssh-job.bash` script runs on the login node.
3.  It checks if a suitable job (`vscode-remote-cpu` or `vscode-remote-gpu`) is already running.
4.  If not, it submits a new SLURM job using `sbatch`, requesting a compute node and launching the `ssh-session.bash` script on it. A random port is chosen for the SSH session.
5.  On the compute node, `ssh-session.bash` starts your specified `enroot` container.
6.  Inside the container, it starts an `sshd` server on the allocated port, creating a temporary host key for the session.
7.  Meanwhile, on the login node, `start-ssh-job.bash` polls `squeue` until the job's state is `RUNNING`.
8.  Once the job is running, it waits for the `sshd` port to become active on the compute node.
9.  Finally, it uses `nc` (netcat) to create a tunnel, piping the SSH connection from the login node to the `sshd` daemon inside the container.
10. Your local SSH client can now communicate with the SSH server running in your container on the compute node.


## Troubleshooting

### Common Issues

**"Container image not found" error:**
- Make sure the container path in your SSH config is correct
- For `/sc/projects` paths, the script will automatically try to copy the file to your home directory
- Check that the `.sqsh` file exists and is readable

**"enroot-mount: failed to mount" error:**
- This usually means the compute node has different library paths than the login node
- Try adding `--constraint=ARCH:X86` to your job parameters to use x86 nodes
- The scripts already include this for CPU jobs by default

**Job stays in PENDING state:**
- Check cluster resources with `sinfo` or `squeue`
- Your requested resources (CPU, memory, GPU) might be too high
- Try reducing resource requirements in the script configuration

**SSH connection timeout:**
- Increase the `TIMEOUT` value in `start-ssh-job.bash` (default: 300 seconds)
- Check that your SSH key authentication works for the HPC login node
- Verify that `~/bin` is in your PATH on the login node

**VSCode Remote connection fails:**
- Make sure your local SSH config syntax is correct
- Test the connection manually with `ssh slurm-cpu` from your terminal first
- Check the job logs with `~/bin/start-ssh-job.bash list`

### Getting Help

1. Check the job logs on the HPC login node: `cat job.logs`
2. List running jobs: `~/bin/start-ssh-job.bash list`
3. Cancel stuck jobs: `~/bin/start-ssh-job.bash cancel`

## Based on
Thank you to https://github.com/gmertes/vscode-remote-hpc for creating the base of these scripts.