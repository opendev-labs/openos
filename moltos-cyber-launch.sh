#!/bin/bash
# MoltOS Super-Sonic Cyber-Launcher
# Bypasses 2-hour ISO build for immediate reality manipulation.

KERNEL="/tmp/moltos-kernel"
INITRD="/tmp/moltos-tiny/initrd.img"

# Ensure kernel is accessible
if [ ! -f "$KERNEL" ]; then
    echo "--- INITIALIZING MOLTOS CORE ---"
    ORIG_KERNEL=$(ls /boot/vmlinuz-* | head -n 1)
    sudo cp "$ORIG_KERNEL" "$KERNEL"
    sudo chmod 644 "$KERNEL"
fi

# Execute QEMU as a 'Mini PC'
qemu-system-x86_64 -m 1024 -kernel "$KERNEL" -initrd "$INITRD" -append "console=ttyS0 quiet" -nographic

