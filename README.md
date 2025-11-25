# Interactive SLURM SSH Sessions

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A streamlined solution for running interactive SSH sessions on SLURM compute nodes, designed for seamless integration with VSCode Remote-SSH and other development tools.

## 🚀 Quick Start

### Setup (One Command)
```bash
git clone https://github.com/aihpi/interactive-slurm.git
cd interactive-slurm
./setup.sh
```

The setup script automatically:
- ✅ Generates SSH keys and configures access
- ✅ Installs scripts on your HPC cluster
- ✅ Sets up VSCode integration
- ✅ Handles container options if needed

### Connect
```bash
ssh slurm-cpu
```

That's it! You now have access to a compute node with:
- VSCode Remote-SSH support
- Automatic updates (runs in background)
- Full SLURM integration
- Optional container support

## ✨ Features

- 🚀 **One-Command Setup**: Fully automated installation
- 🆙 **Auto-Updates**: Scripts update themselves automatically from GitHub
- 🎯 **VSCode Ready**: Perfect Remote-SSH integration
- 🔧 **Simple Management**: Use `remote` commands for all operations
- 🔐 **Secure**: Automatic SSH key management

## 📋 Prerequisites

- Access to a SLURM-managed HPC cluster
- SSH access to the cluster's login node
- VSCode with [Remote-SSH extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) (optional)

## 🖥️ Basic Usage

### Connect to CPU Environment
```bash
ssh slurm-cpu
```

### VSCode Integration
1. **Install Extension**: Get "Remote-SSH" from VSCode marketplace
2. **Connect**: Press `Ctrl/Cmd+Shift+P` → "Remote-SSH: Connect to Host"
3. **Select Host**: Choose `slurm-cpu` from the list
4. **Start Coding**: VSCode connects to the compute node automatically!

### Manage Sessions
```bash
# List running jobs
remote list

# Switch to GPU environment
remote gpuswap

# Cancel all sessions
remote cancel

# Check for updates
remote check

# Update to latest version
remote update
```

## 🆙 Auto-Updates

**Automatic**: When you connect, scripts check for updates in the background (once daily) and apply them automatically.

**Manual Control**:
```bash
# Check for updates
remote check

# Force update
remote update
```

## 🛠️ Troubleshooting

### Common Issues

**Connection takes too long (>5 minutes):**
```bash
# Check job status
ssh login.hpc.yourcluster.edu
squeue --me
```

**VSCode connection fails:**
1. Test command line first: `ssh slurm-cpu`
2. Check VSCode timeout settings: `remote.SSH.connectTimeout ≥ 300`
3. View logs: VSCode → Output → Remote-SSH

**Get help:**
```bash
remote help
```

## 📚 More Information

- **Testing Guide**: [TESTING.md](TESTING.md)  
- **Technical Details**: [DEV.md](DEV.md)
- **Change Log**: [CHANGELOG.md](CHANGELOG.md)

## Based on

Interactive SLURM builds upon [vscode-remote-hpc](https://github.com/gmertes/vscode-remote-hpc) with enhanced automation and auto-update capabilities.