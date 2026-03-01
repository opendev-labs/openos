#!/bin/bash
# MoltOS ISO Creator - Convert kernel+initrd to bootable ISO
# Creates a bootable ISO image for VirtualBox/physical boot

set -e

KERNEL="/tmp/moltos-kernel"
INITRD="/tmp/moltos-tiny/initrd.img"
ISO_DIR="/tmp/moltos-iso"
ISO_OUTPUT="/tmp/moltos-boot.iso"

ORANGE='\033[38;5;208m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}[▸]${NC} Creating MoltOS bootable ISO..."

# Check prerequisites
if [ ! -f "$KERNEL" ] || [ ! -f "$INITRD" ]; then
    echo -e "${ORANGE}[!]${NC} Error: Kernel or initrd not found"
    echo -e "${BLUE}[▸]${NC} Run ./forge_initrd.sh first"
    exit 1
fi

# Install required tools
if ! command -v xorriso &> /dev/null; then
    echo -e "${BLUE}[▸]${NC} Installing ISO creation tools..."
    sudo apt install -y xorriso isolinux syslinux-common
fi

# Prepare ISO directory structure
echo -e "${BLUE}[▸]${NC} Preparing ISO structure..."
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR"/{boot/isolinux,live}

# Copy kernel and initrd
echo -e "${BLUE}[▸]${NC} Copying kernel and initrd..."
cp "$KERNEL" "$ISO_DIR/live/vmlinuz"
cp "$INITRD" "$ISO_DIR/live/initrd.img"

# Copy isolinux bootloader
cp /usr/lib/ISOLINUX/isolinux.bin "$ISO_DIR/boot/isolinux/"
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 "$ISO_DIR/boot/isolinux/"
cp /usr/lib/syslinux/modules/bios/libcom32.c32 "$ISO_DIR/boot/isolinux/"
cp /usr/lib/syslinux/modules/bios/libutil.c32 "$ISO_DIR/boot/isolinux/"
cp /usr/lib/syslinux/modules/bios/menu.c32 "$ISO_DIR/boot/isolinux/"

# Create isolinux configuration
cat > "$ISO_DIR/boot/isolinux/isolinux.cfg" << 'EOF'
DEFAULT moltos
PROMPT 0
TIMEOUT 50

LABEL moltos
    MENU LABEL MoltOS Sovereign Boot
    KERNEL /live/vmlinuz
    APPEND initrd=/live/initrd.img boot=live quiet splash
EOF

# Create ISO
echo -e "${BLUE}[▸]${NC} Building ISO image..."
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "MOLTOS" \
    -eltorito-boot boot/isolinux/isolinux.bin \
    -eltorito-catalog boot/isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -output "$ISO_OUTPUT" \
    "$ISO_DIR" 2>&1 | grep -v "xorriso : WARNING"

echo -e "${GREEN}[✓]${NC} Bootable ISO created: ${BLUE}$ISO_OUTPUT${NC}"
echo -e "${BLUE}[▸]${NC} Size: $(du -h "$ISO_OUTPUT" | cut -f1)"
