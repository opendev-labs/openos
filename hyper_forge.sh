#!/bin/bash
# MoltOS Hyper-Forge: Intelligent Build & Test Automator
# Version: 1.8.0 (X-Ray Surgery Edition)
# X-Ray Visibility (set -x) + Floating Orange Status Line + Raw Stream

# Enable "X-Ray" shell tracing for maximum process visibility
set -x
set -e

# --- Configuration ---
WORKSPACE="/mnt/moltos-build/live-build-config"
PROJECT_DIR="/home/cube/syncstack/opendev-labs/molt.os"
SECRETS_FILE="$PROJECT_DIR/moltos.secrets"
LOG_FILE="$WORKSPACE/hyper_forge.log"
STATUS_FILE="/tmp/moltos_synthesis_status"

# --- Aesthetics (Orange Theme) ---
ORANGE='\033[38;5;208m'
BOLD='\033[1m'
NC='\033[0m'

# Ensure status file is fresh
echo "Initializing..." > "$STATUS_FILE"

# --- Floating Status Monitor (Background) ---
status_monitor() {
    # Turn off shell tracing for the monitor loop to avoid clogging the stream
    set +x
    local spin_chars='/-\|'
    local spin_idx=0
    
    while true; do
        local lines=$(tput lines)
        local msg=$(cat "$STATUS_FILE" 2>/dev/null || echo "Synthesizing...")
        local char="${spin_chars:spin_idx:1}"
        spin_idx=$(( (spin_idx + 1) % 4 ))
        
        # Draw anchored status line at bottom
        printf "\033[s\033[%d;0H\033[K${ORANGE}${BOLD}[$char] MOLT-OS SURGERY:${NC} %s\b\033[u" "$lines" "$msg"
        
        sleep 0.1
    done
}

update_status() {
    echo "$1" > "$STATUS_FILE"
}

# --- Cleanup on Exit ---
cleanup() {
    set +x
    kill "$MONITOR_PID" 2>/dev/null || true
    rm -f "$STATUS_FILE"
    tput cnorm || true
    echo -e "\n${ORANGE}${BOLD}--- SURGERY TERMINATED ---${NC}"
}
trap cleanup EXIT

# Hide cursor for professional look
tput civis || true

echo -e "${ORANGE}${BOLD}"
echo "===================================================="
echo "--- MOLT OS HYPER-FORGE: X-RAY SURGERY ---"
echo "--- FULL X-RAY TERMINAL STREAM ENGAGED ---"
echo "===================================================="
echo -e "${NC}"

# Start the floating status monitor
# We run it in a way that its own trace output is suppressed
(status_monitor) &
MONITOR_PID=$!

# 1. Validation
update_status "Validating System Integrity..."
[ -f "$SECRETS_FILE" ]

# 2. Dependency Check
update_status "Probing Hypervisor Capability..."
command -v qemu-system-x86_64 || (sudo apt update && sudo apt install -y qemu-system-x86 qemu-utils)

# 3. Cleanup & Recovery Optimization
update_status "Scrubbing Stale Nodes (Fast-Recovery Mode)..."
sudo umount -lv "$WORKSPACE/chroot/proc" 2>/dev/null || true
sudo umount -lv "$WORKSPACE/chroot/sys" 2>/dev/null || true
sudo umount -lv "$WORKSPACE/chroot/dev/pts" 2>/dev/null || true
sudo umount -lv "$WORKSPACE/chroot/dev" 2>/dev/null || true

cd "$WORKSPACE"
update_status "Cleansing Workspace Bloat..."
sudo lb clean --verbose

update_status "Re-initializing Synthesis Directory..."
sudo mkdir -pv "$WORKSPACE"
sudo chown -v cube:cube "$WORKSPACE" || true

# 4. Emergency Repairs
update_status "Injecting Emergency Repair (firmware-nexmon fix)..."
mkdir -pv "$WORKSPACE/config/package-lists"
echo "firmware-nexmon" > "$WORKSPACE/config/package-lists/exclude-broken.list.chroot.remove"

# 5. Themes & Icons
update_status "Transplanting Host Aesthetics (Themes & Icons)..."
mkdir -pv "$WORKSPACE/kali-config/common/includes.chroot/usr/share/themes"
mkdir -pv "$WORKSPACE/kali-config/common/includes.chroot/usr/share/icons"

LOCAL_THEME="/usr/share/themes/Adwaita"
LOCAL_ICONS_USER="/home/cube/.icons/Tela-red"

[ -d "$LOCAL_THEME" ] && cp -rv "$LOCAL_THEME" "$WORKSPACE/kali-config/common/includes.chroot/usr/share/themes/"
[ -d "$LOCAL_ICONS_USER" ] && cp -rv "$LOCAL_ICONS_USER" "$WORKSPACE/kali-config/common/includes.chroot/usr/share/icons/"

# 6. Execute Build
update_status "Commencing Deep OS Synthesis..."
echo -e "${ORANGE}${BOLD}====================================================${NC}"
echo -e "${ORANGE}${BOLD}      X-RAY CORE ACTIVE : ANALYZE EVERY OPS         ${NC}"
echo -e "${ORANGE}${BOLD}====================================================${NC}"

cd "$WORKSPACE"
update_status "Binding Configuration Nodes..."
sudo lb config --iso-volume "MOLT OS" --verbose --debug

update_status "Synthesizing OS Image (Full X-Ray Visibility)..."
sudo lb build --verbose --debug 2>&1 | tee "$LOG_FILE"

# 7. Post-Build
update_status "Indexing Synthesized Artifacts..."
ISO_FILE=$(find "$WORKSPACE" -name "*.iso" | head -n 1)

if [ -z "$ISO_FILE" ]; then
    update_status "SYNTHESIS FAILED"
    exit 1
fi

update_status "SYNTHESIS SUCCESSFUL. PREPARING UPLINK..."
qemu-system-x86_64 \
    -enable-kvm -m 4G -smp 4 \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
    -cdrom "$ISO_FILE" -boot d
