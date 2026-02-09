# Homelab Ansible Infrastructure

Automated homelab setup using Ansible and Docker for Debian servers.

## Quick Start

```bash
# 1. Bootstrap server (run on server)
ssh root@your-server-ip 'bash -c "$(curl -fsSL https://raw.githubusercontent.com/yourusername/homelab/main/scripts/bootstrap.sh)"'

# 2. Copy SSH key
ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@your-server-ip

# 3. Configure secrets
vim files/docker-compose/.env

# 4. Deploy everything
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
