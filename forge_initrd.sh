#!/bin/bash
# MoltOS Initrd Forge - Automated RootFS Packaging
# Generates MoltOS Sovereign Kernel Init Sequence and compresses rootfs.

ROOTFS_DIR="/tmp/moltos-tiny/rootfs"
INITRD_IMG="../initrd.img"

# Spinner animation function
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done
}

# Cleanup function for signals
cleanup() {
    echo -e "\n\033[1;33m[ warn ]\033[0m Interrupted. Cleaning up background tasks..."
    [ -n "$BUILD_PID" ] && kill "$BUILD_PID" 2>/dev/null
    echo -e "\033[1;31m[ exit ]\033[0m Process terminated."
    exit 1
}

# Trap Ctrl+C (SIGINT) and Ctrl+Z (SIGTSTP)
trap cleanup INT TSTP

echo -e "\033[1;34m[ info ]\033[0m Initializing MoltOS Initrd Forge..."

# Step 1: Ensure directory exists
if [ ! -d "$ROOTFS_DIR" ]; then
    echo -e "\033[1;31m[ error ]\033[0m Rootfs directory not found at $ROOTFS_DIR"
    exit 1
fi

# Step 2: Create the init script in rootfs root
echo -e "\033[1;34m[ info ]\033[0m Generating MoltOS Sovereign Init Sequence..."
cat <<'EOF' > "$ROOTFS_DIR/init"
#!/bin/sh
export PATH=/bin:/usr/bin
/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev
echo -e "\033[1;37m[  OK  ] MoltOS Sovereign Kernel Initialized.\033[0m"
sleep 0.5
chmod +x /bin/desktop.sh
exec /bin/sh /bin/desktop.sh
EOF

chmod +x "$ROOTFS_DIR/init"
echo -e "\033[1;34m[ info ]\033[0m Repairing broken host-relative symlinks in bin/..."
# Fix links that point to the host's /tmp path instead of internal rootfs path
find "$ROOTFS_DIR/bin" -type l | while read -r link; do
    target=$(readlink "$link")
    if [[ "$target" == *"/tmp/moltos-tiny/rootfs/bin/"* ]]; then
        # Repoint to internal /bin path
        new_target="/bin/${target##*/}"
        ln -sf "$new_target" "$link"
    fi
done

echo -e "\033[1;34m[ info ]\033[0m Ensuring binary permissions in rootfs/bin..."
find "$ROOTFS_DIR/bin" -type f,l -exec chmod +x {} + 2>/dev/null

# Step 3: Package the rootfs with animated indicator
echo -n -e "\033[1;34m[ info ]\033[0m Packaging rootfs into initrd.img..."
(cd "$ROOTFS_DIR" && find . -print0 | cpio --null -ov -H newc 2>/dev/null | gzip -9 > "$INITRD_IMG") &
BUILD_PID=$!
spinner $BUILD_PID

echo -e "\r\033[1;32m[  OK  ]\033[0m Packaging rootfs into initrd.img... [ DONE ]"
echo -e "\033[1;34m[ info ]\033[0m Sovereign Image located at: \033[1;37m/tmp/moltos-tiny/initrd.img\033[0m"
