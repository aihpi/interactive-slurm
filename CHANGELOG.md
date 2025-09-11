# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2025-09-11

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