# Homelab Setup Guide

Complete Ansible-based homelab infrastructure for Debian servers with Docker containers, monitoring, and home automation.

## Architecture

### Hardware Layout
```
1TB NVMe   -> /             (OS, Docker containers, databases)
2TB NVMe   -> /mnt/fast     (Performance tier: InfluxDB, transcode cache)
1TB SSD    -> /mnt/metadata (Jellyfin metadata, temp files)
10TB HDD   -> /mnt/media    (Movies, TV shows, music - 24/7 access)
4TB HDD    -> /mnt/backups  (Primary backups - spin-down)
3TB HDD    -> /mnt/backups/disk2 (Secondary backups - spin-down)
```

### Disk Power Management
- HDDs spin down after 30 minutes of inactivity
- Saves power and extends disk lifespan
- Media disk (10TB) stays online for immediate access

## Quick Start

### 1. Initial Server Setup

**Run these commands ON YOUR DEBIAN SERVER** as root (first time only):

```bash
# Download and run bootstrap script as root
# This installs sudo and configures your user
curl -fsSL https://raw.githubusercontent.com/yourusername/homelab/main/scripts/bootstrap.sh | bash

# Or manually run the local script as root:
cd scripts && bash bootstrap.sh
```

The bootstrap script will:
- Install sudo (if not present)
- Update system packages
- Install essential tools (python3, openssh-server, etc.)
- Create/configure your user (default: maxu)
- Configure passwordless sudo for your user
- Set up SSH key directory

**Note:** If your user already exists, it will just configure sudo. If not, it will create the user and prompt for a password.

### 2. Configure Inventory

On your **local machine**, edit `inventory/production/hosts.yml`:
```yaml
all:
  children:
    homelab:
      hosts:
        homelab-server:
          ansible_host: YOUR_SERVER_IP
          ansible_user: maxu  # Change to your existing username
```

Also update `ansible.cfg` if needed:
```ini
[defaults]
remote_user = maxu  # Change to your username
```

### 3. Copy SSH Key

**From your local machine**, copy your SSH public key to the server (you'll be prompted for your user's password):

```bash
# Replace 'maxu' with your actual username
ssh-copy-id -i ~/.ssh/id_rsa.pub maxu@YOUR_SERVER_IP

# Test that key authentication works (should NOT ask for password):
ssh maxu@YOUR_SERVER_IP
```

**Important:** Only proceed after SSH key login works without a password!

### 4. Configure Secrets

Create and edit environment file:
```bash
cp templates/configs/.env.j2 files/docker-compose/.env
# Edit with your actual values
vim files/docker-compose/.env
```

### 5. Run Ansible Playbooks

⚠️ **WARNING:** The `site.yml` playbook will disable password authentication and root login via SSH. Make sure your SSH key works before running this!

Bootstrap the server:
```bash
ansible-playbook -i inventory/production playbooks/site.yml
```

Deploy containers:
```bash
ansible-playbook -i inventory/production playbooks/deploy-containers.yml
```

After `site.yml` completes, password authentication will be disabled. You can only log in via SSH key.

## Directory Structure

```
homelab/
├── ansible.cfg                 # Ansible configuration
├── inventory/
│   ├── production/
│   │   ├── hosts.yml          # Server inventory
│   │   └── group_vars/
│   │       └── all.yml        # Global variables
│   └── host_vars/
│       └── homelab-server.yml # Server-specific vars
├── playbooks/
│   ├── site.yml               # Main server setup
│   ├── deploy-containers.yml  # Deploy services
│   ├── maintenance.yml        # Updates & cleanup
│   └── bootstrap.yml          # Initial bootstrap
├── roles/
│   ├── common/                # Base packages
│   ├── security/              # SSH hardening, fail2ban, UFW
│   ├── storage/               # Disk setup, spin-down
│   ├── docker/                # Docker installation
│   ├── cockpit/               # Web management
│   ├── monitoring/            # Prometheus/Grafana
│   └── backups/               # Restic backups
├── files/docker-compose/      # Docker Compose files
├── templates/                 # Jinja2 templates
└── docs/                      # Documentation
```

## Services

### Core Services (docker-compose.yml)

#### Traefik
- **Purpose**: Reverse proxy with automatic SSL
- **Access**: https://traefik.yourdomain.com
- **Features**:
  - Automatic Let's Encrypt SSL via Cloudflare
  - Dashboard for monitoring routes
  - Middleware support (auth, rate limiting)

#### Pi-hole
- **Purpose**: DNS-based ad blocker
- **Access**: https://pihole.yourdomain.com
- **Ports**: 53/tcp, 53/udp (DNS)
- **Features**:
  - Network-wide ad blocking
  - Custom DNS entries
  - Query logging

#### Cloudflare Tunnel
- **Purpose**: Access services without public IP
- **Features**:
  - Secure tunnel to Cloudflare edge
  - No port forwarding needed
  - DDoS protection

#### Jellyfin
- **Purpose**: Media server (Plex alternative)
- **Access**: https://jellyfin.yourdomain.com
- **Features**:
  - Hardware transcoding (Intel/AMD)
  - No subscription required
  - Full privacy

### Monitoring Stack (docker-compose.monitoring.yml)

#### Prometheus
- **Purpose**: Metrics collection
- **Access**: https://prometheus.yourdomain.com
- **Features**:
  - Time-series data storage
  - Service discovery
  - Alerting rules

#### Grafana
- **Purpose**: Visualization dashboards
- **Access**: https://grafana.yourdomain.com
- **Default Login**: admin/admin
- **Features**:
  - Pre-built dashboards
  - Multiple data sources
  - Alert notifications

#### InfluxDB
- **Purpose**: High-performance time-series database
- **Access**: https://influxdb.yourdomain.com
- **Features**:
  - Optimized for IoT/Home Assistant
  - 30-day retention policy
  - SQL-like query language

### Home Automation (docker-compose.home.yml)

#### Home Assistant
- **Purpose**: Home automation hub
- **Access**: https://home.yourdomain.com
- **Features**:
  - Device automation
  - Dashboard UI
  - Integration with MQTT and Zigbee

#### Mosquitto MQTT
- **Purpose**: Message broker for IoT devices
- **Port**: 1883 (MQTT), 9001 (WebSocket)
- **Features**:
  - Lightweight messaging
  - Publish/subscribe pattern
  - SSL/TLS support

#### Zigbee2MQTT
- **Purpose**: Zigbee to MQTT bridge
- **Access**: https://zigbee.yourdomain.com
- **Hardware**: Requires USB Zigbee coordinator (e.g., CC2652P)
- **Features**:
  - Control Zigbee devices
  - Device pairing
  - Network map visualization

## Playbooks

### site.yml
Main server configuration:
- System updates
- Security hardening
- Storage setup
- Docker installation
- Cockpit management interface

```bash
ansible-playbook -i inventory/production playbooks/site.yml
```

### deploy-containers.yml
Deploy all containerized services:
- Creates Docker networks
- Copies compose files
- Starts services

```bash
ansible-playbook -i inventory/production playbooks/deploy-containers.yml
```

**Tags:**
- `--tags core`: Deploy only core services
- `--tags monitoring`: Deploy monitoring stack
- `--tags home`: Deploy home automation

### maintenance.yml
Regular maintenance tasks:
- System updates
- Docker cleanup
- Disk space check

```bash
ansible-playbook -i inventory/production playbooks/maintenance.yml
```

### bootstrap.yml
Initial server bootstrap (run once):
- Creates ansible user
- Installs Python
- Sets up sudo

```bash
ansible-playbook -i inventory/production playbooks/bootstrap.yml --ask-pass --ask-become-pass
```

## Security

### SSH Hardening
- Password authentication disabled
- Root login disabled
- Key-based authentication only
- Strong cryptographic algorithms

### Firewall (UFW)
- SSH access allowed
- Cockpit web interface allowed
- Internal network access (192.168.0.0/16)
- Default deny policy

### Fail2ban
- SSH brute-force protection
- 3 failed attempts = 1 hour ban
- Automatic unban after ban time

### Secrets Management
- Ansible Vault for sensitive data
- Environment files for container configs
- No secrets in Git

## Storage Management

### Disk Spin-down
HDDs configured to spin down after 30 minutes of inactivity:
- Saves power
- Reduces noise
- Extends disk lifespan
- Configured in `/etc/hdparm.conf`

### Backup Strategy
- Daily automated backups at 2 AM
- Restic for deduplicated backups
- 30-day retention policy
- Rotates between backup disks

### Restore from Backup
```bash
# List snapshots
restic -r /mnt/backups/restic snapshots

# Restore specific snapshot
restic -r /mnt/backups/restic restore <snapshot-id> --target /restore/path
```

## Troubleshooting

### Check service status
```bash
# Docker containers
docker ps -a

# Container logs
docker logs <container-name>

# System services
systemctl status <service>
```

### View Ansible logs
```bash
# Run with verbose output
ansible-playbook -i inventory/production playbooks/site.yml -vvv
```

### Reset Docker
```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove containers
docker rm $(docker ps -aq)

# Start fresh
ansible-playbook -i inventory/production playbooks/deploy-containers.yml
```

### Access Cockpit
Web-based server management:
- URL: https://your-server-ip:9090
- Login: Your admin user credentials

## Maintenance

### Weekly Tasks
```bash
# Update system and containers
ansible-playbook -i inventory/production playbooks/maintenance.yml

# Check disk space
df -h
```

### Monthly Tasks
```bash
# Review logs
journalctl --since "1 month ago" | less

# Check backup integrity
restic -r /mnt/backups/restic check

# Verify disk health
smartctl -a /dev/sdX
```

### Update Ansible Playbooks
```bash
git pull
ansible-playbook -i inventory/production playbooks/site.yml
ansible-playbook -i inventory/production playbooks/deploy-containers.yml
```

## Customization

### Add New Services
1. Create Docker Compose entry in `files/docker-compose/`
2. Add to `playbooks/deploy-containers.yml`
3. Configure Traefik labels for SSL
4. Deploy with tags

### Modify Storage Layout
Edit `inventory/production/group_vars/all.yml`:
```yaml
storage_config:
  nvme_system: /dev/nvme0n1
  # Add/modify devices

mount_points:
  performance: /mnt/fast
  # Add/modify mount points
```

### Change Backup Schedule
Edit `roles/backups/tasks/main.yml` and adjust cron timing.

## Support

- **Cockpit**: https://server-ip:9090
- **Documentation**: See `docs/` directory
- **Logs**: `/var/log/`
- **Docker**: `/var/lib/docker/`

## License

MIT License - Feel free to use and modify for your homelab!
