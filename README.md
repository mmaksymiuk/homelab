# Homelab Ansible Infrastructure

Automated homelab setup using Ansible and Docker for Debian servers.

## Quick Start

```bash
# BOOTSTRAP - Run this script TWICE on the server:

# === PHASE 1: Run as ROOT ===
su -
curl -fsSL https://raw.githubusercontent.com/yourusername/homelab/main/scripts/bootstrap.sh | bash
# This will install sudo and create/configure your user
# When done, it will tell you to run again as the user

# === PHASE 2: Run as USER ===
# Logout and SSH back in as your user (e.g., maxu), then run:
bash bootstrap.sh
# This completes the setup

# === From your LOCAL MACHINE ===

# 1. Copy your SSH key (will prompt for password)
ssh-copy-id -i ~/.ssh/id_rsa.pub maxu@your-server-ip

# 2. Test SSH key works (should NOT ask for password)
ssh maxu@your-server-ip

# 3. Update inventory with your username and server IP
vim inventory/production/hosts.yml
# Change: ansible_user: maxu
# Change: ansible_host: your-server-ip

# 4. Configure secrets using Ansible Vault
# Edit the vault file with your actual credentials:
ansible-vault edit inventory/production/group_vars/vault.yml

# Or create a vault password file for easier usage:
echo "your-vault-password" > ~/.vault_pass.txt
chmod 600 ~/.vault_pass.txt

# 5. Update inventory with your specific network settings
vim inventory/production/group_vars/all.yml
# Change: ufw_trusted_networks to your actual home network

# 6. Deploy everything (SSH password auth will be disabled!)
ansible-playbook -i inventory/production playbooks/site.yml --vault-password-file ~/.vault_pass.txt
ansible-playbook -i inventory/production playbooks/deploy-containers.yml --vault-password-file ~/.vault_pass.txt
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

## Troubleshooting

### Sudo password required

If you get prompted for a password when running Ansible, the bootstrap didn't complete properly. Fix it by running the script again:

```bash
# Phase 1: As root
su -
bash bootstrap.sh

# Then Phase 2: As user
exit
ssh maxu@your-server-ip
bash bootstrap.sh
```

Or manually fix sudo:
```bash
# On the Debian server, run as root:
echo "maxu ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/maxu
chmod 0440 /etc/sudoers.d/maxu
visudo -c  # Verify syntax
```

## License

MIT
