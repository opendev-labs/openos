#!/bin/bash
# MoltOS USB-NEXT: OpenOS VM Builder
# Builds a QEMU-compatible qcow2 image containing the XFCE desktop & NanoPi stack

set -e

# Configuration
WORKSPACE="/mnt/moltos-build/openos-build"
PROJECT_DIR="/home/cube/syncstack/opendev-labs/openos"
IMAGE_NAME="openos-vmagent.qcow2"
IMAGE_SIZE="30G" # Virtual size, qcow2 will only use what it needs
LOG_FILE="$WORKSPACE/build.log"

# Colors
ORANGE='\033[38;5;208m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${ORANGE}${BOLD}"
echo "===================================================="
echo "  MOLTOS USB-NEXT: OPENOS VM BUILDER (QEMU)"
echo "===================================================="
echo -e "${NC}"

# Ensure required packages exist
echo "Checking dependencies..."
if ! command -v qemu-img &> /dev/null; then
    echo "Installing qemu-utils..."
    sudo apt-get update && sudo apt-get install -y qemu-utils debootstrap
fi

# 1. Setup Workspace
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

# 2. Create raw disk image & format
echo "Creating dynamic virtual disk ($IMAGE_SIZE)..."
qemu-img create -f qcow2 "$IMAGE_NAME" "$IMAGE_SIZE"

# We must mount the qcow2 image to install the OS via debootstrap
echo "Mounting qcow2 image via NBD (Network Block Device)..."
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 "$IMAGE_NAME"

# Clean up trap in case of failure
cleanup() {
    echo "Cleaning up mounts and detaching NBD..."
    sudo umount /mnt/openos-chroot/dev/pts || true
    sudo umount /mnt/openos-chroot/dev || true
    sudo umount /mnt/openos-chroot/proc || true
    sudo umount /mnt/openos-chroot/sys || true
    sudo umount /mnt/openos-chroot || true
    sudo qemu-nbd --disconnect /dev/nbd0 || true
}
trap cleanup EXIT

# Partition the disk (MBR/DOS with one ext4 bootable partition)
echo "Partitioning the virtual disk..."
sudo parted -s /dev/nbd0 mklabel msdos
sudo parted -s /dev/nbd0 mkpart primary ext4 1MiB 100%
sudo parted -s /dev/nbd0 set 1 boot on

echo "Formatting partition as ext4..."
sudo mkfs.ext4 -F /dev/nbd0p1

# Mount for debootstrap
mkdir -p /mnt/openos-chroot
sudo mount /dev/nbd0p1 /mnt/openos-chroot

# 3. Base OS Installation (Ubuntu Jammy Minimal)
echo -e "${BLUE}[▸]${NC} Installing base OS (Ubuntu 22.04 Jammy)..."
sudo debootstrap --arch=amd64 jammy /mnt/openos-chroot http://archive.ubuntu.com/ubuntu/

# 4. Prepare Chroot Environment
echo "Mounting virtual filesystems..."
sudo mount -t proc /proc /mnt/openos-chroot/proc
sudo mount -t sysfs /sys /mnt/openos-chroot/sys
sudo mount -o bind /dev /mnt/openos-chroot/dev
sudo mount -o bind /dev/pts /mnt/openos-chroot/dev/pts

# Inject secrets and configs before chroot step
if [ -f "$PROJECT_DIR/moltos.secrets" ]; then
    sudo cp "$PROJECT_DIR/moltos.secrets" /mnt/openos-chroot/tmp/moltos.secrets
fi

# 5. Execute OS Configuration inside the VM
echo -e "${ORANGE}${BOLD}Configuring the OpenOS VM (Chroot)...${NC}"

# We create a script inside the chroot environment to run the complex apt installs
cat << 'EOF' | sudo tee /mnt/openos-chroot/opt/configure-openos.sh
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# Repositories
cat << REPO > /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://security.ubuntu.org/ubuntu/ jammy-security main restricted universe multiverse
REPO

apt-get update

# Install Kernel, GRUB, XFCE desktop, and QEMU guest agents
apt-get install -y linux-image-generic linux-headers-generic grub-pc xubuntu-core \
    qemu-guest-agent spice-vdagent sudo curl wget git \
    network-manager ca-certificates

# Install Docker & Ollama
curl -fsSL https://get.docker.com | sh
curl -fsSL https://ollama.com/install.sh | sh

# Configure GRUB
echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash console=ttyS0"' >> /etc/default/grub
update-grub
grub-install /dev/nbd0

# Create default User
useradd -m -s /bin/bash -G sudo,docker cube
echo 'cube:moltos' | chpasswd

# Pre-fetch NanoPi Model (1.5B)
echo "Pulling default NanoPi model..."
systemctl start ollama
# Note: In a real automated build, this needs a wait loop for ollama server to be ready
sleep 10
ollama pull qwen2.5:1.5b
systemctl stop ollama

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

sudo chmod +x /mnt/openos-chroot/opt/configure-openos.sh

# Run the configurator
sudo chroot /mnt/openos-chroot /opt/configure-openos.sh

echo -e "${ORANGE}${BOLD}====================================================${NC}"
echo -e "${ORANGE}${BOLD}  ✓ OpenOS VM Build COMPLETE${NC}"
echo -e "${ORANGE}${BOLD}====================================================${NC}"
echo "Image Location: $WORKSPACE/$IMAGE_NAME"
echo "You can now package this qcow2 image onto the host USB partition."
