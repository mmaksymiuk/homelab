#!/bin/bash
# Bootstrap script for Debian server
# This script handles the initial setup where sudo may not be installed yet
# Usage: Run as root first time, or run as user with sudo already configured

set -e

# Get the current username
CURRENT_USER=$(whoami)
CURRENT_UID=$(id -u)

echo "=== Debian Server Bootstrap Script ==="
echo "Running as user: $CURRENT_USER (UID: $CURRENT_UID)"

# Check if we're running as root
if [ "$CURRENT_UID" -eq 0 ]; then
    echo ""
    echo "Running as root. Installing sudo and configuring for regular user..."
    echo ""
    
    # Update package list
    echo "Updating package list..."
    apt-get update
    
    # Install sudo
    echo "Installing sudo..."
    apt-get install -y sudo
    
    # Install essential packages
    echo "Installing essential packages..."
    apt-get install -y \
        curl \
        wget \
        git \
        vim \
        nano \
        htop \
        iotop \
        net-tools \
        dnsutils \
        python3 \
        python3-apt \
        python3-pip \
        openssh-server \
        ca-certificates
    
    # Ask for the username to configure
    echo ""
    read -p "Enter the username to configure for Ansible (default: maxu): " TARGET_USER
    TARGET_USER=${TARGET_USER:-maxu}
    
    # Check if user exists
    if ! id "$TARGET_USER" &>/dev/null; then
        echo "Creating user $TARGET_USER..."
        useradd -m -s /bin/bash "$TARGET_USER"
        echo ""
        echo "Please set a password for $TARGET_USER:"
        passwd "$TARGET_USER"
    else
        echo "User $TARGET_USER already exists."
    fi
    
    # Add user to sudo group
    echo "Adding $TARGET_USER to sudo group..."
    usermod -aG sudo "$TARGET_USER"
    
    # Configure passwordless sudo for the user
    echo "Configuring passwordless sudo for $TARGET_USER..."
    echo "$TARGET_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$TARGET_USER
    chmod 0440 /etc/sudoers.d/$TARGET_USER
    
    # Verify configuration
    echo ""
    echo "Verifying sudo configuration..."
    if sudo -u "$TARGET_USER" sudo -n true 2>/dev/null; then
        echo "✓ Sudo configuration successful for $TARGET_USER"
    else
        echo "⚠ WARNING: Sudo test failed. Manual verification needed."
    fi
    
    echo ""
    echo "=== Bootstrap Complete ==="
    echo ""
    echo "Next steps (run from your local machine):"
    echo "1. Copy your SSH public key:"
    echo "   ssh-copy-id -i ~/.ssh/id_rsa.pub $TARGET_USER@<server-ip>"
    echo ""
    echo "2. Test SSH key login:"
    echo "   ssh $TARGET_USER@<server-ip>"
    echo ""
    echo "3. Update inventory/production/hosts.yml with your server IP"
    echo ""
    echo "4. Deploy with Ansible:"
    echo "   ansible-playbook -i inventory/production playbooks/site.yml"
    echo ""

else
    # Running as regular user
    echo ""
    echo "Running as regular user: $CURRENT_USER"
    echo ""
    
    # Check if sudo is available
    if ! command -v sudo &> /dev/null; then
        echo "ERROR: sudo is not installed on this system!"
        echo ""
        echo "Please run this script as root first to install sudo:"
        echo "   curl -fsSL <script-url> | sudo bash"
        echo "   or"
        echo "   su -c 'bash -c \"\$(curl -fsSL <script-url>)\"'"
        echo ""
        echo "Or manually:"
        echo "   su -"
        echo "   apt-get update && apt-get install -y sudo"
        echo "   usermod -aG sudo $CURRENT_USER"
        echo "   echo '$CURRENT_USER ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$CURRENT_USER"
        echo "   exit"
        echo ""
        exit 1
    fi
    
    # Check if we have sudo access
    echo "Checking sudo access..."
    if ! sudo -n true 2>/dev/null; then
        echo ""
        echo "ERROR: No passwordless sudo access configured!"
        echo ""
        echo "You need to either:"
        echo "1. Run this script as root first (recommended)"
        echo "2. Use 'su' to become root and configure sudo manually"
        echo ""
        echo "To run as root:"
        echo "   su -c 'bash -c \"\$(curl -fsSL <script-url>)\"'"
        echo ""
        exit 1
    fi
    
    echo "✓ Sudo is available and configured"
    echo ""
    
    # Update system
    echo "Updating system packages..."
    sudo apt-get update
    sudo apt-get upgrade -y
    
    # Install essential packages
    echo "Installing essential packages..."
    sudo apt-get install -y \
        curl \
        wget \
        git \
        vim \
        nano \
        htop \
        iotop \
        net-tools \
        dnsutils \
        python3 \
        python3-apt \
        python3-pip \
        openssh-server \
        ca-certificates
    
    # Ensure passwordless sudo is configured
    if [ ! -f "/etc/sudoers.d/$CURRENT_USER" ]; then
        echo "Configuring passwordless sudo..."
        echo "$CURRENT_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$CURRENT_USER > /dev/null
        sudo chmod 0440 /etc/sudoers.d/$CURRENT_USER
    fi
    
    echo ""
    echo "=== Bootstrap Complete ==="
    echo "User: $CURRENT_USER"
    echo ""
    echo "Next steps (run from your local machine):"
    echo "1. Copy your SSH public key:"
    echo "   ssh-copy-id -i ~/.ssh/id_rsa.pub $CURRENT_USER@<server-ip>"
    echo ""
    echo "2. Test SSH key login:"
    echo "   ssh $CURRENT_USER@<server-ip>"
    echo ""
    echo "3. Update inventory/production/hosts.yml:"
    echo "   ansible_host: <your-server-ip>"
    echo "   ansible_user: $CURRENT_USER"
    echo ""
    echo "4. Deploy with Ansible:"
    echo "   ansible-playbook -i inventory/production playbooks/site.yml"
    echo ""
fi
