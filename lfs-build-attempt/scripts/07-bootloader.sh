#!/bin/bash
# Aaron Linux - Step 7: Install GRUB2

set -e

LFS="/mnt/lfs"
LOG_DIR="/workspaces/Aaron-Linux/logs"

log() { echo -e "\033[1;32m[$(date)]\033[0m $1" | tee -a "$LOG_DIR/07-bootloader.log"; }

log "Installing GRUB2..."

chroot "$LFS" /tools/bin/env -i \
    HOME=/root TERM=xterm PS1='(chroot) \u@\h:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login << 'GRUB'

cd /sources

# Extract and build GRUB
tar -xf grub-2.12.tar.xz
cd grub-2.12

# Configure for EFI + BIOS
./configure --prefix=/usr \
    --sysconfdir=/etc \
    --disable-efiemu \
    --disable-werror
make -j$(nproc)
make install

# Setup GRUB
mkdir -p /boot/grub
grub-mkimage -o /boot/grub/i386-pc/core.img biosdisk part_gpt ext2 normal boot linux search search_fs_uuid

# Create GRUB config
cat > /boot/grub/grub.cfg << 'EOF'
set default=0
set timeout=5

menuentry "Aaron Linux 1.0.0" {
    linux /boot/vmlinuz-6.12.7-aaron root=/dev/sda1 ro
    initrd /boot/initrd.img
}

menuentry "Aaron Linux (recovery)" {
    linux /boot/vmlinuz-6.12.7-aaron root=/dev/sda1 ro single
    initrd /boot/initrd.img
}
EOF

# Install GRUB to MBR (if /dev/sda exists)
if [ -b /dev/sda ]; then
    grub-install --boot-directory=/boot /dev/sda 2>/dev/null || true
fi

cd /sources && rm -rf grub-2.12*

log "GRUB installed!"
GRUB