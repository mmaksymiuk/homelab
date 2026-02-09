#!/bin/bash
# Bootstrap script for Debian server
# Run this script twice:
#   1. First as root (installs sudo, creates/configures user)
#   2. Then as the regular user (completes setup)

set -e

CURRENT_USER=$(whoami)
CURRENT_UID=$(id -u)

echo "=== Debian Server Bootstrap Script ==="
echo "Running as: $CURRENT_USER (UID: $CURRENT_UID)"
echo ""

# ============================================================================
# PHASE 1: Running as root
# ============================================================================
if [ "$CURRENT_UID" -eq 0 ]; then
    echo "📦 Phase 1: Initial system setup as root"
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
    
    # Get or create the target user
    echo ""
    read -p "Enter username to configure (default: maxu): " TARGET_USER
    TARGET_USER=${TARGET_USER:-maxu}
    
    # Create user if doesn't exist
    if ! id "$TARGET_USER" &>/dev/null; then
        echo ""
        echo "Creating user: $TARGET_USER"
        useradd -m -s /bin/bash "$TARGET_USER"
        echo ""
        echo "Please set a password for $TARGET_USER:"
        passwd "$TARGET_USER"
        echo ""
    else
        echo "User $TARGET_USER already exists"
    fi
    
    # Add to sudo group
    echo "Adding $TARGET_USER to sudo group..."
    usermod -aG sudo "$TARGET_USER"
    
    # Create passwordless sudo
    echo "Configuring passwordless sudo..."
    SUDOERS_FILE="/etc/sudoers.d/$TARGET_USER"
    echo "$TARGET_USER ALL=(ALL) NOPASSWD: ALL" > "$SUDOERS_FILE"
    chmod 0440 "$SUDOERS_FILE"
    chown root:root "$SUDOERS_FILE"
    
    # Validate
    if visudo -c; then
        echo "✓ Sudo configuration is valid"
    else
        echo "✗ Sudo configuration failed!"
        exit 1
    fi
    
    echo ""
    echo "=================================="
    echo "✓ Phase 1 complete!"
    echo ""
    echo "IMPORTANT: Now you MUST run this script again"
    echo "as the user '$TARGET_USER' to complete setup:"
    echo ""
    echo "   su - $TARGET_USER"
    echo "   bash /path/to/bootstrap.sh"
    echo ""
    echo "Or logout and SSH back in as $TARGET_USER, then run:"
    echo "   bash bootstrap.sh"
    echo "=================================="
    echo ""
    exit 0
fi

# ============================================================================
# PHASE 2: Running as regular user
# ============================================================================

echo "👤 Phase 2: Running as $CURRENT_USER"
echo ""

# Check if sudo is installed
if ! command -v sudo &> /dev/null; then
    echo "ERROR: sudo is not installed!"
    echo ""
    echo "Please run this script first as root:"
    echo "   su -"
    echo "   bash bootstrap.sh"
    echo ""
    exit 1
fi

# Check if we have passwordless sudo
echo "Checking sudo access..."
if ! sudo -n true 2>/dev/null; then
    echo ""
    echo "ERROR: Passwordless sudo is not configured!"
    echo ""
    echo "Please run this script as root first:"
    echo "   su -"
    echo "   bash bootstrap.sh"
    echo ""
    exit 1
fi

echo "✓ Passwordless sudo is configured"
echo ""

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Ensure all packages are installed
echo ""
echo "Installing/verifying essential packages..."
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

# Ensure .ssh directory exists
echo ""
echo "Setting up SSH directory..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Display next steps
echo ""
echo "=================================="
echo "✓ Bootstrap complete!"
echo ""
echo "User: $CURRENT_USER"
echo ""
echo "Next steps (run from your local machine):"
echo ""
echo "1. Copy your SSH public key:"
echo "   ssh-copy-id -i ~/.ssh/id_rsa.pub $CURRENT_USER@<server-ip>"
echo ""
echo "2. Test SSH key login (should NOT ask for password):"
echo "   ssh $CURRENT_USER@<server-ip>"
echo ""
echo "3. Update inventory/production/hosts.yml:"
echo "   ansible_host: <your-server-ip>"
echo "   ansible_user: $CURRENT_USER"
echo ""
echo "4. Run Ansible:"
echo "   ansible-playbook -i inventory/production playbooks/site.yml"
echo "=================================="
echo ""
