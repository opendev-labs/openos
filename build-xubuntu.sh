#!/bin/bash
# MoltOS Xubuntu Build Script
# Version: 2.0 - Xubuntu Edition with AI Terminal

set -e

WORKSPACE="/mnt/moltos-build/xubuntu-build"
PROJECT_DIR="/home/cube/syncstack/opendev-labs/openos"
LOG_FILE="$WORKSPACE/build.log"

# Colors for output
ORANGE='\033[38;5;208m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${ORANGE}${BOLD}"
echo "===================================================="
echo "  MOLTOS XUBUNTU BUILD - AI TERMINAL EDITION"
echo "===================================================="
echo -e "${NC}"

# 1. Navigate to workspace
cd "$WORKSPACE"

# 2. Copy secrets file to /tmp for hook access
if [ -f "$PROJECT_DIR/moltos.secrets" ]; then
    echo "✓ Copying secrets file..."
    sudo cp "$PROJECT_DIR/moltos.secrets" /tmp/moltos.secrets
else
    echo "⚠️  WARNING: moltos.secrets not found, using defaults"
fi

# 3. Clean previous build artifacts (optional)
echo "Cleaning previous build artifacts..."
sudo lb clean --purge || true

# 4. Rebuild configuration (in case of changes)
echo "Regenerating configuration..."
sudo lb config \
    --mode ubuntu \
    --distribution jammy \
    --architectures amd64 \
    --linux-flavours generic \
    --archive-areas "main restricted universe multiverse" \
    --parent-archive-areas "main restricted universe multiverse" \
    --mirror-bootstrap "http://archive.ubuntu.com/ubuntu/" \
    --parent-mirror-bootstrap "http://archive.ubuntu.com/ubuntu/" \
    --mirror-binary "http://archive.ubuntu.com/ubuntu/" \
    --parent-mirror-binary "http://archive.ubuntu.com/ubuntu/" \
    --mirror-chroot-security "http://security.ubuntu.org/ubuntu/" \
    --parent-mirror-chroot-security "http://security.ubuntu.org/ubuntu/" \
    --mirror-binary-security "http://security.ubuntu.org/ubuntu/" \
    --parent-mirror-binary-security "http://security.ubuntu.org/ubuntu/" \
    --iso-volume "MOLT OS Xubuntu" \
    --debian-installer none \
    --binary-images iso-hybrid \
    --bootappend-live "boot=live components quiet splash" \
    --memtest none

# 5. Inject custom AgentOS configuration hooks
echo "Injecting custom MoltOS AgentOS hooks and themes..."
sudo cp -rv "$PROJECT_DIR/xubuntu-config/"* "$WORKSPACE/config/"

# 6. Start the build
echo -e "${ORANGE}${BOLD}Starting ISO build... This will take a while.${NC}"
echo "Build log: $LOG_FILE"

sudo lb build --verbose 2>&1 | tee "$LOG_FILE"

# 6. Check build result
ISO_FILE=$(find "$WORKSPACE" -name "*.iso" -o -name "*.hybrid.iso" | head -n 1)

if [ -z "$ISO_FILE" ]; then
    echo -e "${ORANGE}${BOLD}❌ BUILD FAILED${NC}"
    echo "Check $LOG_FILE for details"
    exit 1
fi

# 7. Success!
echo -e "${ORANGE}${BOLD}"
echo "===================================================="
echo "  ✓ BUILD SUCCESSFUL"
echo "===================================================="
echo -e "${NC}"
echo "ISO Location: $ISO_FILE"
echo "ISO Size: $(du -h "$ISO_FILE" | cut -f1)"
echo ""
echo "Next steps:"
echo "  1. Test in QEMU: cd $PROJECT_DIR && ./hyper_vcore.sh"
echo "  2. Write to USB: sudo dd if=$ISO_FILE of=/dev/sdX bs=4M status=progress"
echo ""
