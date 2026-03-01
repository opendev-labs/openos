#!/bin/bash
# MoltOS Workspace Recovery Script

echo "--- UNLOCKING THE FORGE ---"

# 1. Clear APT locks
echo "Stopping stuck apt processes..."
sudo kill -9 11441 16640 16641 16642 2>/dev/null
sudo rm /var/lib/dpkg/lock-frontend 2>/dev/null
sudo rm /var/lib/apt/lists/lock 2>/dev/null
sudo rm /var/cache/apt/archives/lock 2>/dev/null
sudo dpkg --configure -a

# 2. Kill processes holding the USB
USB_MOUNT="/media/cube/e185d639-3617-4b20-a95f-e205cdcc28e4"
USB_DEV="/dev/sdc1"

echo "Clearing USB busy state..."
sudo fuser -k -m "$USB_MOUNT" 2>/dev/null

# 3. Repair Filesystem
echo "Repairing USB filesystem ($USB_DEV)..."
sudo umount -l "$USB_MOUNT" 2>/dev/null
sudo fsck.ext4 -f -y "$USB_DEV"

# 4. Install QEMU
echo "Installing QEMU tracking dependencies..."
sudo apt update
sudo apt install -y qemu-system-x86 qemu-utils

echo "--- FORGE UNLOCKED: Ready to resume MoltOS build ---"
