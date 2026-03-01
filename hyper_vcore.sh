#!/bin/bash
# MoltOS Hyper-VCore: Professional QEMU Runner
# Simulates real PC hardware for OS testing and installation.

set -e

# Configuration
VM_DIR="/home/cube/syncstack/opendev-labs/molt.os/vm"
DISK_IMAGE="$VM_DIR/moltos_disk.qcow2"
DISK_SIZE="20G"
ISO_FILE=$(find /home/cube/syncstack/opendev-labs/molt.os -maxdepth 1 -name "*.iso" -o -name "*.hybrid.iso" 2>/dev/null | head -n 1)
if [ -z "$ISO_FILE" ]; then
    ISO_FILE=$(find /home/cube/kali-custom-build/images -name "*.iso" -o -name "*.hybrid.iso" 2>/dev/null | head -n 1)
fi
if [ -z "$ISO_FILE" ]; then
    ISO_FILE=$(find /home/cube/moltos-workspace/xubuntu-build -name "*.iso" -o -name "*.hybrid.iso" 2>/dev/null | head -n 1)
fi
OVMF_PATH="/usr/share/OVMF/OVMF_CODE_4M.fd"
OVMF_VARS="/usr/share/OVMF/OVMF_VARS_4M.fd"

# 1. Workspace Setup
mkdir -p "$VM_DIR"

# 2. Virtual Disk Initialization
if [ ! -f "$DISK_IMAGE" ]; then
    echo "Initializing virtual hard drive ($DISK_SIZE)..."
    qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
fi

# 3. UEFI Variables Setup (Local copy to allow writes)
if [ ! -f "$VM_DIR/OVMF_VARS.fd" ]; then
    cp "$OVMF_VARS" "$VM_DIR/OVMF_VARS.fd"
fi

# 4. Validation
if [ -z "$ISO_FILE" ]; then
    echo "ERROR: MoltOS ISO not found"
    echo "Please run ./build-xubuntu.sh first to build the ISO."
    exit 1
fi

echo "--- MOLT OS HYPER-VCORE STARTING ---"
echo "Simulating PC Boot from USB..."
echo "UEFI: Enabled"
echo "Disk: $DISK_IMAGE"
echo "USB (ISO): $ISO_FILE"

# 5. Launch QEMU with Pro-Dev Settings
# -enable-kvm: Hardware acceleration
# -cpu host: Passthrough host CPU features
# -smp 4: 4 CPU cores
# -m 4G: 4GB RAM
# -drive if=pflash,format=raw,readonly=on,file=$OVMF_PATH: UEFI Firmware
# -drive if=pflash,format=raw,file=$VM_DIR/OVMF_VARS.fd: UEFI Variables
# -device virtio-vga-gl: 3D acceleration support
# -display gtk,gl=on: UI with GL support
# -device qemu-xhci: USB 3.0 controller
# -drive id=usb-stick,file=$ISO_FILE,format=raw,if=none: The "USB" image
# -device usb-storage,drive=usb-stick,bus=usb-bus.0: Plug in the USB
qemu-system-x86_64 \
    -enable-kvm \
    -cpu host \
    -smp 4 \
    -m 4G \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_PATH" \
    -drive if=pflash,format=raw,file="$VM_DIR/OVMF_VARS.fd" \
    -drive id=disk0,file="$DISK_IMAGE",format=qcow2,if=none \
    -device virtio-blk-pci,drive=disk0,bootindex=2 \
    -drive id=iso0,file="$ISO_FILE",format=raw,if=none \
    -device virtio-blk-pci,drive=iso0,bootindex=1 \
    -net nic,model=virtio -net user \
    -vga virtio \
    -display gtk,gl=on || \
    qemu-system-x86_64 \
    -enable-kvm \
    -m 2G \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_PATH" \
    -drive if=pflash,format=raw,file="$VM_DIR/OVMF_VARS.fd" \
    -drive id=disk1,file="$DISK_IMAGE",format=qcow2,if=none \
    -device virtio-blk-pci,drive=disk1,bootindex=2 \
    -drive id=iso1,file="$ISO_FILE",format=raw,if=none \
    -device virtio-blk-pci,drive=iso1,bootindex=1 \
    -net nic \
    -net user \
    -vga std
