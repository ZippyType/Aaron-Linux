#!/bin/bash
# Aaron Linux - Simple Build Script
# Uses host packages to create a custom Linux system

set -e

AARON_ROOT="/workspaces/Aaron-Linux"
WORK="/tmp/aaron-build"
ISO_DIR="$WORK/iso"
ROOTFS="$WORK/rootfs"

log() { echo -e "\033[1;34m[$(date)]\033[0m $1"; }

setup() {
    log "Setting up build environment..."
    mkdir -p "$ROOTFS" "$ISO_DIR/boot"
    
    # Create base directory structure
    for dir in bin etc var run usr/{bin,sbin,lib,share} home root boot dev proc sys tmp; do
        mkdir -p "$ROOTFS/$dir"
    done
    
    # Create symlinks
    ln -sf usr/bin "$ROOTFS/bin"
    ln -sf usr/sbin "$ROOTFS/sbin"
    ln -sf usr/lib "$ROOTFS/lib"
    ln -sf lib "$ROOTFS/lib64"
    ln -sf ../run "$ROOTFS/var/run"
    ln -sf ../run/lock "$ROOTFS/var/lock"
}

install_base() {
    log "Installing base system from host..."
    
    # Copy essential files from host
    cp -a /bin/* "$ROOTFS/bin/" 2>/dev/null || true
    cp -a /usr/bin/* "$ROOTFS/usr/bin/" 2>/dev/null || true
    cp -a /sbin/* "$ROOTFS/sbin/" 2>/dev/null || true
    cp -a /usr/sbin/* "$ROOTFS/usr/sbin/" 2>/dev/null || true
    
    # Copy libraries
    cp -a /lib/* "$ROOTFS/lib/" 2>/dev/null || true
    cp -a /usr/lib/* "$ROOTFS/usr/lib/" 2>/dev/null || true
    
    log "Base system installed"
}

configure_system() {
    log "Configuring system..."
    
    # Ensure directories exist (they may have been overwritten by install_base)
    for dir in etc var run usr home root boot dev proc sys tmp; do
        mkdir -p "$ROOTFS/$dir"
    done
    
    # Create passwd
    cat > "$ROOTFS/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/bin/false
bin:x:2:2:bin:/bin:/bin/false
sys:x:3:3:sys:/dev:/bin/false
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/bin/false
man:x:6:12:man:/var/cache/man:/bin/false
lp:x:7:7:lp:/var/spool/lpd:/bin/false
mail:x:8:8:mail:/var/mail:/bin/false
news:x:9:9:news:/var/spool/news:/bin/false
uucp:x:10:10:uucp:/var/spool/uucp:/bin/false
proxy:x:13:13:proxy:/bin:/bin/false
www-data:x:33:33:www-data:/var/www:/bin/false
backup:x:34:34:backup:/var/backups:/bin/false
list:x:38:38:Mailing List Manager:/var/list:/bin/false
irc:x:39:39:ircd:/run/ircd:/bin/false
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/bin/false
nobody:x:65534:65534:nobody:/nonexistent:/bin/false
_apt:x:100:65534::/nonexistent:/bin/false
systemd-network:x:101:102:systemd Network Management,,,:/run/systemd:/bin/false
systemd-resolve:x:102:103:systemd Resolver,,,:/run/systemd:/bin/false
messagebus:x:103:104::/nonexistent:/bin/false
systemd-timesync:x:104:105::/run/systemd:/bin/false
EOF

    # Create group
    cat > "$ROOTFS/etc/group" << 'EOF'
root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:
tty:x:5:
disk:x:6:
lp:x:7:
mail:x:8:
news:x:9:
uucp:x:10:
man:x:12:
proxy:x:13:
kmem:x:15:
dialout:x:20:
fax:x:21:
voice:x:22:
cdrom:x:24:
floppy:x:25:
tape:x:26:
sudo:x:27:
audio:x:29:
dip:x:30:
www-data:x:33:
backup:x:34:
operator:x:37:
list:x:38:
irc:x:39:
src:x:40:
gnats:x:41:
shadow:x:42:
utmp:x:43:
video:x:44:
sasl:x:45:
plugdev:x:46:
staff:x:50:
games:x:60:
users:x:100:
nogroup:x:65534:
systemd-journal:x:101:
systemd-network:x:102:
systemd-resolve:x:103:
messagebus:x:104:
systemd-timesync:x:105:
EOF

    # Create hostname
    echo "aaronlinux" > "$ROOTFS/etc/hostname"

    # Create hosts
    cat > "$ROOTFS/etc/hosts" << 'EOF'
127.0.0.1 localhost
127.0.1.1 aaronlinux
::1 localhost ip6-localhost ip6-loopback
EOF

    # Create fstab
    cat > "$ROOTFS/etc/fstab" << 'EOF'
# /etc/fstab
/dev/sda1 / ext4 defaults 0 1
tmpfs /tmp tmpfs defaults 0 0
EOF

    # Create os-release
    cat > "$ROOTFS/etc/os-release" << 'EOF'
NAME="Aaron Linux"
VERSION="1.0.0"
ID=aaronlinux
ID_LIKE=debian
PRETTY_NAME="Aaron Linux 1.0.0"
VERSION_ID="1.0.0"
HOME_URL="https://github.com/ZippyType/Aaron-Linux"
BUG_REPORT_URL="https://github.com/ZippyType/Aaron-Linux/issues"
EOF

    # Create network interfaces
    cat > "$ROOTFS/etc/network/interfaces" << 'EOF'
# interfaces(5) file
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

    # Create resolv.conf
    echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"
    echo "nameserver 8.8.4.4" >> "$ROOTFS/etc/resolv.conf"

    # Create shell profile
    cat > "$ROOTFS/etc/profile" << 'EOF'
export PATH=/bin:/usr/bin:/sbin:/usr/sbin
export PAGER=less
export EDITOR=vi
PS1='\u@aaronlinux:\w\$ '
EOF

    # Create bashrc
    cat > "$ROOTFS/etc/bash.bashrc" << 'EOF'
alias ll='ls -la'
alias la='ls -A'
export CLICOLOR=1
export LS_OPTIONS='--color=auto'
EOF

    log "System configured"
}

install_package_managers() {
    log "Installing package managers..."
    
    # Create directories
    mkdir -p "$ROOTFS/var/lib/alpkg"
    mkdir -p "$ROOTFS/var/packages"
    mkdir -p "$ROOTFS/var/cache/alpkg"
    mkdir -p "$ROOTFS/var/cache/apt"
    mkdir -p "$ROOTFS/var/lib/dpkg"
    mkdir -p "$ROOTFS/var/cache/dpkg"
    mkdir -p "$ROOTFS/etc/alpkg"
    mkdir -p "$ROOTFS/etc/apt"
    
    # Copy DPKG from host
    if [ -f /usr/bin/dpkg ]; then
        cp /usr/bin/dpkg "$ROOTFS/usr/bin/"
        cp /usr/bin/dpkg-deb "$ROOTFS/usr/bin/"
    fi
    
    # Copy APT from host
    for bin in apt apt-get apt-cache apt-mark dpkg; do
        [ -f "/usr/bin/$bin" ] && cp "/usr/bin/$bin" "$ROOTFS/usr/bin/"
    done
    
    # Copy dpkg database
    if [ -d /var/lib/dpkg ]; then
        cp -a /var/lib/dpkg/* "$ROOTFS/var/lib/dpkg/"
    fi
    
    # Copy apt cache (optional)
    if [ -d /var/cache/apt ]; then
        cp -a /var/cache/apt/* "$ROOTFS/var/cache/apt/" 2>/dev/null || true
    fi
    
    # Create APT sources
    cat > "$ROOTFS/etc/apt/sources.list" << 'EOF'
# Aaron Linux - APT sources
deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-security main restricted universe multiverse
EOF

    # Create alpkg script
    cat > "$ROOTFS/usr/bin/alpkg" << 'ALPKG'
#!/bin/bash
# alpkg - Aaron Linux Package Manager

DB="/var/lib/alpkg"
PKG_DIR="/var/packages"

help() {
    echo "alpkg - Aaron Linux Package Manager"
    echo "Usage: alpkg <command> [options]"
    echo ""
    echo "Commands:"
    echo "  install <file.alp>  Install .alp package"
    echo "  remove <name>       Remove package"
    echo "  list                List installed"
    echo "  search <query>      Search packages"
    echo "  update              Update package lists"
    echo ""
    echo "Note: This uses APT underneath for .deb files"
}

if [ $# -lt 1 ]; then
    help
    exit 1
fi

case "$1" in
    install)
        if [ -f "$2" ]; then
            name=$(basename "$2" .alp)
            echo "Installing $name..."
            cd /tmp
            tar -xf "$2"
            if [ -f install.sh ]; then
                chmod +x install.sh && ./install.sh
            fi
            if [ -f data.tar.xz ]; then
                tar -xf data.tar.xz -C /
            fi
            echo "$name" >> "$DB/db"
            echo "Installed: $name"
        else
            echo "File not found: $2"
        fi
        ;;
    remove)
        apt-get remove "$2" 2>/dev/null || echo "Removing $2..."
        ;;
    list)
        dpkg -l | grep ^ii
        ;;
    search)
        apt-cache search "$2"
        ;;
    update)
        apt-get update
        ;;
    *)
        help
        ;;
esac
ALPKG

    chmod +x "$ROOTFS/usr/bin/alpkg"
    
    # Create alpkg config
    cat > "$ROOTFS/etc/alpkg/alpkg.conf" << 'EOF'
# alpkg configuration
PKG_DIR=/var/packages
DB_DIR=/var/lib/alpkg
CACHE_DIR=/var/cache/alpkg
EOF

    log "Package managers installed"
}

create_initrd() {
    log "Creating initramfs..."
    
    INITRD="$ISO_DIR/boot/initrd.img"
    INITRD_DIR="$WORK/initrd"
    
    mkdir -p "$INITRD_DIR"/{bin,etc,lib,proc,sys,sbin,usr/{bin,sbin}}
    
    # Copy busybox
    if [ -f /bin/busybox ]; then
        cp /bin/busybox "$INITRD_DIR/bin/"
    else
        cp /usr/bin/busybox "$INITRD_DIR/bin/" 2>/dev/null || true
    fi
    
    # Create symlinks
    for cmd in sh mount umount sleep cat echo ls mkdir mdev sleep; do
        ln -sf busybox "$INITRD_DIR/bin/$cmd" 2>/dev/null || true
    done
    ln -sf /bin/busybox "$INITRD_DIR/sbin/init" 2>/dev/null || true
    
    # Create init script
    cat > "$INITRD_DIR/init" << 'INIT'
#!/bin/sh
echo "Aaron Linux initramfs"
mount -t proc /proc /proc
mount -t sysfs /sys /sys
mount -t devtmpfs /dev /dev
echo "Booting..."
exec /sbin/init
INIT
    chmod +x "$INITRD_DIR/init"
    
    # Create cpio archive
    cd "$INITRD_DIR"
    find . | cpio -o -H newc 2>/dev/null | gzip -9 > "$INITRD"
    
    log "Initramfs created"
}

create_kernel() {
    log "Setting up kernel..."
    
    # Try to copy host kernel
    KERNEL=$(ls /boot/vmlinuz-* 2>/dev/null | head -1)
    if [ -n "$KERNEL" ]; then
        cp "$KERNEL" "$ISO_DIR/boot/vmlinuz"
        cp /boot/initrd.img* "$ISO_DIR/boot/initrd.img" 2>/dev/null || true
        log "Kernel copied: $KERNEL"
    else
        log "Warning: No kernel found, using host kernel modules"
        # Create a minimal vmlinuz placeholder
        echo "Kernel will be loaded from host"
    fi
}

create_grub() {
    log "Setting up GRUB..."
    
    mkdir -p "$ISO_DIR/boot/grub/x86_64-efi"
    mkdir -p "$ISO_DIR/EFI/boot"
    
    # Create GRUB config
    cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
set timeout=10
set default=0

menuentry "Aaron Linux 1.0.0" {
    linux /boot/vmlinuz root=/dev/sda1 ro quiet
    initrd /boot/initrd.img
}

menuentry "Aaron Linux (Recovery)" {
    linux /boot/vmlinuz root=/dev/sda1 ro single
    initrd /boot/initrd.img
}
EOF

    # Create EFI bootloader (if available)
    if [ -f /usr/lib/shim/shimx64.efi.signed ]; then
        cp /usr/lib/shim/shimx64.efi.signed "$ISO_DIR/EFI/boot/bootx64.efi"
    fi
    
    if [ -f /usr/bin/grub-mkimage ]; then
        grub-mkimage -o "$ISO_DIR/EFI/boot/bootx64.efi" -p /boot/grub normal boot linux search search_fs_uuid 2>/dev/null || true
    fi
    
    log "GRUB configured"
}

create_iso() {
    log "Creating ISO..."
    
    OUTPUT="$AARON_ROOT/AaronLinux-1.0.0-x86_64.iso"
    
    # Create squashfs
    if command -v mksquashfs &>/dev/null; then
        mksquashfs "$ROOTFS" "$ISO_DIR/live/filesystem.squashfs" -comp xz
    fi
    
    # Create ISO
    if command -v xorriso &>/dev/null; then
        xorriso -as mkisofs \
            -iso-level 3 \
            -v "Aaron Linux 1.0.0" \
            -o "$OUTPUT" \
            "$ISO_DIR"
    elif command -v genisoimage &>/dev/null; then
        genisoimage -o "$OUTPUT" -v -R -J -V "Aaron Linux" "$ISO_DIR"
    else
        # Fallback: just create a tarball
        OUTPUT="$AON_ROOT/AaronLinux-1.0.0-rootfs.tar.gz"
        tar -czf "$OUTPUT" -C "$ROOTFS" .
    fi
    
    if [ -f "$OUTPUT" ]; then
        log "ISO created: $OUTPUT"
        ls -lh "$OUTPUT"
    else
        log "Warning: ISO creation may have failed"
    fi
}

usage() {
    echo "Aaron Linux Build Script"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  all      - Full build (all steps)"
    echo "  setup    - Setup build environment"
    echo "  base     - Install base system"
    echo "  config   - Configure system"
    echo "  pkgs     - Install package managers"
    echo "  iso      - Create ISO"
    echo "  clean    - Clean build directory"
}

case "$1" in
    all)
        setup
        install_base
        configure_system
        install_package_managers
        create_kernel
        create_initrd
        create_grub
        create_iso
        log "BUILD COMPLETE!"
        ;;
    setup) setup ;;
    base) install_base ;;
    config) configure_system ;;
    pkgs) install_package_managers ;;
    iso) create_iso ;;
    clean) rm -rf "$WORK" ;;
    *) usage ;;
esac