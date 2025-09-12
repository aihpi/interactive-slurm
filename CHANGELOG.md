# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2025-09-12

### Fixed - Setup Script Improvements & noexec Filesystem Compatibility
- **noexec Filesystem Support**: ProxyCommand now uses `bash ~/bin/start-ssh-job.bash` to bypass noexec restrictions on NFS home directories
- **Duplicate SSH Entry Prevention**: Setup script now cleans existing Interactive SLURM entries before adding new ones, preventing conflicts
- **Enhanced Script Permissions**: Added explicit chmod commands and verification for critical scripts during installation
- **SSH Config Management**: Automatic cleanup of old SSH configurations ensures the latest settings are always used

### Added - Major Release: Optional Containers & Automated Setup
- **Automated Setup Script**: New `setup.sh` provides one-command installation with interactive prompts
- **Optional Container Support**: Can now run with or without enroot containers
- **SSH Key Management**: Automatic generation and distribution of SSH keys (`~/.ssh/interactive-slurm`)
- **VSCode Integration**: Automatic configuration of Remote-SSH extension settings
- **Container Auto-copy**: Setup script can copy containers from `/sc/projects` to home directory
- **Connection Validation**: Built-in testing and troubleshooting during setup
- **Comprehensive Documentation**: New TESTING.md with step-by-step testing guide
- **Enhanced README**: Complete tutorial with clear local vs remote machine indicators

### Enhanced
- **Dual Execution Modes**: Both containerized (enroot) and direct compute node access
- **Smart Container Detection**: Scripts automatically detect container presence/absence
- **Improved Error Messages**: Better feedback for containerless vs container modes
- **SSH Configuration**: Auto-generated SSH configs with appropriate timeouts and settings
- **User Experience**: Emoji-enhanced output and clear step-by-step guidance

### Changed
- **Container Parameter**: Now optional in `start-ssh-job.bash cpu [path]` and `gpu [path]`
- **SSH Session Logic**: Conditional execution based on container availability
- **Documentation Structure**: README focused on automated setup, manual config moved to advanced section
- **Project Architecture**: Added setup.sh as primary entry point

### Technical Improvements
- **Session Management**: Enhanced `ssh-session.bash` with dual-mode execution
- **Error Handling**: Better validation and fallback mechanisms
- **Tool Detection**: Improved validation of required tools with warnings vs errors

## [Previous] - 2025-09-11

### Added
- **Automatic sqsh file management**: `ssh-session.bash` now automatically copies container images from `/sc/projects` to the user's home directory if they don't exist locally
- **Comprehensive Slurm integration**: Added mounting of Slurm binaries (`srun`, `sbatch`, `scancel`) and libraries (`libslurm.so.*`, `libmunge.so.2`) for full cluster access within containers
- **SSH daemon setup**: Containers now automatically generate SSH host keys and set up proper SSH daemon configuration
- **Slurm command aliases**: Added automatic SSH-over-Slurm command wrappers to `~/.bashrc` for seamless cluster command execution
- **Container initialization script**: Added `incontainer-setup.sh` for standardized container environment setup

### Changed
- **CPU job parameters**: Updated `SBATCH_PARAM_CPU` to use x86 architecture constraint, reduced memory to 16GB and CPU cores to 4 for better resource efficiency
- **GPU job parameters**: Added `--export=IN_ENROOT=1` environment variable export
- **Container image validation**: Improved path validation to handle mounted directories like `/sc/projects` more intelligently
- **Error handling**: Enhanced error messages and fallback mechanisms for container image access

### Enhanced
- **Job scheduling**: Jobs now target x86 architecture specifically to avoid library compatibility issues on ARM nodes
- **Resource management**: Optimized CPU job resource allocation for typical development workloads
- **Container portability**: Improved support for shared container images stored in project directories

### Technical Details
- Container images from `/sc/projects` are automatically cached locally to avoid mounting issues
- Slurm library versions 40 and 41 are both supported through dynamic mounting
- SSH daemon runs on dynamically allocated ports to prevent conflicts
- All Slurm commands work transparently within containers via SSH forwarding