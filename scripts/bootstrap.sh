#!/bin/bash
# Bootstrap script for existing Debian server user
# Run this on the server as the existing user (e.g., maxu)

set -e

# Get the current username
CURRENT_USER=$(whoami)

echo "=== Debian Server Bootstrap Script ==="
echo "Running as user: $CURRENT_USER"

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo "Please run as your regular user, not root"
   exit 1
fi

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo "Installing essential packages..."
sudo apt install -y \
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

# Configure sudo for current user without password
echo "Configuring sudo access..."
echo "$CURRENT_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$CURRENT_USER > /dev/null
sudo chmod 0440 /etc/sudoers.d/$CURRENT_USER

# Verify sudo works
echo "Testing sudo access..."
sudo -n true || { echo "ERROR: sudo configuration failed!"; exit 1; }

# Note: SSH hardening (disable password auth, root login) will be done by Ansible
# AFTER you've copied your SSH key. Don't disable password auth manually!

echo ""
echo "=== Bootstrap Complete ==="
echo "IMPORTANT: Password authentication is still enabled!"
echo ""
echo "Next steps:"
echo "1. From your local machine, copy your SSH public key:"
echo "   ssh-copy-id -i ~/.ssh/id_rsa.pub $CURRENT_USER@<server-ip>"
echo ""
echo "2. Test SSH key login (should NOT ask for password):"
echo "   ssh $CURRENT_USER@<server-ip>"
echo ""
echo "3. Update inventory/production/hosts.yml with your server IP"
echo ""
echo "4. Run Ansible to harden SSH and configure everything:"
echo "   ansible-playbook -i inventory/production playbooks/site.yml"
echo ""
echo "   This will disable password authentication and complete setup!"
echo ""
