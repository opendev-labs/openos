#!/bin/bash
# MoltOS Hyper-Identity: Definitive Build Restoration & Identity Protocol
# Version: 1.0.0 (Identity-Restore Edition)
# Re-clones Kali identity and injects MoltOS surgical patches.

set -e

# --- Configuration ---
WORKSPACE="/mnt/moltos-build/live-build-config"
PROJECT_DIR="/home/cube/syncstack/opendev-labs/openos"
SECRETS_FILE="$PROJECT_DIR/moltos.secrets"
STATUS_FILE="/tmp/moltos_identity_status"
KALI_GIT="https://gitlab.com/kalilinux/build-scripts/live-build-config.git"

# --- Aesthetics ---
ORANGE='\033[38;5;208m'
BOLD='\033[1m'
NC='\033[0m'

update_status() {
    echo -e "${ORANGE}${BOLD}[IDENTITY] + ${NC}$1"
}

echo -e "${ORANGE}${BOLD}====================================================${NC}"
echo -e "${ORANGE}${BOLD}   MOLT OS HYPER-IDENTITY : RESTORATION PROTOCOL   ${NC}"
echo -e "${ORANGE}${BOLD}====================================================${NC}"

# 1. Workspace Total Reset
update_status "Performing Total Workspace Rescan..."
if [ -d "$WORKSPACE" ]; then
    update_status "Workspace found. Checking for Identity Drift..."
    if [ ! -d "$WORKSPACE/auto" ]; then
        update_status "Identity Drift Detected (auto/ folder missing). Purging for restoration..."
        sudo rm -rf "$WORKSPACE/.build" "$WORKSPACE/config" "$WORKSPACE/auto"
    fi
fi

if [ ! -d "$WORKSPACE/.git" ]; then
    update_status "Surgically Restoring Identity Base..."
    TEMP_CLONE="/tmp/kali-config-base"
    sudo rm -rf "$TEMP_CLONE"
    git clone --depth 1 "$KALI_GIT" "$TEMP_CLONE"
    
    update_status "Merging Kali Identity into Workspace..."
    # Copy essential structures from the clone
    cp -rv "$TEMP_CLONE/auto" "$WORKSPACE/"
    cp -rv "$TEMP_CLONE/kali-config" "$WORKSPACE/"
    # Copy other root files if they exist (e.g. build scripts)
    cp -v "$TEMP_CLONE"/* "$WORKSPACE/" 2>/dev/null || true
    
    # Initialize git if needed to mark identity
    cd "$WORKSPACE"
    git init
    git remote add origin "$KALI_GIT"
    update_status "Identity Merged Successfully."
fi

# 2. Inject MoltOS Signature
update_status "Injecting MoltOS Surgical Signature..."

# Themes & Icons
update_status "Applying Host Aesthetics..."
mkdir -p "$WORKSPACE/kali-config/common/includes.chroot/usr/share/themes"
mkdir -p "$WORKSPACE/kali-config/common/includes.chroot/usr/share/icons"

[ -d "/usr/share/themes/Adwaita" ] && cp -rv "/usr/share/themes/Adwaita" "$WORKSPACE/kali-config/common/includes.chroot/usr/share/themes/"
[ -d "/home/cube/.icons/Tela-red" ] && cp -rv "/home/cube/.icons/Tela-red" "$WORKSPACE/kali-config/common/includes.chroot/usr/share/icons/"

# Branding Hook
update_status "Deploying Branding Hooks..."
mkdir -p "$WORKSPACE/kali-config/common/hooks/live"
cp -v "$PROJECT_DIR/staged_hooks/96-molt-branding.chroot" "$WORKSPACE/kali-config/common/hooks/live/" || true

# 3. Security: GPG Keyring Injection & APT Pinning
update_status "Injecting Security Credentials & Version Pins..."
mkdir -p "$WORKSPACE/config/archives"
sudo cp -v "/usr/share/keyrings/kali-archive-keyring.gpg" "$WORKSPACE/config/archives/kali.key"

# Inject Hardcore Pins to prevent systemd drift
mkdir -p "$WORKSPACE/config/chroot_apt"
cat <<EOF > "$WORKSPACE/config/chroot_apt/preferences"
Package: systemd systemd-sysv libsystemd0 libsystemd-shared udev libudev1 libpam-systemd
Pin: version 259-1
Pin-Priority: 1001
EOF

# Also try to inject into existing chroot for immediate effect
if [ -d "$WORKSPACE/chroot/etc/apt/preferences.d" ]; then
    sudo cp -v "$WORKSPACE/config/chroot_apt/preferences" "$WORKSPACE/chroot/etc/apt/preferences.d/moltos-lock"
fi

if [ -d "$WORKSPACE/chroot/usr/share/keyrings" ]; then
    sudo cp -v "/usr/share/keyrings/kali-archive-keyring.gpg" "$WORKSPACE/chroot/usr/share/keyrings/"
fi

# 4. Phantom Protocol: Professional Local Repository
update_status "Deploying Professional Local Repository (Phantom Package)..."
PHANTOM_DIR="/tmp/phantom-pkg"
LOCAL_REPO="/tmp/moltos-local-repo"
sudo rm -rf "$PHANTOM_DIR" "$LOCAL_REPO"
mkdir -p "$PHANTOM_DIR/DEBIAN"
mkdir -p "$LOCAL_REPO"

cat <<EOF > "$PHANTOM_DIR/DEBIAN/control"
Package: firmware-nexmon
Version: 9.9.9
Section: misc
Priority: optional
Architecture: all
Maintainer: MoltOS Surgery <surgery@moltos.org>
Description: Phantom package to satisfy broken Kali dependencies.
EOF

dpkg-deb --build "$PHANTOM_DIR" "$LOCAL_REPO/firmware-nexmon_9.9.9_all.deb"

# Generate Repository Index
cd "$LOCAL_REPO"
dpkg-scanpackages . /dev/null > Packages
gzip -fk Packages

# Inject into live-build archives
mkdir -p "$WORKSPACE/config/archives"
cat <<EOF > "$WORKSPACE/config/archives/moltos-local.list.chroot"
deb [trusted=yes] file://$LOCAL_REPO ./
EOF

# Stage repo into chroot
mkdir -p "$WORKSPACE/kali-config/common/includes.chroot/root/local-repo"
cp -v "$LOCAL_REPO"/* "$WORKSPACE/kali-config/common/includes.chroot/root/local-repo/"

# 5. Lock Identity to Kali Rolling
update_status "Locking OS Persona: kali-rolling..."
# Kali's live-build-config handles this in auto/config, but we make sure.
cd "$WORKSPACE"
if [ -f "auto/config" ]; then
    sed -i 's/--distribution .*/--distribution kali-rolling \\/' auto/config
fi

# Scrub existing chroot's APT lists to prevent hash mismatch
# (Already handled manually and verified)
# if [ -d "$WORKSPACE/chroot/var/lib/apt/lists" ]; then
#     sudo rm -rf "$WORKSPACE/chroot/var/lib/apt/lists"/*
# fi

# 6. Execute Synthesis
update_status "Re-igniting the Forge (Fast-Track Active)..."
echo -e "${ORANGE}${BOLD}====================================================${NC}"
echo -e "${ORANGE}${BOLD}      IDENTITY RESTORED. COMMENCING SYNTHESIS      ${NC}"
echo -e "${ORANGE}${BOLD}====================================================${NC}"

# We don't lb clean --purge to save time on bootstrap cache
sudo lb build --verbose --debug
