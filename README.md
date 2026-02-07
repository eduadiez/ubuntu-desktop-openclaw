# MATE Desktop in Docker with noVNC

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Multi--arch-blue.svg)](https://www.docker.com/)
[![Architectures](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-green.svg)](#multi-architecture-support)

A fully functional MATE desktop environment running in Docker with multi-architecture support (x86_64 and ARM64), accessible through your browser via noVNC. Comes with Brave browser, persistent home directory, and a package persistence system so your installed apps survive container restarts.

**Supported Architectures:** `linux/amd64` | `linux/arm64`

---

## Key Features

- 🖥️ **Multi-architecture support** - Runs on x86_64 (Intel/AMD) and ARM64 (Apple Silicon, Raspberry Pi)
- 🌐 **Zero-install browser access** via noVNC - No VNC client needed
- 💾 **Smart package persistence** - Installed apps survive container restarts
- 🚀 **Fast reinstalls** using cached .deb files
- 🔒 **Isolated environment** with persistent home directory
- 📦 **Pre-configured** with Brave browser and essential MATE apps
- 🔄 **Container-friendly** - Rebuild without losing your data and settings

---

## System Requirements

- **Architecture:** x86_64 (Intel/AMD) or ARM64 (Apple Silicon, Raspberry Pi 4+, etc.)
- **Docker:** Docker Engine 20.10+ and Docker Compose V2
- **RAM:** Minimum 2GB (4GB recommended for smooth performance)
- **Disk Space:** 5GB for base image + space for your files and installed apps
- **Network:** Port 6080 available (and optionally 5900 for direct VNC)

---

## Quick Start

> **ℹ️ Default VNC Password: `dappnode`**
>
> **To use a custom password:** Copy `.env.example` to `.env` and change `VNC_PASSWORD=dappnode` to your preferred password before starting. The password persists across container restarts.

### Option 1: Using Pre-built Images from Docker Hub (Fastest)

Pull and run the latest multi-architecture image:

**Base MATE Desktop:**
```bash
docker run -d \
  --name mate-desktop \
  -p 6080:6080 \
  -p 5900:5900 \
  -v mate-desktop-home:/home/desktop \
  -e VNC_PASSWORD=dappnode \
  --shm-size=2gb \
  eduadiez/mate-desktop:latest
```

**OpenClaw Development Variant:**
```bash
docker run -d \
  --name mate-desktop-openclaw \
  -p 6080:6080 \
  -p 5900:5900 \
  -p 18789:18789 \
  -v mate-desktop-home-openclaw:/home/desktop \
  -e VNC_PASSWORD=dappnode \
  --shm-size=2gb \
  eduadiez/mate-desktop-openclaw:latest
```

Then access at: **http://localhost:6080**

### Option 2: Quick Install from Source (Recommended)

One-line installation:
```bash
curl -sSL https://raw.githubusercontent.com/eduadiez/ubuntu-desktop-openclaw/main/scripts/install.sh | bash
```

This will:
- Clone the repository
- Set up environment with a random secure password
- Optionally build and start the container

### Option 2: Manual Installation

1. Clone or download the project:

```
mate-desktop/
├── .github/
│   └── workflows/
│       └── docker-build.yml
├── docs/
│   ├── CHANGELOG.md
│   └── CONTRIBUTING.md
├── scripts/
│   ├── startup.sh
│   ├── persist-install.sh
│   └── xstartup
├── config/
│   └── container.layout
├── Dockerfile
├── docker-compose.yml
├── README.md
├── LICENSE
├── .dockerignore
├── .env.example
└── .gitignore
```

2. Configure your environment (recommended):

```bash
cp .env.example .env
# Edit .env and set your VNC_PASSWORD
nano .env  # Change VNC_PASSWORD=dappnode to your preferred password
```

**Important:** The password set in `.env` persists across container restarts.

3. Build and start:

```bash
# Using Makefile (recommended)
make build
make start

# Or using Docker Compose directly
docker compose up -d --build
```

4. Open your browser and go to:

```
http://localhost:6080
```

5. **Enter the VNC password when prompted:**
   - **Default password:** `dappnode`

**To change the password:** Edit the `VNC_PASSWORD` value in your `.env` file, then restart the container with `make restart` or `docker compose restart`.

You'll see a full MATE desktop with Brave and Terminal shortcuts on the desktop.

### Using the Makefile

This project includes a Makefile for convenience:

```bash
make help          # Show all available commands
make build         # Build the image
make start         # Start the container
make stop          # Stop the container
make logs          # View logs
make shell         # Open shell as desktop user
make health        # Check container health
make backup        # Backup your data
make test          # Test the build
```

---

## Configuration

### Default Credentials

**Default VNC Password:** `dappnode`

### Changing the Password

The VNC password is set via environment variables and **persists across container restarts**. To change it:

**Option 1: Using .env file (Recommended)**
```bash
# Copy the example file
cp .env.example .env

# Edit and change VNC_PASSWORD
nano .env  # or use your preferred editor

# Change this line:
# VNC_PASSWORD=dappnode
# To something like:
# VNC_PASSWORD=mySecurePassword123

# Restart the container to apply
docker compose restart
# or
make restart
```

**Option 2: Directly in docker-compose.yml**
```yaml
environment:
  - VNC_PASSWORD=yourPasswordHere  # Change this value
```

**Note:** Don't try to change the password inside the running container (e.g., with `vncpasswd`) - it won't persist. Always set it in `.env` or `docker-compose.yml`.

### Configuration Options

Available environment variables in `.env` or `docker-compose.yml`:

```yaml
environment:
  - VNC_PASSWORD=dappnode        # Your VNC password (set in .env)
  - VNC_RESOLUTION=1920x1080     # Desktop resolution
  - VNC_COL_DEPTH=24             # Color depth (16/24/32)
  - TZ=UTC                       # Timezone (e.g., Europe/Madrid)
```

After changing any values, restart the container:
```bash
docker compose restart
```

### Ports

| Port | Service | Description |
|------|---------|-------------|
| 6080 | noVNC   | Browser access (main) |
| 5900 | VNC     | Direct VNC client access (optional) |

If you only need browser access, you can remove the `5900:5900` line from `docker-compose.yml`.

---

## Security Considerations

**Important security notes:**

- **Default password:** The VNC password is `dappnode` - change it in `.env` if needed
- **Network exposure:** VNC traffic is unencrypted by default
  - Best used on localhost or trusted networks
  - For remote access, use SSH tunneling (see below)
- **The `--I-KNOW-THIS-IS-INSECURE` flag** is used in startup.sh for VNC
  - This is designed for local testing and development environments

### Secure Remote Access

For accessing over the internet, use SSH tunneling:

```bash
# On your local machine, create an SSH tunnel
ssh -L 6080:localhost:6080 user@your-server.com

# Then access via http://localhost:6080 in your browser
```

Or use a reverse proxy with TLS (nginx, Caddy, Traefik) in front of the container.

---

## Persistent Home Directory

The user's home directory (`/home/desktop`) is stored in a Docker named volume called `mate-desktop-home`. This means all your files, desktop settings, browser bookmarks, terminal history, and customizations persist across container restarts and image rebuilds.

### Using a local bind mount instead

If you prefer to store the home directory on your host filesystem:

```yaml
# In docker-compose.yml, replace the volumes section:
volumes:
  - ./desktop-home:/home/desktop
```

Create the directory with the correct permissions first:

```bash
mkdir -p desktop-home
# UID 1000 matches the 'desktop' user inside the container
sudo chown 1000:1000 desktop-home
```

---

## Installing Additional Software

### Quick install (standard apt packages)

Open a terminal inside the desktop (or `docker exec`) and run:

```bash
sudo persist-install vlc
```

This installs the package AND adds it to the persistent list, so it gets reinstalled automatically on every container start. The `.deb` files are cached in the persistent volume so reinstalls are fast.

You can install multiple packages at once:

```bash
sudo persist-install gimp inkscape htop
```

### Installing packages with third-party repositories

For software that requires adding a custom APT repo (like VS Code, Sublime Text, etc.), add the repo and key first, then use `persist-install`. The repos and GPG keys are saved automatically to the persistent volume.

Example — installing VS Code:

```bash
# Add Microsoft's GPG key and repo
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
  sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg

echo "deb [arch=arm64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
  sudo tee /etc/apt/sources.list.d/vscode.list

# Install and persist
sudo persist-install code
```

### Managing persistent packages

```bash
# List all persisted packages
sudo persist-install --list

# Remove a package from the persistent list (and uninstall it)
sudo persist-install --remove vlc

# Force reinstall everything in the list
sudo persist-install --refresh

# Show help
sudo persist-install --help
```

### Custom startup scripts

For more complex setups, you can place shell scripts in `~/.persist/scripts.d/`. These run automatically on every container start.

```bash
# Create a startup script
cat > ~/.persist/scripts.d/my-setup.sh << 'EOF'
#!/bin/bash
# Skip if already done
[ -f /usr/local/bin/my-tool ] && exit 0
echo "Running custom setup..."
# your commands here
EOF

chmod +x ~/.persist/scripts.d/my-setup.sh
```

### How persistence works

Everything lives inside `~/.persist/` on the persistent volume:

| Path | Purpose |
|------|---------|
| `~/.persist/packages.list` | Package names reinstalled on every start |
| `~/.persist/repos.d/` | Saved APT repository files |
| `~/.persist/keys.d/` | Saved GPG signing keys |
| `~/.persist/apt-cache/` | Cached `.deb` files (speeds up reinstalls) |
| `~/.persist/scripts.d/` | Custom `.sh` scripts run on startup |
| `~/.persist/install.log` | Log of package installations |

---

## Pre-installed Software

| Application | Description |
|-------------|-------------|
| Brave Browser | Chromium-based privacy browser |
| MATE Terminal | Terminal emulator |
| Caja | File manager |
| Pluma | Text editor |
| Atril | PDF/document viewer |
| Engrampa | Archive manager |
| Eye of MATE | Image viewer |
| MATE Calc | Calculator |
| System Monitor | Task manager |
| Brisk Menu | Application menu |

Desktop shortcuts for **Brave** and **Terminal** are created automatically.

---

## Container Management

### Common commands

```bash
# Start the container
docker compose up -d

# Stop the container
docker compose down

# Rebuild after changing Dockerfile
docker compose up -d --build

# View logs
docker compose logs -f

# Open a root shell
docker exec -it mate-desktop bash

# Open a shell as the desktop user
docker exec -it -u desktop mate-desktop bash
```

### Reset everything

If something breaks and you want a fresh start:

```bash
docker compose down
docker volume rm mate-desktop-home
docker compose up -d --build
```

> **Warning:** This deletes all user data, installed packages, browser data, and settings.

### Reset only the panel/desktop layout

If the MATE panel gets corrupted:

```bash
docker exec -it -u desktop mate-desktop bash -c \
  "rm -rf ~/.config/mate-panel && mate-panel --reset"
```

---

## Multi-Architecture Support

This image supports both **x86_64** (Intel/AMD) and **ARM64** (Apple Silicon, Raspberry Pi) architectures. Docker will automatically pull or build the correct version for your system.

### Building for Specific Architectures

By default, `docker compose up --build` builds for your current architecture. For cross-platform builds:

```bash
# Set up buildx (one-time setup)
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap
```

**Build for your current platform:**
```bash
docker compose up -d --build
```

**Build for a specific architecture:**
```bash
# For x86_64 / amd64
docker buildx build --platform linux/amd64 -t mate-desktop:amd64 --load .

# For ARM64 (Apple Silicon, Raspberry Pi)
docker buildx build --platform linux/arm64 -t mate-desktop:arm64 --load .
```

**Build multi-arch image (for pushing to registry):**
```bash
# Build for both architectures and push to registry
docker buildx build --platform linux/amd64,linux/arm64 \
  -t eduadiez/mate-desktop:latest \
  --push .
```

**Note:** The `--load` flag (for local use) only works with single-platform builds. For multi-platform builds, use `--push` to push to a registry, or build each platform separately.

### Testing on Different Architectures

If you're on an x86 machine and want to test the ARM64 build (or vice versa):

```bash
# Build and run ARM64 image on x86 (uses QEMU emulation)
docker buildx build --platform linux/arm64 -t mate-desktop:arm64 --load .
docker run -p 6080:6080 --platform linux/arm64 mate-desktop:arm64

# Build and run x86_64 image on ARM64
docker buildx build --platform linux/amd64 -t mate-desktop:amd64 --load .
docker run -p 6080:6080 --platform linux/amd64 mate-desktop:amd64
```

**Performance note:** Cross-architecture emulation is slower than native builds. For best performance, build on your target architecture.

---

## Troubleshooting

### `exec format error`

The shell scripts have Windows-style line endings. The Dockerfile already handles this with `sed -i 's/\r$//'`, but if you still see it, run manually:

```bash
sed -i 's/\r$//' scripts/*.sh scripts/xstartup
docker compose up -d --build
```

### Container exits immediately (code 0)

Check the logs with `docker compose logs -f`. The websockify process runs in the foreground to keep the container alive. If VNC fails to start, the container will exit with code 1 and show the error in the logs.

### `vncpasswd: command not found`

The Dockerfile enables the `universe` repository which provides TigerVNC. If you still hit this, verify the build completed without errors:

```bash
docker compose build --no-cache
```

### BriskMenu error on first start

If you see a panel error about `BriskMenuFactory::BriskMenu`, the `mate-applet-brisk-menu` package is included in the Dockerfile. Reset the volume and rebuild:

```bash
docker compose down
docker volume rm mate-desktop-home
docker compose up -d --build
```

### Brave browser won't launch

Brave runs with `--no-sandbox --disable-gpu` flags because it's inside a Docker container. If it crashes, make sure `shm_size: "2gb"` is set in `docker-compose.yml` — Chromium-based browsers need a large shared memory space.

### Slow performance

Increase the shared memory and consider lowering the resolution:

```yaml
environment:
  - VNC_RESOLUTION=1280x720
shm_size: "4gb"
```

---

## Example Configurations

The `examples/` directory contains ready-to-use configurations:

- **`docker-compose.optimized.yml`** - Optimized setup with resource limits for servers
- **`docker-compose.multiple-desktops.yml`** - Run multiple isolated desktops
- **`docker-compose.with-file-sharing.yml`** - Share folders with host
- **`docker-compose.development.yml`** - Development-friendly configuration

See [examples/README.md](examples/README.md) for details.

---

## Use Cases

This containerized desktop environment is perfect for:

- **Remote Development:** Full desktop on cloud servers (AWS, Oracle Cloud, DigitalOcean, etc.)
- **Isolated Browsing:** Secure, disposable browser environment for testing or privacy
- **ARM Development:** Native ARM environment on Apple Silicon or Raspberry Pi
- **Testing GUI Apps:** Test desktop applications without affecting your host system
- **Headless Servers:** Add GUI capabilities to servers without a display
- **Education/Labs:** Provide consistent desktop environments for students
- **CI/CD:** Run GUI tests in containers
- **Multi-user Setups:** Multiple isolated desktop instances on one machine

---

## Project Structure

| Path | Description |
|------|-------------|
| `Dockerfile` | Multi-arch container image (Ubuntu 24.04, MATE, Brave, TigerVNC, noVNC) |
| `docker-compose.yml` | Service configuration with ports, volumes, environment variables, and healthcheck |
| `Makefile` | Convenience commands for common operations |
| `.dockerignore` | Excludes unnecessary files from build context for faster builds |
| `.env.example` | Template for environment variables (copy to `.env` and customize) |
| `scripts/startup.sh` | Entrypoint script — initializes home dir, desktop shortcuts, persistence, VNC, and noVNC |
| `scripts/xstartup` | VNC session startup — launches MATE desktop via dbus |
| `scripts/persist-install.sh` | Helper tool to install and persist packages across container restarts |
| `scripts/install.sh` | Quick installation script |
| `config/container.layout` | Custom MATE panel layout configuration |
| `docs/CHANGELOG.md` | Version history and change tracking |
| `docs/CONTRIBUTING.md` | Contribution guidelines |
| `examples/` | Example Docker Compose configurations for different use cases |
| `.github/workflows/` | CI/CD pipelines for automated testing and builds |
| `.github/ISSUE_TEMPLATE/` | Issue templates for bug reports and feature requests |
| `SECURITY.md` | Security policy and vulnerability reporting |

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines on how to contribute to this project.

### Reporting Issues

Found a bug or have a feature request? Please use our issue templates:
- [Bug Report](.github/ISSUE_TEMPLATE/bug_report.yml)
- [Feature Request](.github/ISSUE_TEMPLATE/feature_request.yml)

### Security

For security vulnerabilities, please see our [Security Policy](SECURITY.md).

## Changelog

See [CHANGELOG.md](docs/CHANGELOG.md) for a list of changes and version history.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The included software (Ubuntu, MATE, Brave, TigerVNC, noVNC) is subject to their respective licenses.

## Disclaimer

**USE AT YOUR OWN RISK**

This software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.

By using this software, you acknowledge that:
- You understand the security limitations described in [SECURITY.md](SECURITY.md)
- You are solely responsible for securing your deployment
- You accept all risks associated with using this software
- The maintainers are not responsible for any data loss, security breaches, or other issues
