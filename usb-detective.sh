#!/bin/bash
# MoltOS USB Detective - Automatic USB Detection & ISO Finder
# Monitors for USB insertion and locates ISO files automatically

set -e

ORANGE='\033[38;5;208m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${ORANGE}${BOLD}"
cat << "EOF"
═══════════════════════════════════════════════════════════
     MOLT OS USB DETECTIVE - ISO HUNTER MODE            
═══════════════════════════════════════════════════════════
EOF
echo -e "${NC}"

# Capture initial device state
echo -e "${BLUE}[▸]${NC} Scanning current devices..."
INITIAL_DEVICES=$(lsblk -ndo NAME,TYPE | grep disk | awk '{print $1}')

echo -e "${ORANGE}[!]${NC} ${BOLD}Please UNPLUG your USB drive now${NC}"
echo -e "${BLUE}[▸]${NC} Waiting for device removal..."

# Wait for device removal
while true; do
    CURRENT_DEVICES=$(lsblk -ndo NAME,TYPE | grep disk | awk '{print $1}')
    
    # Check if any device was removed
    if [ "$INITIAL_DEVICES" != "$CURRENT_DEVICES" ]; then
        echo -e "${GREEN}[✓]${NC} USB device removed detected"
        sleep 2
        break
    fi
    sleep 1
done

# Update baseline
BASELINE=$(lsblk -ndo NAME,TYPE | grep disk | awk '{print $1}')

echo -e "${ORANGE}[!]${NC} ${BOLD}Now PLUG IN your USB drive${NC}"
echo -e "${BLUE}[▸]${NC} Monitoring for new devices..."

# Monitor for new device
NEW_DEVICE=""
while true; do
    CURRENT=$(lsblk -ndo NAME,TYPE | grep disk | awk '{print $1}')
    
    # Find the difference
    NEW_DEVICE=$(comm -13 <(echo "$BASELINE" | sort) <(echo "$CURRENT" | sort) | head -1)
    
    if [ -n "$NEW_DEVICE" ]; then
        echo -e "${GREEN}[✓]${NC} New device detected: ${BOLD}/dev/$NEW_DEVICE${NC}"
        sleep 2
        break
    fi
    sleep 1
done

# Get partition info
echo -e "${BLUE}[▸]${NC} Analyzing partitions..."
PARTITION=$(lsblk -nlo NAME,TYPE | grep "part" | grep "$NEW_DEVICE" | head -1 | awk '{print $1}')

if [ -z "$PARTITION" ]; then
    echo -e "${ORANGE}[!]${NC} No partition found on device. Trying whole disk..."
    PARTITION="$NEW_DEVICE"
fi

# Create temporary mount point
MOUNT_POINT="/tmp/moltos-usb-scan"
sudo mkdir -p "$MOUNT_POINT"

echo -e "${BLUE}[▸]${NC} Mounting ${BOLD}/dev/$PARTITION${NC} to ${BOLD}$MOUNT_POINT${NC}..."
sudo mount "/dev/$PARTITION" "$MOUNT_POINT" 2>/dev/null || {
    echo -e "${ORANGE}[!]${NC} Mount failed. Trying with file system detection..."
    sudo mount -t auto "/dev/$PARTITION" "$MOUNT_POINT"
}

echo -e "${GREEN}[✓]${NC} USB mounted successfully"

# Search for ISO files
echo -e "${BLUE}[▸]${NC} Hunting for ISO files..."
ISO_FILES=$(find "$MOUNT_POINT" -type f -name "*.iso" 2>/dev/null)

if [ -z "$ISO_FILES" ]; then
    echo -e "${ORANGE}[!]${NC} No ISO files found on this USB"
    sudo umount "$MOUNT_POINT"
    exit 1
fi

echo -e "${GREEN}[✓]${NC} Found ISO file(s):"
echo "$ISO_FILES" | while read iso; do
    SIZE=$(du -h "$iso" | cut -f1)
    FILENAME=$(basename "$iso")
    echo -e "  ${BLUE}→${NC} ${BOLD}$FILENAME${NC} (${SIZE})"
    echo -e "     ${BLUE}Path:${NC} $iso"
done

# Check for Kali ISO specifically
KALI_ISO=$(echo "$ISO_FILES" | grep -i "kali" | head -1)

if [ -n "$KALI_ISO" ]; then
    echo -e ""
    echo -e "${GREEN}[✓]${NC} ${BOLD}Kali Linux ISO detected!${NC}"
    echo -e "${BLUE}[▸]${NC} Path: ${BOLD}$KALI_ISO${NC}"
    echo -e ""
    echo -e "${ORANGE}[!]${NC} Ready to create MoltOS Kali VM?"
    echo -e "${BLUE}[▸]${NC} Run: ${BOLD}./moltos-vm-controller create kali --name MoltOS-Kali --iso \"$KALI_ISO\"${NC}"
fi

echo -e ""
echo -e "${BLUE}[▸]${NC} USB will remain mounted at: ${BOLD}$MOUNT_POINT${NC}"
echo -e "${BLUE}[▸]${NC} To unmount: ${BOLD}sudo umount $MOUNT_POINT${NC}"
