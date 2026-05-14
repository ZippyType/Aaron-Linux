#!/bin/bash
# Aaron Linux - Step 9: Create Live ISO

set -e

AARON_ROOT="/workspaces/Aaron-Linux"
LFS="/mnt/lfs"
LOG_DIR="$AARON_ROOT/logs"
ISO_DIR="/tmp/aaron-iso"
OUTPUT="$AARON_ROOT/AaronLinux-1.0.0-x86_64.iso"

log() { echo -e "\033[1;34m[$(date)]\033[0m $1" | tee -a "$LOG_DIR/09-iso.log"; }

log "Creating live ISO..."

# Prepare ISO directory
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR"/{boot,live,EFI}

# Copy kernel and initrd
cp "$LFS/boot/vmlinuz-6.12.7-aaron" "$ISO_DIR/boot/"
cp "$LFS/boot/initrd.img" "$ISO_DIR/boot/"

# Create squashfs of the root filesystem
log "Creating squashfs..."
mksquashfs "$LFS" "$ISO_DIR/live/filesystem.squashfs" -comp xz -Xbcj x86

# Create GRUB EFI
mkdir -p "$ISO_DIR/boot/grub/x86_64-efi"
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
set default=0
set timeout=10

menuentry "Aaron Linux 1.0.0 (Live)" {
    linux /boot/vmlinuz-6.12.7-aaron boot=live union=overlay
    initrd /boot/initrd.img
}

menuentry "Aaron Linux (Install)" {
    linux /boot/vmlinuz-6.12.7-aaron
    initrd /boot/initrd.img
}
EOF

# Create EFI boot (minimal)
mkdir -p "$ISO_DIR/EFI/boot"
cat > "$ISO_DIR/EFI/boot/startup.nsh" << 'EOF'
@echo -off
\EFI\boot\bootx64.efi
EOF

# Create ISO with xorriso (if available) or genisoimage
if command -v xorriso &>/dev/null; then
    log "Using xorriso..."
    xorriso -as mkisofs \
        -isohybrid-mbr /usr/lib/syslinux/isohdpfx.bin \
        -c boot/bootcat \
        -b boot/grub/i386-pc/cdimg \
        -no-emul-boot \
        -boot-load-size 4 \
        -o "$OUTPUT" \
        "$ISO_DIR"
elif command -v genisoimage &>/dev/null; then
    log "Using genisoimage..."
    genisoimage -o "$OUTPUT" -b boot/grub/i386-pc/cdimg \
        -no-emul-boot -boot-load-size 4 \
        -R -J -V "Aaron Linux" "$ISO_DIR"
else
    log "ERROR: No ISO tools found!"
    log "Install xorriso or genisoimage"
    exit 1
fi

# Compress
xz -z "$OUTPUT" 2>/dev/null || true

log "ISO created: $OUTPUT"
log "Build complete!"
ls -lh "$OUTPUT"