# Docker Deployment Guide

This guide covers deploying Roxy-WI using Docker.

## Quick Start

### With MySQL (Recommended for Production)

```bash
# Clone the repository
git clone https://github.com/roxy-wi/roxy-wi.git
cd roxy-wi

# Copy and configure environment file
cp docker/.env.example docker/.env
# Edit docker/.env to customize settings

# Create bind mount directories
mkdir -p /custom/docker/stacks/stk-roxy-wi-001/Database/Data
mkdir -p /custom/docker/stacks/stk-roxy-wi-001/Application/{Data,Logs,Config}

# Start Roxy-WI with MySQL
docker compose -f docker/docker-compose.yml up -d

# Access the web interface
open http://localhost:8080
```

### With SQLite (Lightweight)

```bash
# Copy and configure environment file
cp docker/.env.sqlite.example docker/.env

# Create bind mount directories
mkdir -p /custom/docker/stacks/stk-roxy-wi-001/Application/{Data,Logs,Config}

# Start Roxy-WI with SQLite
docker compose -f docker/docker-compose.sqlite.yml up -d
```

## Default Credentials

| Username | Password | Role        |
|----------|----------|-------------|
| admin    | admin    | Super Admin |
| editor   | editor   | Editor      |
| guest    | guest    | Guest       |

**⚠️ Change default passwords immediately after first login!**

## Configuration

### Environment File (.env)

Copy `.env.example` or `.env.sqlite.example` to `.env` and customize:

```bash
###BEGIN GENERAL###
STACK_NAME=stk-roxy-wi-001
STACK_BINDMOUNTROOT=custom/docker/stacks
TZ=America/New_York
UID=0
GID=0
SERVICE_BIND_ADDRESS_EXTERNAL=0.0.0.0
DNSSERVER=1.1.1.1
###END GENERAL###

###BEGIN DATABASE###
DATABASE_IMAGENAME=mysql
DATABASE_IMAGEVERSION=8.0
DATABASE_HOST=ROXY-WI-DB-001
DATABASE_PORT=3306
DATABASE_ROOT_PASSWORD=change-me
DATABASE_USER=roxy-wi
DATABASE_PASSWORD=change-me
DATABASE_NAME=roxywi
###END DATABASE###

###BEGIN APPLICATION###
APPLICATION_IMAGENAME=roxy-wi/roxy-wi
APPLICATION_IMAGEVERSION=latest
APPLICATION_PORT_EXTERNAL=8080
APPLICATION_MYSQL_ENABLE=1
APPLICATION_SECRET_PHRASE=
###END APPLICATION###
```

### Bind Mounts

| Host Path | Container Path | Description |
|-----------|---------------|-------------|
| `/${STACK_BINDMOUNTROOT}/${STACK_NAME}/Database/Data` | `/var/lib/mysql` | MySQL data |
| `/${STACK_BINDMOUNTROOT}/${STACK_NAME}/Application/Data` | `/var/lib/roxy-wi` | App data, keys, configs |
| `/${STACK_BINDMOUNTROOT}/${STACK_NAME}/Application/Logs` | `/var/log/roxy-wi` | Application logs |
| `/${STACK_BINDMOUNTROOT}/${STACK_NAME}/Application/Config` | `/etc/roxy-wi` | Configuration files |

### Container Application Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ROXY_WI_SECRET_PHRASE` | Secret phrase for encryption | Auto-generated |
| `ROXY_WI_MYSQL_ENABLE` | Enable MySQL (1) or SQLite (0) | `0` |
| `ROXY_WI_MYSQL_HOST` | MySQL host | `127.0.0.1` |
| `ROXY_WI_MYSQL_PORT` | MySQL port | `3306` |
| `ROXY_WI_MYSQL_USER` | MySQL username | `roxy-wi` |
| `ROXY_WI_MYSQL_PASSWORD` | MySQL password | `roxy-wi` |
| `ROXY_WI_MYSQL_DB` | MySQL database name | `roxywi` |
| `TZ` | Timezone | `America/New_York` |

## Building from Source

```bash
# Build the image
docker build -t roxy-wi:local -f docker/Dockerfile .

# Run with your custom build
APPLICATION_IMAGENAME=roxy-wi APPLICATION_IMAGEVERSION=local \
  docker compose -f docker/docker-compose.yml up -d
```

## Health Checks

The container exposes a health check endpoint at `/api/health`.

```bash
# Check container health
docker inspect --format='{{.State.Health.Status}}' ROXY-WI-APP-001
```

## Troubleshooting

### View Logs

```bash
# All container logs
docker logs ROXY-WI-APP-001

# Application logs (from bind mount)
cat /custom/docker/stacks/stk-roxy-wi-001/Application/Logs/flask.log

# Or from container
docker exec ROXY-WI-APP-001 cat /var/log/roxy-wi/flask.log
docker exec ROXY-WI-APP-001 cat /var/log/nginx/roxy-wi-error.log
```

### Shell Access

```bash
docker exec -it ROXY-WI-APP-001 /bin/bash
```

### Reset to Defaults

```bash
# Stop and remove containers
docker compose -f docker/docker-compose.yml down

# Remove data (CAUTION: destroys all data)
rm -rf /custom/docker/stacks/stk-roxy-wi-001

# Recreate directories and start fresh
mkdir -p /custom/docker/stacks/stk-roxy-wi-001/Database/Data
mkdir -p /custom/docker/stacks/stk-roxy-wi-001/Application/{Data,Logs,Config}
docker compose -f docker/docker-compose.yml up -d
```

## Networks

The stack creates two networks:

| Network | Type | Purpose |
|---------|------|---------|
| `ROXY-WI-EXTERNAL` | bridge | External access to the application |
| `ROXY-WI-INTERNAL` | bridge (internal) | Secure database communication |

## Watchtower Integration

Both containers include labels for [Watchtower](https://containrrr.dev/watchtower/) automatic updates:

- Database: Disabled by default (`DATABASE_ENABLEAUTOMATICUPDATES=false`)
- Application: Enabled by default (`APPLICATION_ENABLEAUTOMATICUPDATES=true`)

