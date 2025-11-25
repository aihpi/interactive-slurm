# Developer Documentation

This document contains technical implementation details, architecture information, and developer guidance for Interactive SLURM SSH Sessions.

## Architecture Overview

Interactive SLURM is built as a layered SSH proxy system that:

1. **Local SSH Client** → **Login Node ProxyCommand** → **SLURM Job Submission** → **Compute Node** → **Container/SSH Server**

2. **Components**:
   - `setup.sh` - Installation and configuration
   - `start-ssh-job.bash` - SLURM job management on login node
   - `ssh-session.bash` - Container/SSH server startup on compute node
   - Auto-update system - Git-based remote updates

## File Structure

```
interactive-slurm/
├── setup.sh                    # Main installation script
├── bin/
│   ├── start-ssh-job.bash     # Job management and proxy command
│   ├── ssh-session.bash       # Container/SSH server launcher
│   └── incontainer-setup.sh   # Container initialization
├── templates/                  # Configuration templates
│   ├── ssh-config.template
│   ├── config.template
│   └── profiles/              # SLURM resource profiles
├── README.md                  # User documentation
├── DEV.md                     # This file
└── TUTORIAL.md               # Cross-platform setup guide
```

## Core Components

### setup.sh
**Purpose**: Automated installation and configuration

**Functions**:
- SSH key generation and distribution
- Remote script installation
- SSH configuration generation
- VSCode integration setup
- Container path configuration

**Key Variables**:
- `CLUSTER_HOST` - HPC login node hostname
- `USERNAME` - HPC cluster username
- `CONTAINER_PATH` - Container image location
- `USE_CONTAINERS` - Enable/disable container support

### start-ssh-job.bash
**Purpose**: Central job management and SSH proxy coordination

**Primary Functions**:
- Job submission via `sbatch`
- Job state monitoring via `squeue`
- Port allocation and tunnel establishment
- Auto-update system integration
- Command routing for `remote` commands

**Job Management**:
```bash
# Job names and patterns
CPU_JOB_PATTERN="vscode-remote-cpu"
GPU_JOB_PATTERN="vscode-remote-gpu"

# Resource allocation
SBATCH_PARAM_CPU="--partition=aisc-interactive --time=8:00:00 --nodes=1 --tasks-per-node=4 --cpus-per-task=4 --mem=16GB"
SBATCH_PARAM_GPU="--partition=aisc-interactive --time=4:00:00 --nodes=1 --tasks-per-node=1 --gres=gpu:1 --constraint=x86"
```

**Auto-Update System**:
```bash
# Update configuration
UPDATE_VERSION_FILE="$HOME/.interactive-slurm.version"
UPDATE_LOG="$HOME/.interactive-slurm.update.log"
UPDATE_DIR="$HOME/.interactive-slurm.updates"
UPDATE_INTERVAL=86400  # 24 hours
REPO_URL="https://github.com/aihpi/interactive-slurm.git"
BRANCH="main"
```

**Commands Implemented**:
- `list` - Show running jobs
- `cancel` - Terminate all interactive jobs
- `check` - Manual update check
- `update` - Force update application
- `gpuswap` - Switch to GPU environment
- `ssh` - Direct compute node access
- `help` - Command reference

### ssh-session.bash
**Purpose**: Compute node session initialization

**Container Management**:
- `enroot` container startup
- SSH server configuration inside container
- Temporary host key generation
- Port binding and health monitoring

**Without Containers**:
- Direct SSH server on compute node
- No enroot dependency
- Simplified resource allocation

**Process Flow**:
```bash
1. Container startup: enroot start --mount $CONTAINER_PATH
2. SSH server init: /usr/sbin/sshd -p $SSH_PORT
3. Health check: netstat/nc port validation
4. Exit: Clean container shutdown
```

### incontainer-setup.sh
**Purpose**: Container-specific initialization when needed

**Features**:
- Environment validation
- SSH service configuration
- Container health checks
- Resource validation

## Auto-Update System

### Overview
The auto-update system runs directly on the HPC cluster and fetches updates from the GitHub repository, eliminating the need for users to re-run the setup script.

### Implementation Details

**Update Flow**:
1. **Connection Trigger**: When user connects via `ssh slurm-cpu`
2. **Silent Check**: Background update check (once every 24 hours)
3. **Git Operations**: Clone/pull repository on cluster
4. **Version Comparison**: Compare current vs latest version
5. **Safe Update**: Backup current, apply changes, validate

**Key Functions in start-ssh-job.bash**:

```bash
silent_update_check() {
    # Check if auto-updates disabled
    [[ -f "$HOME/.interactive-slurm.noauto" ]] && return 0
    
    # Check update interval
    local last_check=$(stat -c %Y "$UPDATE_VERSION_FILE" 2>/dev/null || echo 0)
    local current_time=$(date +%s)
    local time_diff=$((current_time - last_check))
    
    # Only check if interval exceeded
    [[ $time_diff -lt $UPDATE_INTERVAL ]] && return 0
    
    # Run update check in background
    check_for_updates &
}

check_for_updates() {
    local update_dir=$(mktemp -d)
    cd "$update_dir"
    
    # Clone or update repository
    if [[ -d "interactive-slurm/.git" ]]; then
        git -C interactive-slurm pull
    else
        git clone -b "$BRANCH" "$REPO_URL" interactive-slurm
    fi
    
    # Compare versions
    local current_version=$(cat "$UPDATE_VERSION_FILE" 2>/dev/null || echo "0.0.0")
    local remote_version=$(git -C interactive-slurm describe --tags --always 2>/dev/null || echo "0.0.0")
    
    # Update if newer version available
    if [[ "$remote_version" != "$current_version" ]]; then
        echo "New version available: $remote_version"
        update_interactive_slurm "$update_dir/interactive-slurm" "$remote_version"
    fi
}

update_interactive_slurm() {
    local new_dir="$1"
    local version="$2"
    local backup_dir="$UPDATE_DIR/backup-$(date +%Y%m%d-%H%M%S)"
    
    # Create backup
    mkdir -p "$UPDATE_DIR"
    cp -r ~/bin "$backup_dir"
    
    # Install new version
    cp "$new_dir/bin/"* ~/bin/
    cp "$new_dir/setup.sh" ~/setup.sh
    
    # Update version tracking
    echo "$version" > "$UPDATE_VERSION_FILE"
    
    # Log update
    echo "$(date): Updated to version $version" >> "$UPDATE_LOG"
}
```

**Manual Control**:
- `remote check` - Force update check
- `remote update` - Force update application
- Disable: `touch ~/.interactive-slurm.noauto`
- Logs: `~/.interactive-slurm.update.log`

### Safety Mechanisms
- **Backup Creation**: Current installation backed up before updates
- **Version Tracking**: Version file tracks current installation
- **Update Intervals**: Prevents excessive network usage
- **Error Handling**: Failed updates can be restored from backup

## SSH Configuration

### ProxyCommand Architecture
The system uses SSH ProxyCommand to transparently establish connections through SLURM jobs:

```ssh-config
Host slurm-cpu
    HostName login.hpc.yourcluster.edu
    User your.username
    IdentityFile ~/.ssh/interactive-slurm
    ConnectTimeout 300
    ProxyCommand ssh login.hpc.yourcluster.edu -l your.username "~/bin/start-ssh-job.bash cpu"
    StrictHostKeyChecking no
```

**Connection Flow**:
1. Local SSH client reads `~/.ssh/config`
2. ProxyCommand executes `start-ssh-job.bash` on login node
3. `start-ssh-job.bash` submits SLURM job and waits
4. Job starts SSH server on compute node
5. ProxyCommand creates tunnel to compute node
6. SSH connection established to compute node

### Port Management
- Dynamic port allocation: Random unused port per session
- Port validation: Wait for SSH server to be ready
- Cleanup: Automatic port cleanup on job termination

## SLURM Integration

### Job Patterns
- **CPU Jobs**: `vscode-remote-cpu` - 4 cores, 16GB RAM
- **GPU Jobs**: `vscode-remote-gpu` - 1 GPU, 12 cores, 32GB RAM
- **Timeout**: 8 hours (CPU), 4 hours (GPU)
- **Architecture**: x86 constraint for compatibility

### Resource Profiles
Located in `templates/profiles/`:

**development.conf**:
```bash
SBATCH_PARAM_CPU="--partition=aisc-interactive --time=4:00:00 --nodes=1 --cpus-per-task=2 --mem=8GB"
SBATCH_PARAM_GPU="--partition=aisc-interactive --time=2:00:00 --nodes=1 --gres=gpu:1 --cpus-per-task=6 --mem=16GB"
```

**production.conf**:
```bash
SBATCH_PARAM_CPU="--partition=aisc-interactive --time=12:00:00 --nodes=1 --cpus-per-task=8 --mem=32GB"
SBATCH_PARAM_GPU="--partition=aisc-interactive --time=8:00:00 --nodes=1 --gres=gpu:2 --cpus-per-task=12 --mem=64GB"
```

**gpu-intensive.conf**:
```bash
SBATCH_PARAM_CPU="--partition=aisc-interactive --time=8:00:00 --nodes=1 --cpus-per-task=4 --mem=16GB"
SBATCH_PARAM_GPU="--partition=aisc-interactive --time=6:00:00 --nodes=1 --gres=gpu:4 --cpus-per-task=16 --mem=64GB"
```

### Job State Management
```bash
check_job_status() {
    local job_name="$1"
    local job_info=$(squeue -u $(whoami) -h -n "$job_name" -o %T 2>/dev/null)
    
    case "$job_info" in
        "RUNNING") return 0 ;;
        "PENDING") return 1 ;;
        *) return 2 ;;  # Unknown state
    esac
}
```

## Container Integration

### Enroot Support
The system supports both containerized and non-containerized environments:

**Container Usage**:
```bash
# Container startup with enroot
enroot start --mount $CONTAINER_PATH --rw \
    --conf userns=keep \
    --conf net_hooks=post-start \
    /bin/bash -c 'sshd -p $SSH_PORT && nc -l $SSH_PORT'
```

**Container Path Resolution**:
1. Direct paths: `~/container.sqsh`
2. Project paths: `/sc/projects/path/container.sqsh` → copied to `~/container.sqsh`
3. Validation: Check architecture compatibility

**Non-Container Usage**:
- Direct SSH server on compute node
- No enroot dependency
- Simpler deployment

### Container Management
- **Auto-copy**: `/sc/projects` containers copied to home directory
- **Caching**: Container files cached locally for faster access
- **Architecture**: x86 constraint to prevent compatibility issues
- **Cleanup**: Automatic container cleanup on disconnect

## Security Considerations

### SSH Key Management
- **Key Generation**: ED25519 keys with secure permissions
- **Key Distribution**: Automatic copying to HPC cluster
- **Key Storage**: `~/.ssh/interactive-slurm` (0600 permissions)
- **Rotation**: Keys regenerated on setup script re-run

### Host Key Management
- **Temporary Keys**: Generate unique host keys per session
- **Key Validation**: Verify host key matches expected fingerprint
- **Cleanup**: Temporary keys cleaned up on disconnect

### Network Security
- **Port Binding**: Bind to localhost only (127.0.0.1)
- **Tunnel Creation**: SSH tunneling through login node
- **Connection Validation**: Health checks before establishing connection

## Error Handling

### Common Failure Points
1. **SLURM Job Submission**: Queue full, resource constraints
2. **Container Startup**: Missing container, enroot failures
3. **SSH Server**: Port binding, authentication issues
4. **Network**: SSH tunnel creation failures

### Recovery Mechanisms
- **Job Cancellation**: Cleanup stuck jobs with `remote cancel`
- **Retry Logic**: Automatic retry for transient failures
- **Health Monitoring**: Port availability checks
- **Logging**: Comprehensive logging for debugging

## Development and Testing

### Development Setup
```bash
# Clone repository
git clone https://github.com/aihpi/interactive-slurm.git
cd interactive-slurm

# Install locally for testing
./setup.sh --dev

# Test locally (if possible)
./bin/start-ssh-job.bash list
```

### Testing Strategy
1. **Unit Testing**: Individual component testing
2. **Integration Testing**: Full workflow testing
3. **Connection Testing**: SSH proxy functionality
4. **Update Testing**: Auto-update system validation

### Debug Configuration
```bash
# Enable verbose SSH
ssh -vvv slurm-cpu

# Check job status directly
ssh login.hpc.cluster "squeue --me"

# View update logs
ssh login.hpc.cluster "cat ~/.interactive-slurm.update.log"
```

### Performance Optimization
- **Job Reuse**: Reuse existing jobs for faster connections
- **Container Caching**: Cache containers locally
- **Update Optimization**: Reduce update frequency
- **Resource Tuning**: Optimize SLURM parameters

## Troubleshooting Guide

### Connection Issues
```bash
# Check SSH configuration
grep -A5 slurm-cpu ~/.ssh/config

# Test SSH key
ssh -i ~/.ssh/interactive-slurm user@login.hpc.cluster

# Check script installation
ssh login.hpc.cluster "ls ~/bin/start-ssh-job.bash"
```

### Job Management
```bash
# List all jobs
remote list

# Check SLURM status
ssh login.hpc.cluster "squeue --me"

# Cancel stuck jobs
remote cancel
```

### Auto-Update Issues
```bash
# Check update status
remote check

# View update logs
ssh login.hpc.cluster "cat ~/.interactive-slurm.update.log"

# Disable auto-updates
ssh login.hpc.cluster "touch ~/.interactive-slurm.noauto"
```

## Configuration Reference

### Setup Script Variables
```bash
# Cluster Configuration
CLUSTER_HOST=""           # HPC login hostname
USERNAME=""               # HPC username  
USE_CONTAINERS=true       # Enable container support

# Container Configuration  
CONTAINER_PATH=""         # Container image path
AUTO_COPY_CONTAINERS=true # Auto-copy from /sc/projects

# SSH Configuration
SSH_KEY_PATH="~/.ssh/interactive-slurm"
SSH_CONFIG_PATH="~/.ssh/config"
```

### Runtime Variables (start-ssh-job.bash)
```bash
# SLURM Parameters
SBATCH_PARAM_CPU="--partition=aisc-interactive --time=8:00:00 --nodes=1 --tasks-per-node=4 --cpus-per-task=4 --mem=16GB"
SBATCH_PARAM_GPU="--partition=aisc-interactive --time=4:00:00 --nodes=1 --tasks-per-node=1 --gres=gpu:1 --constraint=x86"

# Update Configuration
UPDATE_VERSION_FILE="$HOME/.interactive-slurm.version"
UPDATE_LOG="$HOME/.interactive-slurm.update.log"  
UPDATE_DIR="$HOME/.interactive-slurm.updates"
UPDATE_INTERVAL=86400  # 24 hours
REPO_URL="https://github.com/aihpi/interactive-slurm.git"
BRANCH="main"

# Job Patterns
CPU_JOB_PATTERN="vscode-remote-cpu"
GPU_JOB_PATTERN="vscode-remote-gpu"
```

### Container Profiles
```bash
# Development: Light resources
DEVELOPMENT_CPU="--cpus-per-task=2 --mem=8GB --time=4:00:00"
DEVELOPMENT_GPU="--gres=gpu:1 --cpus-per-task=6 --mem=16GB --time=2:00:00"

# Production: Heavy resources  
PRODUCTION_CPU="--cpus-per-task=8 --mem=32GB --time=12:00:00"
PRODUCTION_GPU="--gres=gpu:2 --cpus-per-task=12 --mem=64GB --time=8:00:00"

# GPU-Intensive: Maximum GPU resources
GPU_INTENSIVE_CPU="--cpus-per-task=4 --mem=16GB --time=8:00:00"
GPU_INTENSIVE_GPU="--gres=gpu:4 --cpus-per-task=16 --mem=64GB --time=6:00:00"
```

## Contributing

### Development Workflow
1. Fork repository
2. Create feature branch
3. Make changes with tests
4. Test on HPC cluster
5. Submit pull request

### Code Style
- **Shell Scripts**: Follow bash best practices, use `#!/usr/bin/env bash`
- **Documentation**: Update both README.md and DEV.md
- **Variables**: UPPERCASE for constants, lowercase for variables
- **Functions**: Use descriptive names with underscores

### Release Process
1. Update version in setup.sh
2. Update CHANGELOG.md
3. Tag release in Git
4. Test auto-update system
5. Announce release

## Version History

- **v2.0**: Auto-update system integration
- **v1.9**: Enhanced container support
- **v1.8**: VSCode integration improvements
- **v1.7**: GPU swap functionality
- **v1.6**: Cross-platform support
- **v1.5**: Initial container support
- **v1.0**: Basic interactive SSH functionality