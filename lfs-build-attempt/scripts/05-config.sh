#!/bin/bash
# Aaron Linux - Step 5: System Configuration

set -e

LFS="/mnt/lfs"
LOG_DIR="/workspaces/Aaron-Linux/logs"

log() { echo -e "\033[1;35m[$(date)]\033[0m $1" | tee -a "$LOG_DIR/05-config.log"; }

log "Configuring system..."

chroot "$LFS" /tools/bin/env -i \
    HOME=/root TERM=xterm PS1='(chroot) \u@\h:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login << 'CONFIG'

# Create fstab
cat > /etc/fstab << 'EOF'
# /etc/fstab: static file system information
<file-system> <mount-point> <type> <options> <dump> <fsck>

# Root partition
/dev/sda1 / ext4 defaults 0 1

# Swap (uncomment if needed)
/dev/sda2 none swap sw 0 0

# tmpfs
tmpfs /tmp tmpfs defaults 0 0
EOF

# Create hostname
echo "aaronlinux" > /etc/hostname

# Create hosts
cat > /etc/hosts << 'EOF'
127.0.0.1 localhost
127.0.1.1 aaronlinux.localdomain aaronlinux
::1 localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# Create /etc/os-release
cat > /etc/os-release << 'EOF'
NAME="Aaron Linux"
VERSION="1.0.0"
ID=aaronlinux
ID_LIKE=linux
PRETTY_NAME="Aaron Linux 1.0.0"
VERSION_ID="1.0.0"
HOME_URL="https://github.com/AaronLinux"
BUG_REPORT_URL="https://github.com/AaronLinux/issues"
EOF

# Create /etc/lsb-release (for compatibility)
mkdir -p /etc/lsb-release.d
cat > /etc/lsb-release << 'EOF'
DISTRIB_ID="Aaron Linux"
DISTRIB_RELEASE="1.0.0"
DISTRIB_CODENAME="aaron"
DISTRIB_DESCRIPTION="Aaron Linux 1.0.0"
EOF

# Create localtime symlink
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Set timezone
echo "UTC" > /etc/timezone

# Create /etc/resolv.conf (for network)
cat > /etc/resolv.conf << 'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# Create /etc/machine-id (empty for now)
printf "00000000000000000000000000000000\n" > /etc/machine-id

# Set root password
echo "root:aaron" | chpasswd

# Enable systemd getty@tty1
systemctl enable get@tty1

# Create basic journal config
mkdir -p /etc/systemd
cat > /etc/systemd/journald.conf << 'EOF'
[Journal]
Storage=persistent
Compress=yes
RateLimitInterval=30s
RateLimitBurst=50M
SystemMaxUse=100M
SystemMaxFileSize=10M
EOF

# Create logind config
cat > /etc/systemd/logind.conf << 'EOF'
[Login]
NAutoVTs=6
ReserveVT=6
KillUserProcesses=no
EOF

# Create limits.conf
cat > /etc/security/limits.conf << 'EOF'
* soft nofile 65536
* hard nofile 65536
root soft nofile unlimited
root hard nofile unlimited
EOF

# Create sysctl.conf
cat > /etc/sysctl.conf << 'EOF'
# Network settings
net.ipv4.ip_forward=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# Memory
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5
EOF

# Create modprobe blacklist
mkdir -p /etc/modprobe.d
cat > /etc/modprobe.d/blacklist.conf << 'EOF'
# Blacklist unused modules
blacklist pcspkr
blacklist joydev
EOF

log "System configuration complete!"
CONFIG