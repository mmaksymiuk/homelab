# Homelab Ansible Infrastructure

Automated homelab setup using Ansible and Docker for Debian servers.

## Quick Start

```bash
# 1. Bootstrap server (run ON THE SERVER as root first time)
# This installs sudo and configures your user
curl -fsSL https://raw.githubusercontent.com/yourusername/homelab/main/scripts/bootstrap.sh | sudo bash

# Or if you don't have sudo yet, run as root:
# su -
# curl -fsSL https://raw.githubusercontent.com/yourusername/homelab/main/scripts/bootstrap.sh | bash

# 2. Copy SSH key from YOUR LOCAL MACHINE (will prompt for password)
# Replace 'maxu' with your actual username if different
ssh-copy-id -i ~/.ssh/id_rsa.pub maxu@your-server-ip

# 3. Test SSH key works (should NOT ask for password)
ssh maxu@your-server-ip

# 4. Update inventory with your username and server IP
vim inventory/production/hosts.yml
# Change: ansible_user: maxu
# Change: ansible_host: your-server-ip

# 5. Configure secrets on YOUR LOCAL MACHINE
cp templates/configs/.env.j2 files/docker-compose/.env
vim files/docker-compose/.env  # Add your credentials

# 6. Deploy everything (SSH password auth will be disabled!)
ansible-playbook -i inventory/production playbooks/site.yml
ansible-playbook -i inventory/production playbooks/deploy-containers.yml
```

## What's Included

### Infrastructure
- SSH hardening with key-only auth
- UFW firewall with fail2ban
- Automated disk spin-down for power saving
- Cockpit web management interface

### Storage
- **1TB NVMe**: OS + containers
- **2TB NVMe**: Performance tier (databases)
- **1TB SSD**: Metadata & cache
- **10TB HDD**: Media (always on)
- **4TB+3TB HDD**: Backups (spin-down)

### Services
- **Traefik**: Reverse proxy + SSL (Let's Encrypt)
- **Jellyfin**: Media server
- **Pi-hole**: DNS ad blocker
- **Cloudflare Tunnel**: External access without public IP
- **Home Assistant**: Home automation
- **Mosquitto**: MQTT broker
- **Zigbee2MQTT**: Zigbee bridge
- **Prometheus + Grafana**: Monitoring
- **InfluxDB**: Time-series database

## Documentation

See [docs/setup.md](docs/setup.md) for complete documentation.

## Directory Structure

```
.
├── ansible.cfg
├── inventory/
├── playbooks/
├── roles/
├── files/docker-compose/
├── templates/
├── docs/
└── scripts/
```

## License

MIT
