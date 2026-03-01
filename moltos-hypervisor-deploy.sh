#!/bin/bash
# MoltOS Hypervisor Deploy - Sovereign VM Host Transformation
# Transforms Ubuntu into a professional-grade VM appliance host

set -e

# Configuration
ORANGE='\033[38;5;208m'
BOLD='\033[1m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${ORANGE}${BOLD}"
echo "================================================================"
echo "     MOLT OS HYPERVISOR DEPLOYMENT - SOVEREIGN MODE            "
echo "================================================================"
echo -e "${NC}"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${ORANGE}[!]${NC} Please run without sudo. Script will request sudo when needed."
   exit 1
fi

# 1. System Detection
echo -e "${BLUE}[▸]${NC} Detecting host environment..."
if ! lsb_release -d | grep -qi "ubuntu"; then
    echo -e "${ORANGE}[!]${NC} Warning: Not running on Ubuntu. Proceeding anyway..."
fi

# 2. VirtualBox Installation
echo -e "${BLUE}[▸]${NC} Installing VirtualBox 7.0..."
if ! command -v vboxmanage &> /dev/null; then
    sudo apt update
    sudo apt install -y wget gnupg
    
    # Add Oracle VirtualBox repository
    wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
    
    sudo apt update
    sudo apt install -y virtualbox-7.0
    
    echo -e "${GREEN}[✓]${NC} VirtualBox 7.0 installed successfully"
else
    echo -e "${GREEN}[✓]${NC} VirtualBox already installed: $(vboxmanage --version)"
fi

# 3. Extension Pack Installation
echo -e "${BLUE}[▸]${NC} Installing VirtualBox Extension Pack..."
VBOX_VERSION=$(vboxmanage --version | cut -d'r' -f1)
EXTPACK_URL="https://download.virtualbox.org/virtualbox/${VBOX_VERSION}/Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack"

if ! vboxmanage list extpacks | grep -q "Oracle VM VirtualBox Extension Pack"; then
    wget -O /tmp/vbox-extpack.vbox-extpack "$EXTPACK_URL"
    echo "y" | sudo vboxmanage extpack install --replace /tmp/vbox-extpack.vbox-extpack || true
    rm -f /tmp/vbox-extpack.vbox-extpack
    echo -e "${GREEN}[✓]${NC} Extension Pack installed"
else
    echo -e "${GREEN}[✓]${NC} Extension Pack already installed"
fi

# 4. User Group Configuration
echo -e "${BLUE}[▸]${NC} Configuring user permissions..."
sudo usermod -aG vboxusers "$USER"
echo -e "${GREEN}[✓]${NC} User added to vboxusers group"

# 5. VM Storage Pool
echo -e "${BLUE}[▸]${NC} Creating VM storage pool..."
VM_POOL="/opt/moltos/vms"
sudo mkdir -p "$VM_POOL"
sudo chown "$USER:$USER" "$VM_POOL"
vboxmanage setproperty machinefolder "$VM_POOL"
echo -e "${GREEN}[✓]${NC} VM pool created at $VM_POOL"

# 6. Network Configuration
echo -e "${BLUE}[▸]${NC} Configuring virtual networking..."
if ! vboxmanage list hostonlyifs | grep -q "vboxnet0"; then
    vboxmanage hostonlyif create || true
fi
echo -e "${GREEN}[✓]${NC} Virtual network interfaces ready"

# 7. Install QEMU tools for legacy support
echo -e "${BLUE}[▸]${NC} Installing legacy QEMU tools..."
sudo apt install -y qemu-system-x86 qemu-utils ovmf

echo -e "${ORANGE}${BOLD}"
echo "================================================================"
echo "     HYPERVISOR DEPLOYMENT COMPLETE                             "
echo "================================================================"
echo -e "${NC}"
echo -e "${GREEN}[✓]${NC} VirtualBox 7.0 with Extension Pack installed"
echo -e "${GREEN}[✓]${NC} User permissions configured"
echo -e "${GREEN}[✓]${NC} VM storage pool: $VM_POOL"
echo -e ""
echo -e "${ORANGE}[!]${NC} ${BOLD}IMPORTANT:${NC} Log out and back in for group changes to take effect"
echo -e "${BLUE}[▸]${NC} Next: Run ${BOLD}./moltos-vm-controller create${NC} to spawn your first VM"
