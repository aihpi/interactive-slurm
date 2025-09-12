# Interactive SLURM SSH Sessions

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A set of scripts to simplify running interactive SSH sessions on SLURM compute nodes, particularly designed for use with tools like VSCode Remote-SSH. These scripts handle SLURM job submission, wait for the job to start, and proxy the connection, allowing you to seamlessly connect to a container on a compute node.

## 🚀 Quick Start

**Automated Setup** - Just run one command and follow the prompts:

### 📱 **On Your Local Machine:**
```bash
git clone https://github.com/aihpi/interactive-slurm.git
cd interactive-slurm
./setup.sh
```

That's it! The setup script will:
- ✅ Generate SSH keys automatically
- ✅ Copy keys to your HPC cluster  
- ✅ Install scripts on the remote cluster
- ✅ Configure SSH settings
- ✅ Set up VSCode integration
- ✅ Handle container options (optional)

### 🎯 **Connect Immediately After Setup:**
```bash
# Direct compute node access (no container)
ssh slurm-cpu     # CPU job
ssh slurm-gpu     # GPU job

# Or with containers (if configured)
ssh slurm-cpu-container
ssh slurm-gpu-container
```

### 💻 **VSCode Users:**
1. Install the Remote-SSH extension
2. Press `Ctrl/Cmd+Shift+P` → "Remote-SSH: Connect to Host"
3. Select `slurm-cpu`, `slurm-gpu`, or container variants

## ✨ Features

- 🚀 **One-Command Setup**: Automated installation with interactive prompts
- 🐳 **Optional Containers**: Use with or without enroot containers (`.sqsh` files)
- 📁 **Smart Container Management**: Auto-copies from `/sc/projects` to home directory
- 🔗 **Full SLURM Integration**: Access to `srun`, `sbatch`, `scancel` commands
- 🎯 **VSCode Ready**: Perfect integration with Remote-SSH extension
- ⚡ **Resource Optimized**: Sensible defaults (CPU: 16GB/4cores, GPU: 32GB/12cores)
- 🏗️ **Architecture Aware**: Targets x86 nodes to avoid compatibility issues
- 🔧 **Easy Management**: List, cancel, and monitor jobs with simple commands
- 🔐 **Secure**: Automatic SSH key generation and distribution

## 📋 Prerequisites

- Access to a SLURM-managed HPC cluster
- SSH access to the cluster's login node
- `enroot` installed on compute nodes (only if using containers)
- VSCode with [Remote-SSH extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) (optional)

## 📖 Complete Tutorial

### Step 1: **📱 On Your Local Machine**

Clone the repository and run the setup script:

```bash
git clone https://github.com/aihpi/interactive-slurm.git
cd interactive-slurm
./setup.sh
```

### Step 2: **Follow the Interactive Prompts**

The setup script will ask you:

1. **HPC Login Node**: Enter your cluster's hostname
   ```
   HPC Login Node (hostname or IP) [login.hpc.university.edu]: login.your-cluster.edu
   ```

2. **Your Username**: Enter your HPC username
   ```
   Your username on the HPC cluster [john.doe]: your.username
   ```

3. **Container Usage**: Choose whether to use containers
   ```
   Do you want to use containers? [Y/n]: y
   ```

4. **Container Source**: If using containers, specify where to get them
   ```
   Do you have containers in /sc/projects that you want to copy? [Y/n]: y
   Container path to copy: /sc/projects/sci-aisc/sqsh-files/pytorch_ssh.sqsh
   ```

### Step 3: **✅ Automatic Configuration**

The script will automatically:
- Generate SSH keys (`~/.ssh/interactive-slurm`)
- Copy the public key to your HPC cluster
- Install scripts on the HPC cluster
- Configure your local SSH settings
- Set up VSCode integration
- Test the connection

### Step 4: **🚀 Start Using!**

After setup completes, you can immediately connect:

#### **Command Line:**
```bash
ssh slurm-cpu              # CPU job, direct access
ssh slurm-gpu              # GPU job, direct access  
ssh slurm-cpu-container    # CPU job with container
ssh slurm-gpu-container    # GPU job with container
```

#### **VSCode:**
1. Open VSCode
2. Press `Ctrl/Cmd+Shift+P`
3. Type "Remote-SSH: Connect to Host"
4. Select your desired host (e.g., `slurm-cpu`)
5. VSCode will connect to a compute node automatically!

## 🧪 Testing Your Setup

### Quick Connection Test

Try connecting via command line first:

```bash
# Test CPU connection (should submit a job and connect)
ssh slurm-cpu
```

### **🖥️ On the HPC Cluster** - Manage Your Jobs

Once connected, or via direct SSH to the login node:

```bash
# List your running interactive jobs
~/bin/start-ssh-job.bash list

# Cancel all your interactive jobs  
~/bin/start-ssh-job.bash cancel

# Get help
~/bin/start-ssh-job.bash help
```

### Expected Behavior

1. **First Connection**: Takes 30s-5min (job needs to start)
2. **Job Submission**: You'll see "Submitted new vscode-remote-cpu job"
3. **Connection**: Eventually connects to compute node
4. **Subsequent Connections**: Should reuse existing job (faster)

### ✅ Testing Checklist

Before reporting issues, verify:

- [ ] **📱 Local:** SSH key works: `ssh -i ~/.ssh/interactive-slurm user@hpc`
- [ ] **🖥️ HPC:** Scripts installed: `ls ~/bin/start-ssh-job.bash`
- [ ] **🖥️ HPC:** SLURM works: `squeue --me`
- [ ] **📱 Local:** SSH config generated: `grep slurm-cpu ~/.ssh/config`
- [ ] **📱 Local:** Basic connection: `ssh slurm-cpu`
- [ ] **📱 Local:** VSCode extension installed: Remote-SSH
- [ ] **🖥️ HPC:** Container exists (if used): `ls ~/your-container.sqsh`

## Manual Configuration (Advanced Users)

### Local SSH Config for VSCode Remote

To make this work seamlessly with VSCode, you need to configure your local `~/.ssh/config` file. This tells SSH how to connect to your SLURM jobs via the login node.

Add entries like the following to your `~/.ssh/config` on your **local machine**:

```ssh-config
# In your ~/.ssh/config on your LOCAL machine

Host slurm-cpu
    HostName login.hpc.yourcluster.edu
    User john.doe
    IdentityFile ~/.ssh/id_ed25519
    ConnectTimeout 30
    ProxyCommand ssh login.hpc.yourcluster.edu -l john.doe "~/bin/start-ssh-job.bash cpu /sc/projects/sci-aisc/sqsh-files/pytorch_ssh.sqsh"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host slurm-gpu
    HostName login.hpc.yourcluster.edu
    User john.doe
    IdentityFile ~/.ssh/id_ed25519
    ConnectTimeout 30
    ProxyCommand ssh login.hpc.yourcluster.edu -l john.doe "~/bin/start-ssh-job.bash gpu /sc/projects/sci-aisc/sqsh-files/pytorch_ssh.sqsh"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**Replace with your actual values:**
-   `HostName login.hpc.yourcluster.edu`: Replace with your HPC login node address (e.g., `login.cluster.university.edu` or IP like `192.168.1.100`)
-   `User john.doe`: Replace with your HPC cluster username
-   `IdentityFile ~/.ssh/id_ed25519`: Path to your SSH private key (use `~/.ssh/id_rsa` if you have an RSA key)
-   Container path `/sc/projects/sci-aisc/sqsh-files/pytorch_ssh.sqsh`: Replace with your actual container image path

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


## 🛠️ Troubleshooting

### Setup Issues

**❌ "SSH connection test failed" during setup:**
```bash
# Verify basic SSH access manually
ssh your.username@login.your-cluster.edu

# Check if SSH key was copied correctly
ssh -i ~/.ssh/interactive-slurm your.username@login.your-cluster.edu
```

**❌ "Failed to copy container file":**
- Container path might not exist: check `/sc/projects/...` path
- **🖥️ On HPC cluster:** manually copy with `cp /sc/projects/path/container.sqsh ~/`

### Connection Issues

**⏱️ Connection takes too long (>5 minutes):**
```bash
# Check job queue status
ssh login.your-cluster.edu
squeue --me  # See if your jobs are pending
```

**❌ "Connection refused" or immediate disconnection:**
```bash
# 📱 On local machine: Check if job is actually running
ssh login.your-cluster.edu "~/bin/start-ssh-job.bash list"

# Cancel stuck jobs and try again  
ssh login.your-cluster.edu "~/bin/start-ssh-job.bash cancel"
```

**❌ VSCode connection fails:**
1. **First, test command line:** `ssh slurm-cpu`
2. **Check VSCode settings:** `remote.SSH.connectTimeout` should be ≥300
3. **View connection logs:** VSCode → Output → Remote-SSH

### Container Issues

**❌ "Container image not found":**
- **🖥️ On HPC cluster:** Check file exists: `ls ~/your-container.sqsh`
- For `/sc/projects` paths, setup should auto-copy to home directory

**❌ "enroot-mount failed":**
- CPU jobs use x86 nodes by default (should prevent this)
- **🖥️ On HPC cluster:** Verify enroot works: `enroot list`

### Job Issues

**⏸️ Job stays PENDING:**
- **🖥️ On HPC cluster:** Check resources: `sinfo` and `squeue`
- Reduce resource requirements in `~/bin/start-ssh-job.bash`

**🔄 Multiple jobs created:**
- Each SSH connection creates a separate job
- **🖥️ On HPC cluster:** Clean up: `~/bin/start-ssh-job.bash cancel`

### Getting Help

1. Check the job logs on the HPC login node: `cat job.logs`
2. List running jobs: `~/bin/start-ssh-job.bash list`
3. Cancel stuck jobs: `~/bin/start-ssh-job.bash cancel`

## Based on
Thank you to https://github.com/gmertes/vscode-remote-hpc for creating the base of these scripts.
