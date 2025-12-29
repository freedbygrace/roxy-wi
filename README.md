# ![alt text](https://roxy-wi.org/static/images/logo_menu.png "Logo")

**Roxy-WI** is a powerful web-based frontend management platform for **HAProxy**, **Nginx**, **Apache**, and **Keepalived**. It provides a centralized control panel to configure, monitor, and coordinate load balancing and high-availability failover across multiple local or remote servers.

Whether you're managing a single node or orchestrating dozens of load balancers across your infrastructure, Roxy-WI gives you:

- **Unified Management** — Configure and push changes to all your HAProxy, Nginx, Apache, and Keepalived instances from a single web interface
- **Multi-Node Coordination** — Manage local and remote servers via SSH, keeping configurations synchronized across your entire cluster
- **Load Balancing Control** — Add, edit, or remove backend servers dynamically; enable/disable nodes without service restarts
- **High Availability** — Coordinate failover with Keepalived VIPs, monitor service health, and get alerted on state changes
- **Real-Time Monitoring** — View server status, analyze logs, track metrics, and visualize traffic flows from one dashboard
- **Secure Access** — Role-based access control, LDAP integration, and SSH key management for secure multi-user environments

Leave your [feedback](https://github.com/hap-wi/roxy-wi/issues)

# Get involved
* [Telegram Channel](https://t.me/roxy_wi_channel) about Roxy-WI, talks and questions are welcome

# Demo site
[Demo site](https://demo.roxy-wi.org) Login/password: admin/admin. Server resets every hour.

![alt text](https://roxy-wi.org/static/images/viewstat.png "HAProxy state page")

# Features:
1. Installing and updating HAProxy, Nginx, Apache and Keepalived with Roxy-WI as a system service
2. Installing and updating HAProxy and Nginx with Roxy-WI as a Docker service
3. Installing and updating HAProxy, Nginx, Apache, Keepalived, and Node exporters with Roxy-WI
4. Downloading, updating, and formatting GeoIP to the acceptable format for HAProxy, and NGINX with Roxy-WI
5. Dynamic change of Maxconn, Black/white lists, add, edit, or delete backend's IP address and port with saving changes to the config file
6. Configuring HAProxy, Nginx, Apache and Keepalived in a jiffy with Roxy-WI
7. Viewing and analyzing the status of all Frontend/backend servers via Roxy-WI from a single control panel
8. Enabling/disabling servers through stats page without rebooting HAProxy
9. Viewing/Analyzing HAProxy, Nginx, Apache and Keepalived logs right from the Roxy-WI web interface
10. Creating and visualizing the HAProxy workflow from Web Ui
11. Pushing Your changes to your HAProxy, Nginx, Apache, and Keepalived servers with a single click via the web interface
12. Getting info on past changes, evaluating your config files, and restoring the previous stable config at any time with a single click right from the Web interface
13. Adding/Editing Frontend or backend servers via the web interface with a click
14. Editing the config of HAProxy, Nginx, Apache, and Keepalived and push interchanges to All Master/Slave servers by a single click
15. Adding Multiple servers to ensure the Config Sync between servers
16. Managing the ports assigned to Frontend automatically
17. Evaluating the changes of recent configs pushed to HAProxy, Nginx, Apache, and Keepalived instances right from the Web UI
18. Multiple User Roles support for privileged-based Viewing and editing of Config
19. Creating Groups and adding/removing servers to ensure the proper identification for your HAProxy, Nginx, and Apache Clusters
20. Sending notifications from Roxy-WI via Telegram, Slack, Email, PageDuty, Mattermost, and via the web interface
21. Supporting high Availability to ensure uptime to all Master slave servers configured
22. Support of SSL (including Let's Encrypt)
23. Support of SSH Key for managing multiple HAProxy, Nginx, Apache, and Keepalived Servers straight from Roxy-WI
24. SYN flood protect
25. Alerting about changes of the state of HAProxy backends, about approaching the limit of Maxconn
26. Alerting about the state of HAProxy, Nginx, Apache, and Keepalived service
27. Gathering metrics for incoming connections
28. Web acceleration settings
29. Firewall for web application (WAF)
30. LDAP support
31. Keep active HAProxy, Nginx, Apache, and Keepalived services
32. Possibility to hide parts of the config with tags for users with the "guest" role: "HideBlockStart" and "HideBlockEnd"
33. Mobile-ready design
34. [SMON](https://roxy-wi.org/services/smon) (Check: Ping, TCP/UDP, HTTP(s), SSL expiry, HTTP body answer, DNS records, Status pages)
35. Backup HAProxy, Nginx, Apache, and Keepalived config files through Roxy-WI



![alt text](https://roxy-wi.org/static/images/roxy-wi-metrics.png "Merics")

# Install

## Docker (Recommended)

The easiest way to get started is with Docker. Default configuration uses SQLite (no external database required).

### Quick Start

```bash
# Clone the repository
git clone https://github.com/hap-wi/roxy-wi.git
cd roxy-wi

# Create environment file
cp docker/.env.example docker/.env

# Start the application
docker compose -f docker/docker-compose.yml up -d
```

Access Roxy-WI at `http://localhost:8080` (default credentials: `admin` / `admin`)

### Docker Compose Example

```yaml
name: 'roxy-wi'

networks:
  EXTERNAL:
    name: ROXY-WI-EXTERNAL
    driver: bridge

services:
  Application:
    image: 'roxy-wi/roxy-wi:latest'
    container_name: ROXY-WI-APP-001
    hostname: ROXY-WI-APP-001
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/api/health"]
      start_period: 60s
      interval: 30s
      retries: 3
      timeout: 10s
    environment:
      TZ: 'America/New_York'
      ROXY_WI_MYSQL_ENABLE: '0'
      ROXY_WI_SECRET_PHRASE: ''
    networks:
      EXTERNAL:
    ports:
      - "8080:80"
    volumes:
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
      - "./data:/var/lib/roxy-wi:rw"
      - "./logs:/var/log/roxy-wi:rw"
      - "./config:/etc/roxy-wi:rw"
```

### Environment Variables (.env)

```bash
# Stack Configuration
STACK_NAME=stk-roxy-wi-001
STACK_BINDMOUNTROOT=custom/docker/stacks
TZ=America/New_York
DNSSERVER=1.1.1.1

# Application
APPLICATION_IMAGENAME=roxy-wi/roxy-wi
APPLICATION_IMAGEVERSION=latest
APPLICATION_PORT_EXTERNAL=8080
APPLICATION_MYSQL_ENABLE=0
# Leave empty to auto-generate, or set a custom 32-char base64 secret
APPLICATION_SECRET_PHRASE=
```

### Building the Image Locally

```bash
# Build for local use
docker build -t roxy-wi/roxy-wi:latest -f docker/Dockerfile .

# Build with custom tag
docker build -t myrepo/roxy-wi:2024.12.29.1200 -f docker/Dockerfile .
```

### Building and Pushing to DockerHub

Use the included build script for multi-platform builds with automatic tagging:

```bash
# Set DockerHub credentials
export DOCKERHUB_USERNAME=your-username
export DOCKERHUB_TOKEN=your-access-token

# Build and push (creates 'latest' and 'yyyy.mm.dd.hhmm' tags)
./scripts/docker-build-push.sh --repo your-username/roxy-wi

# Build only (no push)
./scripts/docker-build-push.sh --no-push

# Custom platform
./scripts/docker-build-push.sh --platform linux/amd64
```

Manual push example:

```bash
# Tag and push
docker tag roxy-wi/roxy-wi:latest your-username/roxy-wi:latest
docker tag roxy-wi/roxy-wi:latest your-username/roxy-wi:2024.12.29.1200
docker push your-username/roxy-wi:latest
docker push your-username/roxy-wi:2024.12.29.1200
```

For detailed Docker deployment instructions, see [docs/DOCKER.md](docs/DOCKER.md).

## RPM

### Read instruction on the official [site](https://roxy-wi.org/installation#rpm)

## DEB

### Read instruction on the official [site](https://roxy-wi.org/installation#deb)

# OS support
Roxy-WI supports the following OSes:
1. EL7(RPM installation and manual installation). It must be "Infrastructure Server" at least. x86_64 only
2. EL8(RPM installation and manual installation). It must be "Infrastructure Server" at least. x86_64 only
3. EL9(RPM installation and manual installation). It must be "Infrastructure Server" at least. x86_64 only
4. Amazon Linux 2(RPM installation and manual installation). x86_64 only
5. Ubuntu (DEB installation and manual installation). x86_64 only
6. Other Linux distributions (manual installation only). x86_64 only

![alt text](https://roxy-wi.org/static/images/smon_dashboard.png "SMON area")

# Database support

Default Roxy-WI use Sqlite, if you want use MySQL enable in config, and create database:

### For MySQL support:

### Read instruction on the official [site](https://roxy-wi.org/installation#database)

![alt text](https://roxy-wi.org/static/images/roxy-wi-overview.webp "Overview page")

# Settings


Login https://roxy-wi-server/admin, and add: users, groups, and servers. Default: admin/admin

### Read instruction on the official [site](https://roxy-wi.org/settings)

![alt text](https://roxy-wi.org/static/images/hapwi_overview.webp "HAProxy server overview page")


![alt text](https://roxy-wi.org/static/images/add.webp "Add proxy page")



# Troubleshooting
If you have error:
```
Internal Server Error
```

Do this:
```
$ cd /var/www/haproxy-wi/app
$ ./create_db.py
```

[Read more](https://roxy-wi.org/troubleshooting)
