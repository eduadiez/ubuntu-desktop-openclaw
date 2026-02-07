#!/bin/bash
#
# Quick install script for MATE Desktop Docker
# Usage: curl -sSL https://raw.githubusercontent.com/yourusername/mate-desktop-docker/main/scripts/install.sh | bash
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "  MATE Desktop Docker - Quick Install"
echo "================================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not available${NC}"
    echo "Please install Docker Compose V2"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker is installed"
echo ""

# Set installation directory
INSTALL_DIR="${INSTALL_DIR:-$HOME/ubuntu-desktop-openclaw}"

# Check if directory already exists
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Warning: Directory $INSTALL_DIR already exists${NC}"
    read -p "Do you want to remove it and reinstall? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
    else
        echo "Installation cancelled"
        exit 0
    fi
fi

# Clone repository
echo "Cloning repository..."
REPO_URL="${REPO_URL:-https://github.com/yourusername/mate-desktop-docker.git}"
git clone "$REPO_URL" "$INSTALL_DIR" || {
    echo -e "${RED}Error: Failed to clone repository${NC}"
    exit 1
}

cd "$INSTALL_DIR"

echo -e "${GREEN}✓${NC} Repository cloned"
echo ""

# Setup environment file
if [ ! -f .env ]; then
    echo "Setting up environment configuration..."
    cp .env.example .env

    # Generate random password
    RANDOM_PASSWORD=$(openssl rand -base64 12 2>/dev/null || echo "dappnode-$(date +%s)")

    # Update .env with random password
    if command -v sed &> /dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/VNC_PASSWORD=dappnode/VNC_PASSWORD=$RANDOM_PASSWORD/" .env
        else
            sed -i "s/VNC_PASSWORD=dappnode/VNC_PASSWORD=$RANDOM_PASSWORD/" .env
        fi
    fi

    echo -e "${GREEN}✓${NC} Environment configured"
    echo ""
fi

# Ask if user wants to build now
echo "Configuration complete!"
echo ""
echo -e "${YELLOW}Your VNC password is:${NC} $RANDOM_PASSWORD"
echo "(Saved in $INSTALL_DIR/.env)"
echo ""
read -p "Do you want to build and start the container now? [Y/n] " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo ""
    echo "Building Docker image (this may take a few minutes)..."
    docker compose build

    echo ""
    echo "Starting container..."
    docker compose up -d

    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo "Access your desktop at:"
    echo -e "  ${GREEN}http://localhost:6080${NC}"
    echo ""
    echo "VNC Password: $RANDOM_PASSWORD"
    echo ""
    echo "Useful commands:"
    echo "  cd $INSTALL_DIR"
    echo "  make help          # Show all available commands"
    echo "  make logs          # View container logs"
    echo "  make shell         # Open shell in container"
    echo "  make stop          # Stop the container"
    echo ""
else
    echo ""
    echo -e "${GREEN}Installation files ready!${NC}"
    echo ""
    echo "To build and start:"
    echo "  cd $INSTALL_DIR"
    echo "  make build"
    echo "  make start"
    echo ""
    echo "Or use Docker Compose directly:"
    echo "  docker compose up -d --build"
    echo ""
fi

echo "Documentation: $INSTALL_DIR/README.md"
echo ""