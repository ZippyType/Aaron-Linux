#!/bin/bash
# Aaron Linux - Step 6: Build Linux Kernel

set -e

LFS="/mnt/lfs"
SOURCES="$LFS/sources"
LOG_DIR="/workspaces/Aaron-Linux/logs"

log() { echo -e "\033[1;31m[$(date)]\033[0m $1" | tee -a "$LOG_DIR/06-kernel.log"; }

log "Building kernel..."

chroot "$LFS" /tools/bin/env -i \
    HOME=/root TERM=xterm PS1='(chroot) \u@\h:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login << 'KERNEL'

cd /sources

# Extract and build kernel
tar -xf linux-6.12.7.tar.xz
cd linux-6.12.7

# Basic config for x86_64
make defconfig

# Enable systemd and required options
sed -i 's/CONFIG_DEFAULT_HOSTNAME="localhost"/CONFIG_DEFAULT_HOSTNAME="aaronlinux"/' .config
sed -i 's/CONFIG_MODULES=y/CONFIG_MODULES=y/' .config

# Build kernel
make -j$(nproc) bzImage
make -j$(nproc) modules

# Install
make INSTALL_MOD_PATH=/usr modules_install

# Copy kernel
cp -v arch/x86/boot/bzImage /boot/vmlinuz-6.12.7-aaron
cp -v System.map /boot/System.map-6.12.7-aaron
cp -v .config /boot/config-6.12.7-aaron

# Create initramfs (simple)
mkdir -p /boot/initrd
cd /boot/initrd
mkdir -p bin dev lib proc sys run
cp /sbin/busybox init
ln -s init bin/sh
ln -s init bin/init

# Create init script
cat > init << 'INIT'
#!/bin/sh
echo "Aaron Linux initramfs"
echo "Mounting root..."
mount -t proc /proc /proc
mount -t sysfs /sys /sys
mount -t devtmpfs /dev /dev
echo "Starting init..."
exec /sbin/init
INIT
chmod +x init

# Create cpio archive
find . | cpio -o -H newc | xz -9 > /boot/initrd.img

cd /sources && rm -rf linux-6.12.7*

log "Kernel build complete!"
KERNEL