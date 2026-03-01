#!/bin/bash
# MoltOS USB-NEXT: VMAGENT USB Creator
# Formats a target USB drive and copies the OpenOS VM and runner scripts

set -e

# Configuration
USB_DRIVE=$1
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORKSPACE="/mnt/moltos-build/openos-build"
IMAGE_PATH="$WORKSPACE/openos-vmagent.qcow2"

# Colors
ORANGE='\033[38;5;208m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${ORANGE}${BOLD}"
echo "===================================================="
echo "  MOLTOS USB-NEXT: VMAGENT CREATOR"
echo "===================================================="
echo -e "${NC}"

if [ -z "$USB_DRIVE" ]; then
    echo "❌ Error: Target USB drive not provided."
    echo "Usage: sudo ./create-usb-agent.sh /dev/sdX"
    echo ""
    echo "Available drives:"
    lsblk -d -o NAME,SIZE,MODEL | grep -E '^sd|nvme'
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script must be run as root."
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Error: OpenOS VM image not found at $IMAGE_PATH"
    echo "Please run ./openos-vm-builder.sh first."
    exit 1
fi

echo "⚠️  WARNING: ALL DATA ON $USB_DRIVE WILL BE DESTROYED."
read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

# Ensure drive is unmounted
echo "Unmounting any existing partitions on $USB_DRIVE..."
umount ${USB_DRIVE}* 2>/dev/null || true

# Partition the USB drive
echo "Formatting $USB_DRIVE as exFAT (Cross-platform compatibility)..."
# We use exFAT so Windows, macOS, and Linux can naturally read the USB without special drivers
parted -s "$USB_DRIVE" mklabel msdos
parted -s "$USB_DRIVE" mkpart primary exfat 1MiB 100%

# Install exfat tools if missing
if ! command -v mkfs.exfat &> /dev/null; then
    apt-get update && apt-get install -y exfat-fuse exfat-utils
fi

mkfs.exfat -n "MOLTOS_AGENT" "${USB_DRIVE}1"

# Copy files
echo "Mounting USB drive..."
mkdir -p /mnt/moltos-usb
mount "${USB_DRIVE}1" /mnt/moltos-usb

echo "Copying OpenOS VM Image (This may take a while)..."
# Using rsync for a progress bar
rsync -ah --progress "$IMAGE_PATH" /mnt/moltos-usb/

echo "Copying Runner Scripts..."
cp "$PROJECT_DIR/start-openos.sh" /mnt/moltos-usb/
cp "$PROJECT_DIR/start-openos.bat" /mnt/moltos-usb/
chmod +x /mnt/moltos-usb/start-openos.sh

echo "Syncing filesystem..."
sync

echo "Unmounting USB..."
umount /mnt/moltos-usb

echo -e "${ORANGE}${BOLD}====================================================${NC}"
echo -e "${ORANGE}${BOLD}  ✓ VMAGENT USB CREATED SUCCESSFULLY${NC}"
echo -e "${ORANGE}${BOLD}====================================================${NC}"
echo "You can now eject $USB_DRIVE."
echo "Plug it into any Windows, Mac, or Linux computer and run start-openos!"
