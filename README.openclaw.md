# OpenClaw Development Variant

This variant extends the base MATE Desktop image with OpenClaw development tools, automatic service management via supervisord, and a pre-configured desktop environment with auto-launching dashboard and README.

## What's Included

On top of the base image, this variant adds:
- **NVM** (Node Version Manager v0.39.7)
- **Node.js** (latest LTS version)
- **npm, yarn, pnpm** - Package managers
- **TypeScript, ts-node, nodemon** - Development tools
- **Homebrew** (Linuxbrew) - Package manager for additional tools
- **Build tools** - For compiling native npm modules
- **OpenClaw** - CLI and tools
- **OpenClaw Gateway** - Automatically runs on port 18789
- **Supervisord** - Manages VNC, noVNC, and OpenClaw Gateway services
- **Auto-configured Desktop** - README and dashboard auto-launch on startup

## Services Managed by Supervisord

This variant uses supervisord to manage three services:

1. **vncserver** (Priority 100)
   - VNC server on port 5900
   - Runs as `desktop` user
   - Auto-restart enabled

2. **novnc** (Priority 200)
   - Web-based VNC client on port 6080
   - Proxies to VNC server
   - Auto-restart enabled

3. **openclaw-gateway** (Priority 300)
   - OpenClaw Gateway on port 18789
   - Runs as `desktop` user
   - Auto-restart enabled

Check service status:
```bash
sudo supervisorctl status
```

## Quick Start

### Option 1: Using Make (Easiest)

```bash
# Build the OpenClaw variant
make build-openclaw

# Start it
make start-openclaw

# Stop it
make stop-openclaw
```

### Option 2: Using Docker Compose

```bash
# Build base image first
docker compose build

# Build OpenClaw variant (extends base)
docker build -f Dockerfile.openclaw -t mate-desktop:openclaw .

# Run it
docker run -d \
  -p 127.0.0.1:6080:6080 \
  -p 127.0.0.1:5900:5900 \
  -p 127.0.0.1:18789:18789 \
  --name mate-desktop-openclaw \
  mate-desktop:openclaw
```

### Option 3: Using docker-compose.openclaw.yml

```bash
# Build and start
docker compose -f docker-compose.openclaw.yml up -d --build

# Stop
docker compose -f docker-compose.openclaw.yml down
```

## Usage

Once running:
- **Desktop**: http://localhost:6080 (password: `dappnode`)
- **OpenClaw Gateway**: http://localhost:18789
- **OpenClaw Dashboard**: Auto-launches on desktop startup in Brave browser
- **README.txt**: Auto-opens on desktop (contains getting-started instructions)

### First-Time Setup

On first access, you need to configure OpenClaw:

1. Open a terminal inside the desktop (shortcut available on desktop)
2. Run the onboarding command:
   ```bash
   openclaw onboard
   ```
3. Follow the prompts to complete OpenClaw configuration

This step is required before using OpenClaw features. The README.txt on the desktop includes these instructions.

### Automatic Startup Behavior

When the desktop starts up:
1. **OpenClaw Gateway** starts automatically (managed by supervisord on port 18789)
2. **Dashboard launcher** runs in background (T+5s):
   - Generates fresh dashboard URL with authentication token
   - Updates Brave preferences to open dashboard URL on launch
   - Keeps `openclaw dashboard` process running
3. **README.txt** opens in text editor (T+12s, appears on top of any windows)
   - Contains instructions for running `openclaw onboard` to configure OpenClaw
   - Located at `/home/desktop/Desktop/README.txt`

### OpenClaw Dashboard

The OpenClaw Gateway provides a web dashboard for managing your agents. The dashboard provides:
- Real-time control and monitoring of OpenClaw agents
- Session management
- Agent configuration
- Live output and logs

**Dashboard Auto-Launch:**

The dashboard URL is automatically generated and configured on every startup. When you launch Brave browser (manually or via autostart), it will open the dashboard URL.

**Manual Dashboard Launch:**

You can also manually generate a new dashboard URL from the terminal:
```bash
openclaw dashboard
```

This will:
- Generate a fresh dashboard URL with authentication token
- Update Brave preferences with the new URL
- Output: `Dashboard URL: http://127.0.0.1:18789/#token=YOUR_TOKEN`
- Keep the dashboard process running in background

Inside the container terminal:

```bash
# Check Node.js and npm
node --version
npm --version

# Use nvm to switch Node versions
nvm list
nvm install 18
nvm use 18

# Global tools are ready
yarn --version
pnpm --version
tsc --version
nodemon --version

# Use Homebrew to install additional tools
brew --version
brew install gh           # GitHub CLI
brew install jq           # JSON processor
brew search <package>     # Search for packages

# Check supervisor status (all services)
sudo supervisorctl status

# View service logs
sudo tail -f /var/log/supervisor/openclaw-gateway.log
sudo tail -f /var/log/supervisor/vncserver.log
sudo tail -f /var/log/supervisor/novnc.log

# View dashboard launcher logs
tail -f /tmp/openclaw-dashboard-autostart.log
tail -f /tmp/openclaw-dashboard-cmd.log

# Manually generate new dashboard URL (if needed)
openclaw dashboard

# First-time setup: Configure OpenClaw
openclaw onboard
```

The `openclaw dashboard` command outputs a URL like:
```
Dashboard URL: http://127.0.0.1:18789/#token=YOUR_TOKEN_HERE
```

This URL is automatically generated on startup and configured in Brave preferences.

## Mount Your Projects

Add your projects directory to `docker-compose.openclaw.yml`:

```yaml
volumes:
  - desktop-home-openclaw:/home/desktop
  - ./my-projects:/home/desktop/projects  # Add this line
```

Or when using `docker run`:

```bash
docker run -d \
  -p 127.0.0.1:6080:6080 \
  -p 127.0.0.1:5900:5900 \
  -p 127.0.0.1:18789:18789 \
  -v $(pwd)/my-projects:/home/desktop/projects \
  mate-desktop:openclaw
```

## Building for Different Architectures

```bash
# Build for x86_64
docker buildx build --platform linux/amd64 \
  -f Dockerfile.openclaw \
  -t mate-desktop:openclaw-amd64 \
  --load .

# Build for ARM64
docker buildx build --platform linux/arm64 \
  -f Dockerfile.openclaw \
  -t mate-desktop:openclaw-arm64 \
  --load .
```

## Customizing Node Version

Edit `Dockerfile.openclaw` and change:

```dockerfile
ENV NODE_VERSION=node    # Latest
# Or specify a version:
ENV NODE_VERSION=18      # Node 18 LTS
ENV NODE_VERSION=20      # Node 20 LTS
```

## Image Size

- Base image: ~3.0 GB
- OpenClaw variant: ~3.5 GB (adds ~500MB)

## Troubleshooting

### Dashboard not opening automatically

Check the autostart logs:
```bash
tail -f /tmp/openclaw-dashboard-autostart.log
tail -f /tmp/openclaw-dashboard-cmd.log
```

Verify the autostart entry exists:
```bash
ls -la ~/.config/autostart/openclaw-dashboard.desktop
```

Manually test the launcher script:
```bash
~/.openclaw-dashboard.sh
```

### Brave shows loading cursor

This should be resolved in the current implementation. If it persists:
```bash
# Clean up Brave lock files
rm -f ~/.config/BraveSoftware/Brave-Browser/SingletonLock
rm -f ~/.config/BraveSoftware/Brave-Browser/SingletonSocket
rm -f ~/.config/BraveSoftware/Brave-Browser/SingletonCookie
```

### OpenClaw Gateway not running

Check supervisord status:
```bash
sudo supervisorctl status openclaw-gateway
```

View gateway logs:
```bash
sudo tail -f /var/log/supervisor/openclaw-gateway.log
```

Restart the gateway:
```bash
sudo supervisorctl restart openclaw-gateway
```

### NVM not found

NVM is installed system-wide in `/opt/nvm` and should be automatically available. If not:

```bash
# Load NVM manually
source /etc/profile.d/nvm.sh

# Or check if it's already loaded
nvm --version
```

### Native module build fails

Build tools are included, but some modules need additional dependencies:

```bash
sudo apt-get update
sudo apt-get install -y libxyz-dev  # Install specific library needed
```

### README.txt not opening on startup

Check the autostart entry:
```bash
ls -la ~/.config/autostart/open-readme.desktop
```

The README should open 12 seconds after desktop startup. Check if pluma is installed:
```bash
which pluma
```

## Switching Between Base and OpenClaw Variants

Your data is stored in separate volumes, so you can run both:

```bash
# Base variant
docker compose up -d                # Port 6080

# OpenClaw variant (change ports or stop base first)
docker run -p 127.0.0.1:6081:6080 -p 127.0.0.1:5901:5900 -p 127.0.0.1:18790:18789 mate-desktop:openclaw
```