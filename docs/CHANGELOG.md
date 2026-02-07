# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-06

### Added
- Multi-architecture support (x86_64 and ARM64)
- MATE desktop environment with noVNC browser access
- Brave browser pre-installed
- Smart package persistence system via `persist-install` helper
- Persistent home directory with Docker volumes
- Desktop shortcuts for Brave and Terminal
- Custom MATE panel layout optimized for containers
- Environment variable configuration via .env file
- Healthcheck for container monitoring
- Comprehensive documentation with security considerations
- Quick start guide and troubleshooting section

### Features
- VNC server (TigerVNC) with configurable resolution and color depth
- noVNC web interface for zero-install browser access
- Automatic package reinstallation on container restart
- APT cache persistence for faster reinstalls
- Custom startup scripts support
- Repository and GPG key persistence
- Pre-configured timezone and locale support

### Included Applications
- Brave Browser
- MATE Terminal
- Caja File Manager
- Pluma Text Editor
- Atril Document Viewer
- Engrampa Archive Manager
- Eye of MATE Image Viewer
- MATE Calculator
- System Monitor
- Brisk Menu

## [1.1.0] - 2026-02-06

### Added
- **Makefile** with convenient commands (build, start, stop, logs, shell, backup, restore, test)
- **Quick install script** (`scripts/install.sh`) for one-line installation
- **GitHub issue templates** for bug reports and feature requests
- **GitHub pull request template** for standardized contributions
- **SECURITY.md** with security policy and vulnerability reporting instructions
- **Example Docker Compose configurations:**
  - `docker-compose.optimized.yml` - Optimized setup with resource limits for servers
  - `docker-compose.multiple-desktops.yml` - Run multiple isolated desktop instances
  - `docker-compose.with-file-sharing.yml` - Share folders between host and container
  - `docker-compose.development.yml` - Development-friendly configuration
- **examples/README.md** with detailed usage instructions for each example

### Changed
- Reorganized project files into logical directories (scripts/, config/, docs/, examples/)
- Updated README with Makefile usage instructions
- Updated README with quick install option
- Enhanced documentation with security and contribution sections
- Updated project structure documentation

### Improved
- Better project organization and maintainability
- Lower barrier to entry with automated install script
- Production-ready examples with best practices
- Comprehensive issue reporting and contribution workflow
- Cleaner root directory with organized subdirectories

## [Unreleased]

### Planned
- Screenshot examples in README
- Audio support documentation
- Additional browser options (Firefox, Chrome)
- GPU acceleration guide
- Performance optimization tips
- Pre-built images on Docker Hub