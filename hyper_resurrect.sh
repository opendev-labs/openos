#!/bin/bash
# MoltOS Hyper-Resurrect: Emergency Build Recovery & Resumption
# Version: 1.1.0 (Phantom-Fix Edition)
# Bypasses broken dependencies by injecting a dummy package.

set -e

# --- Configuration ---
WORKSPACE="/mnt/moltos-build/live-build-config"
PROJECT_DIR="/home/cube/syncstack/opendev-labs/openos"
SECRETS_FILE="$PROJECT_DIR/moltos.secrets"

# --- Aesthetics ---
ORANGE='\033[38;5;208m'
BOLD='\033[1m'
NC='\033[0m'

update_status() {
    echo -e "${ORANGE}${BOLD}[SURGERY] + ${NC}$1"
}

echo -e "${ORANGE}${BOLD}====================================================${NC}"
echo -e "${ORANGE}${BOLD}   MOLT OS HYPER-RESURRECT : PHANTOM PROTOCOL      ${NC}"
echo -e "${ORANGE}${BOLD}====================================================${NC}"

# 1. Validation
update_status "Validating environment..."
if [ ! -f "$SECRETS_FILE" ]; then
    echo "ERROR: moltos.secrets missing."
    exit 1
fi

# 2. Phantom Injection
update_status "Deploying Phantom Package (satisfying firmware-nexmon ghost)..."
sudo bash -c 'cat <<EOF > /tmp/phantom_control
Package: firmware-nexmon
Version: 9.9.9
Section: misc
Priority: optional
Architecture: all
Maintainer: MoltOS Surgery <surgery@moltos.org>
Description: Phantom package to satisfy broken dependencies.
EOF'

mkdir -p /tmp/phantom-pkg/DEBIAN
sudo cp /tmp/phantom_control /tmp/phantom-pkg/DEBIAN/control
mkdir -p /mnt/moltos-build/live-build-config/config/packages.chroot
sudo dpkg-deb --build /tmp/phantom-pkg /mnt/moltos-build/live-build-config/config/packages.chroot/firmware-nexmon_9.9.9_all.deb

# 3. APT Cleanup (Remove previous failed pin)
update_status "Scrubbing previous APT patches..."
sudo rm -f "$WORKSPACE/config/chroot_apt/preferences"
sudo rm -f "$WORKSPACE/chroot/etc/apt/preferences.d/moltos-fix" || true

# 4. Resume Build
update_status "Re-igniting Synthesis Engine (INCREMENTAL MODE)..."
echo -e "${ORANGE}${BOLD}--- PHANTOM CORE ACTIVE : RESUMING SYNTHESIS ---${NC}"
cd "$WORKSPACE"

# We skip 'lb clean' and 'lb config' to keep the current state.
sudo lb build --verbose --debug

# 5. Success Check
ISO_FILE=$(find "$WORKSPACE" -name "*.iso" | head -n 1)
if [ -z "$ISO_FILE" ]; then
    update_status "RESURRECTION FAILED. Check logs."
    exit 1
fi

echo -e "${ORANGE}${BOLD}====================================================${NC}"
echo -e "${ORANGE}${BOLD}      UPLINK ESTABLISHED. RESURRECTION SUCCESS     ${NC}"
echo -e "${ORANGE}${BOLD}====================================================${NC}"
