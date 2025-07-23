# Interactive SLURM SSH Sessions

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A set of scripts to simplify running interactive SSH sessions on SLURM compute nodes, particularly designed for use with tools like VSCode Remote-SSH. These scripts handle SLURM job submission, wait for the job to start, and proxy the connection, allowing you to seamlessly connect to a container on a compute node.

## Features

-   Start interactive jobs on CPU or GPU nodes.
-   Automatically manages SLURM job submission (`sbatch`) and cancellation (`scancel`).
-   Provides a direct SSH connection into a container running on the compute node.
-   Supports `enroot` containers (`.sqsh` files).
-   Configurable timeout for pending jobs.
-   Helper commands to `list`, `cancel`, and `ssh` into running jobs.
-   Easily configurable SLURM parameters for different job types.

## Prerequisites

-   Access to a SLURM-managed HPC cluster.
-   `enroot` installed on the cluster's compute nodes.
-   An `enroot` container image (e.g., a `.sqsh` file) available on the cluster's filesystem.
-   SSH access to a login node of the cluster.

## Installation

1.  **Clone the repository** to your local machine:
    ```bash
    git clone https://github.com/aihpi/interactive-slurm.git
    ```

2.  **Copy the scripts** to your home directory on the HPC login node. A common practice is to have a `~/bin` directory for user scripts.
    ```bash
    # On the HPC login node
    mkdir -p ~/bin
    # You can use scp or any other method to copy the files from the cloned repo
    scp /path/to/local/interactive-slurm/bin/* <HPC_LOGIN_NODE>:~/bin/
    ```

3.  **Make the scripts executable**:
    ```bash
    # On the HPC login node
    chmod +x ~/bin/start-ssh-job.bash ~/bin/ssh-session.bash
    ```
    Ensure `~/bin` is in your `$PATH` on the login node. If not, add it to your `~/.bashrc` or `~/.zshrc`.

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
    ProxyCommand ssh %h -l %u "~/bin/start-ssh-job.bash cpu /path/on/hpc/to/your/container.sqsh"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host slurm-gpu
    HostName <HPC_LOGIN_NODE_ADDRESS>
    User <YOUR_HPC_USERNAME>
    IdentityFile <PATH_TO_YOUR_SSH_KEY_FOR_HPC>
    ProxyCommand ssh %h -l %u "~/bin/start-ssh-job.bash gpu /path/on/hpc/to/your/gpu_container.sqsh"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**Replace the placeholders:**
-   `<HPC_LOGIN_NODE_ADDRESS>`: The hostname or IP address of your HPC's login node.
-   `<YOUR_HPC_USERNAME>`: Your username on the HPC cluster.
-   `<PATH_TO_YOUR_SSH_KEY_FOR_HPC>`: The path to the private SSH key you use to log in to the HPC.
-   `/path/on/hpc/to/your/container.sqsh`: The full path to your `enroot` container image on the HPC filesystem.

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