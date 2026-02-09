#!/bin/bash
# Bootstrap script for new Debian server
# Run this on the server before using Ansible

set -e

echo "=== Debian Server Bootstrap Script ==="

# Update system
echo "Updating system packages..."
apt update && apt upgrade -y

# Install essential packages
echo "Installing essential packages..."
apt install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    sudo \
    python3 \
    python3-apt \
    python3-pip \
    openssh-server \
    ca-certificates

# Create ansible user
echo "Creating ansible user..."
if ! id "ansible" &>/dev/null; then
    useradd -m -s /bin/bash -G sudo ansible
    echo "ansible ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ansible
fi

# Configure SSH
echo "Configuring SSH..."
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

echo ""
echo "=== Bootstrap Complete ==="
echo "Next steps:"
echo "1. Copy your SSH public key to the server:"
echo "   ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@<server-ip>"
echo "2. Update inventory/production/hosts.yml with your server IP"
echo "3. Run: ansible-playbook -i inventory/production playbooks/site.yml"
echo ""
echo "Server is ready for Ansible configuration!"
