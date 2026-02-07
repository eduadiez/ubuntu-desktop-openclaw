# Example Configurations

This directory contains example Docker Compose configurations for different use cases.

## Available Examples

### 1. Optimized (`docker-compose.optimized.yml`)

Optimized configuration for server deployments with:
- Resource limits (CPU/memory)
- Localhost-only binding
- Proper logging configuration
- Health checks
- Security options

**Usage:**
```bash
cd examples
docker compose -f docker-compose.optimized.yml up -d
```

### 2. Multiple Desktops (`docker-compose.multiple-desktops.yml`)

Run multiple isolated desktop instances simultaneously:
- Desktop 1: http://localhost:6081
- Desktop 2: http://localhost:6082
- Desktop 3: http://localhost:6083

Each has its own persistent volume and configuration.

**Usage:**
```bash
cd examples
docker compose -f docker-compose.multiple-desktops.yml up -d
```

### 3. File Sharing (`docker-compose.with-file-sharing.yml`)

Share folders between host and container:
- Downloads, Documents, Projects folders
- Easy file transfer
- Read-only reference folder option

**Setup:**
```bash
mkdir -p shared/{downloads,documents,projects,reference}
sudo chown -R 1000:1000 shared/
docker compose -f docker-compose.with-file-sharing.yml up -d
```

### 4. Development (`docker-compose.development.yml`)

Development configuration with:
- No auto-restart
- Verbose logging
- Extra memory
- Live script mounting
- Quick iteration

**Usage:**
```bash
cd examples
docker compose -f docker-compose.development.yml up
```

## Tips

### Switching Configurations

You can specify which compose file to use:
```bash
# Use optimized config
docker compose -f examples/docker-compose.optimized.yml up -d

# Use development config
docker compose -f examples/docker-compose.development.yml up -d

# Stop specific config
docker compose -f examples/docker-compose.optimized.yml down
```

### Combining Configurations

Override the default configuration:
```bash
# Start with main config, override with optimized settings
docker compose -f docker-compose.yml -f examples/docker-compose.optimized.yml up -d
```

### Environment Variables

Create a `.env` file in the examples directory:
```bash
cp ../.env.example .env
# Edit .env with your settings
```

## Creating Custom Configurations

Copy an example and modify it for your needs:
```bash
cp docker-compose.optimized.yml docker-compose.custom.yml
# Edit docker-compose.custom.yml
docker compose -f docker-compose.custom.yml up -d
```