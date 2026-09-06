#!/usr/bin/env bash
# ==============================================================================
# Script: setup.sh
# Description: Automated setup for Vagrant, VMware Utility, and VMware Desktop Plugin.
# Ensures the latest versions are installed directly from official HashiCorp repos.
# ==============================================================================

set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check for root / sudo privileges
if [ "$EUID" -ne 0 ]; then
  error "Please run this script with root privileges or using sudo."
fi

# Detect Linux Distribution
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  error "OS not identified or unsupported."
fi

info "Detected distribution: $OS"

# 1. Add HashiCorp Repository & Install Vagrant + VMware Utility
case "$OS" in
  ubuntu|debian|pop|linuxmint|kali|elementary)
    # Remove any existing misconfigured hashicorp repo to prevent update crashes
    rm -f /etc/apt/sources.list.d/hashicorp.list

    info "Updating repositories and installing prerequisites..."
    # Using '|| true' on the first update in case other unrelated repos are broken
    apt-get update -y || true
    apt-get install -y wget gpg coreutils lsb-release curl

    # Smart codename resolution for Debian/Ubuntu derivatives
    if [ -n "$UBUNTU_CODENAME" ]; then
      REPO_CODENAME=$UBUNTU_CODENAME
    elif [ -n "$VERSION_CODENAME" ]; then
      REPO_CODENAME=$VERSION_CODENAME
    else
      REPO_CODENAME=$(lsb_release -cs)
    fi

    info "Adding official HashiCorp repository for $REPO_CODENAME..."
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    
    # Adding architecture specifically for better compatibility
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $REPO_CODENAME main" | tee /etc/apt/sources.list.d/hashicorp.list

    # Strict update after adding the correct repo
    apt-get update -y
    info "Installing the latest version of Vagrant and Vagrant VMware Utility..."
    apt-get install -y vagrant vagrant-vmware-utility
    ;;

  fedora|rhel|centos|rocky|almalinux)
    info "Adding official HashiCorp repository..."
    if command -v dnf &> /dev/null; then
      dnf install -y dnf-plugins-core
      dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
      info "Installing the latest version of Vagrant and Vagrant VMware Utility..."
      dnf install -y vagrant vagrant-vmware-utility
    else
      yum install -y yum-utils
      yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
      info "Installing the latest version of Vagrant and Vagrant VMware Utility..."
      yum install -y vagrant vagrant-vmware-utility
    fi
    ;;

  *)
    error "Linux distribution ($OS) is not supported. Please install dependencies manually."
    ;;
esac

# 2. Enable and Start VMware Utility Service
info "Enabling vagrant-vmware-utility service..."
systemctl enable --now vagrant-vmware-utility

# 3. Install Vagrant VMware Desktop Plugin for Non-Root User
REAL_USER=${SUDO_USER:-$USER}

info "Installing vagrant-vmware-desktop plugin for user $REAL_USER..."

if [ "$REAL_USER" != "root" ]; then
  su - "$REAL_USER" -c "vagrant plugin install vagrant-vmware-desktop"
else
  vagrant plugin install vagrant-vmware-desktop
fi

# 4. Status Verification
echo "--------------------------------------------------"
info "Checking installation status:"
vagrant --version
if systemctl is-active --quiet vagrant-vmware-utility; then
  echo -e "vagrant-vmware-utility service: ${GREEN}Active${NC}"
else
  echo -e "vagrant-vmware-utility service: ${RED}Inactive${NC}"
fi
echo "--------------------------------------------------"
info "Installation completed successfully! You can now configure 'config.yml' and run 'vagrant up'."
