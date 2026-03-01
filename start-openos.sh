#!/bin/bash
# MoltOS USB-NEXT: OpenOS Runner (Linux/macOS)
# Placed on the USB drive to launch the VMAGENT

set -e

# Detect the directory where this script is located (the root of the USB drive)
USB_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
IMAGE_PATH="$USB_DIR/openos-vmagent.qcow2"

echo "===================================================="
echo "          MOLTOS VMAGENT: STARTING OPENOS           "
echo "===================================================="

# Check if QEMU is installed
if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo "❌ Error: QEMU is not installed or not in PATH."
    echo ""
    echo "To run OpenOS, please install QEMU:"
    echo "  Ubuntu/Debian: sudo apt-get install qemu-system-x86"
    echo "  macOS:         brew install qemu"
    echo "  Fedora:        sudo dnf install qemu-system-x86"
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Error: OpenOS VM image not found at $IMAGE_PATH"
    exit 1
fi

# Detect OS and available hardware acceleration
ACCEL=""
MEM_SIZE="4096" # Default 4GB RAM
CPU_CORES="2"    # Default 2 cores

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux (KVM)
    if [ -w /dev/kvm ]; then
        ACCEL="-enable-kvm"
        echo "✓ Hardware acceleration enabled (KVM)"
    else
        echo "⚠️ KVM not available. VM will run significantly slower."
        echo "  Consider adding your user to the kvm group: sudo usermod -aG kvm $USER"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (HVF)
    ACCEL="-accel hvf"
    echo "✓ Hardware acceleration enabled (Apple Hypervisor)"
else
    echo "ℹ️ Unknown OS type, running without hardware acceleration."
fi

echo ""
echo "Booting OpenOS VM with $MEM_SIZE MB RAM, $CPU_CORES Cores..."
echo "Do not close this terminal window until you shut down the VM."
echo "===================================================="

# Launch the VM
qemu-system-x86_64 \
    $ACCEL \
    -m $MEM_SIZE \
    -smp $CPU_CORES \
    -drive file="$IMAGE_PATH",format=qcow2,if=virtio \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::8080-:8080,hostfwd=tcp::11434-:11434 \
    -vga virtio \
    -display sdl,gl=on \
    -audiodev pa,id=snd0 -machine pc \
    "$@"
