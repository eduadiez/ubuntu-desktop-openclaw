.PHONY: help build start stop restart logs shell shell-root clean clean-all test health backup restore build-openclaw start-openclaw stop-openclaw clean-openclaw clean-all-openclaw

# Default target
help:
	@echo "MATE Desktop Docker - Available Commands:"
	@echo ""
	@echo "  make build          - Build the Docker image"
	@echo "  make start          - Start the container"
	@echo "  make stop           - Stop the container"
	@echo "  make restart        - Restart the container"
	@echo "  make logs           - View container logs"
	@echo "  make shell          - Open shell as desktop user"
	@echo "  make shell-root     - Open shell as root"
	@echo "  make health         - Check container health"
	@echo "  make clean          - Stop and remove container"
	@echo "  make clean-all      - Stop, remove container and volumes (DATA LOSS!)"
	@echo "  make backup         - Backup persistent data"
	@echo "  make restore        - Restore from backup"
	@echo "  make test           - Test the build on current architecture"
	@echo "  make test-multiarch - Test builds on both architectures"
	@echo ""
	@echo "OpenClaw Variant:"
	@echo "  make build-openclaw      - Build OpenClaw development variant"
	@echo "  make start-openclaw      - Start OpenClaw variant container"
	@echo "  make stop-openclaw       - Stop OpenClaw variant container"
	@echo "  make clean-openclaw      - Stop and remove OpenClaw container (keeps volume)"
	@echo "  make clean-all-openclaw  - Remove OpenClaw container AND volume (DATA LOSS!)"
	@echo ""

# Build the image
build:
	@echo "Building MATE Desktop image..."
	docker compose build
	@echo "Tagging as mate-desktop-base for variants..."
	docker tag $$(docker compose config | grep 'image:' | awk '{print $$2}' || echo "mate-desktop") mate-desktop-base:latest 2>/dev/null || docker build -t mate-desktop-base:latest .

# Start the container
start:
	@echo "Starting MATE Desktop..."
	docker compose up -d
	@echo ""
	@echo "✓ Desktop is starting!"
	@echo "  Access via: http://localhost:6080"
	@echo "  Check logs: make logs"

# Stop the container
stop:
	@echo "Stopping MATE Desktop..."
	docker compose down

# Restart the container
restart: stop start

# View logs
logs:
	docker compose logs -f

# Open shell as desktop user
shell:
	@echo "Opening shell as 'desktop' user..."
	docker exec -it -u desktop mate-desktop bash

# Open shell as root
shell-root:
	@echo "Opening shell as root..."
	docker exec -it mate-desktop bash

# Check health
health:
	@echo "Container status:"
	@docker ps --filter name=mate-desktop --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "Health check:"
	@docker inspect mate-desktop --format='{{.State.Health.Status}}' 2>/dev/null || echo "Container not running"
	@echo ""
	@echo "Resource usage:"
	@docker stats mate-desktop --no-stream 2>/dev/null || echo "Container not running"

# Clean up (stop and remove container, keep volumes)
clean:
	@echo "Stopping and removing container..."
	docker compose down
	@echo "✓ Cleaned (volumes preserved)"

# Clean everything (including volumes - DATA LOSS!)
clean-all:
	@echo "WARNING: This will delete ALL data including your home directory!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		echo "✓ Everything cleaned (including volumes)"; \
	else \
		echo "Cancelled"; \
	fi

# Backup persistent data
backup:
	@echo "Creating backup..."
	@mkdir -p backups
	@BACKUP_FILE="backups/mate-desktop-$$(date +%Y%m%d-%H%M%S).tar.gz"; \
	docker run --rm \
		-v mate-desktop-home:/data \
		-v $$(pwd)/backups:/backup \
		ubuntu:24.04 \
		tar czf /backup/$$(basename $$BACKUP_FILE) -C /data . && \
	echo "✓ Backup created: $$BACKUP_FILE"

# Restore from backup
restore:
	@echo "Available backups:"
	@ls -1 backups/*.tar.gz 2>/dev/null || (echo "No backups found" && exit 1)
	@echo ""
	@read -p "Enter backup filename (from backups/): " BACKUP; \
	if [ -f "backups/$$BACKUP" ]; then \
		echo "Restoring from backups/$$BACKUP..."; \
		docker run --rm \
			-v mate-desktop-home:/data \
			-v $$(pwd)/backups:/backup \
			ubuntu:24.04 \
			bash -c "rm -rf /data/* /data/.[!.]* && tar xzf /backup/$$BACKUP -C /data"; \
		echo "✓ Restored from backup"; \
	else \
		echo "Backup file not found"; \
		exit 1; \
	fi

# Test build on current architecture
test:
	@echo "Testing build on current architecture..."
	docker compose build
	@echo "Starting test container..."
	docker compose up -d
	@echo "Waiting for services to start..."
	@sleep 30
	@echo "Checking VNC server..."
	@docker exec mate-desktop pgrep -x Xvnc > /dev/null && echo "✓ VNC server running" || (echo "✗ VNC server failed" && exit 1)
	@echo "Checking websockify..."
	@docker exec mate-desktop pgrep -x websockify > /dev/null && echo "✓ websockify running" || (echo "✗ websockify failed" && exit 1)
	@echo "Checking MATE session..."
	@docker exec mate-desktop pgrep -x mate-session > /dev/null && echo "✓ MATE session running" || (echo "✗ MATE session failed" && exit 1)
	@echo ""
	@echo "✓ All tests passed!"
	@echo "  Access at: http://localhost:6080"
	@echo "  Run 'make stop' when done testing"

# Test multi-architecture builds
test-multiarch:
	@echo "Setting up buildx..."
	docker buildx create --name multiarch --use 2>/dev/null || docker buildx use multiarch
	@echo "Building for amd64..."
	docker buildx build --platform linux/amd64 -t mate-desktop:test-amd64 --load .
	@echo "Building for arm64..."
	docker buildx build --platform linux/arm64 -t mate-desktop:test-arm64 --load .
	@echo "✓ Multi-arch builds successful"

# Build OpenClaw variant
build-openclaw:
	@echo "Building base image first..."
	docker compose build
	@echo "Building OpenClaw variant..."
	docker build -f Dockerfile.openclaw -t mate-desktop:openclaw .
	@echo "✓ OpenClaw variant built!"
	@echo "  Run 'make start-openclaw' to start it"

# Start OpenClaw variant
start-openclaw:
	@echo "Starting OpenClaw variant..."
	docker run -d \
		--name mate-desktop-openclaw \
		-p 127.0.0.1:6080:6080 \
		-p 127.0.0.1:5900:5900 \
		-p 127.0.0.1:18789:18789 \
		-v mate-desktop-home-openclaw:/home/desktop \
		--shm-size=2gb \
		mate-desktop:openclaw
	@echo ""
	@echo "✓ OpenClaw variant is running!"
	@echo "  Access via: http://localhost:6080"
	@echo "  OpenClaw Gateway: http://localhost:18789"
	@echo "  OpenClaw, npm, yarn, pnpm, TypeScript included"
	@echo "  Password: dappnode (or your custom password)"

# Stop OpenClaw variant
stop-openclaw:
	@echo "Stopping OpenClaw variant..."
	docker stop mate-desktop-openclaw 2>/dev/null || true
	docker rm mate-desktop-openclaw 2>/dev/null || true
	@echo "✓ OpenClaw variant stopped"

# Clean OpenClaw (stop and remove container, keep volume)
clean-openclaw:
	@echo "Cleaning OpenClaw variant..."
	docker stop mate-desktop-openclaw 2>/dev/null || true
	docker rm mate-desktop-openclaw 2>/dev/null || true
	@echo "✓ OpenClaw container removed (volume preserved)"

# Clean all OpenClaw data (including volume - DATA LOSS!)
clean-all-openclaw:
	@echo "WARNING: This will delete ALL OpenClaw data including your home directory!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker stop mate-desktop-openclaw 2>/dev/null || true; \
		docker rm mate-desktop-openclaw 2>/dev/null || true; \
		docker volume rm mate-desktop-home-openclaw 2>/dev/null || true; \
		echo "✓ Everything cleaned (including volume)"; \
	else \
		echo "Cancelled"; \
	fi
