#!/bin/bash
# Aaron Linux - Step 3: Enter Chroot
# Chapter 7: Entering Chroot and building temporary tools

set -e

AARON_ROOT="/workspaces/Aaron-Linux"
LFS="/mnt/lfs"
SOURCES="$LFS/sources"
LOG_DIR="$AARON_ROOT/logs"

export LFS

log() {
    echo -e "\033[1;33m[$(date '+%Y-%m-%d %H:%M:%S')]\033[0m $1" | tee -a "$LOG_DIR/03-chroot.log"
}

err() { echo "ERROR: $1"; exit 1; }

[ -d "$LFS/tools" ] || err "Tools not built - run step 2 first"

log "Setting up chroot environment..."

# Create essential directories
log "Creating directory structure..."
mkdir -pv "$LFS"/{bin,boot,dev,etc{opt,profile.d,sysconfig},home,lib,media,mnth,mnt,opt,proc,root,run,sbin,srv,sys,usr/{bin,include,lib,local,sbin,share,src},var}
ln -sf /run "$LFS/var/run"
ln -sf /run/lock "$LFS/var/lock"

# Create log directory
mkdir -pv "$LFS/var/log"

# Create passwd file
cat > "$LFS/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:2:2:daemon:/dev/null:/bin/false
messagebus:x:3:4:system message bus:/dev/null:/bin/false
systemd-journal-gateway:x:4:21:systemd Journal Gateway:/dev/null:/bin/false
systemd-network:x:5:5:systemd Network Management:/dev/null:/bin/false
systemd-resolve:x:6:7:systemd Resolver:/dev/null:/bin/false
systemd-timesync:x:7:8:systemd Time Synchronization:/dev/null:/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/bin/false
EOF

# Create group file
cat > "$LFS/etc/group" << 'EOF'
root:x:0:
bin:x:1:daemon
sys:x:2:
adm:x:3:
tty:x:5:
wheel:x:10:
users:x:100:
nobody:x:65534:
EOF

# Create inputrc
cat > "$LFS/etc/inputrc" << 'EOF'
# /etc/inputrc - global inputrc for libreadline
set horizontal-scroll-mode On
set meta-flag On
set input-meta On
set convert-meta Off
set output-meta On
set bell-style audible
"\eOd": backward-word
"\eOc": forward-word
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert
"\e[B": next-history
"\e[A": previous-history
"\e[C": forward-char
"\e[D": backward-char
"\C-M": self-insert
"\C-?": backward-delete-char
EOF

# Create /etc/profile
cat > "$LFS/etc/profile" << 'EOF'
# /etc/profile

export PAGER=less
export EDITOR=vi
export INPUTRC=/etc/inputrc
export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin

# Set prompt
PS1='\u@\h:\w\$ '

# Load profiles
for i in /etc/profile.d/*.sh; do
    [ -r "$i" ] && . "$i"
done
unset i
EOF

# Create /etc/profile.d/ directory
mkdir -p "$LFS/etc/profile.d"

# Create bash.bashrc
cat > "$LFS/etc/bash.bashrc" << 'EOF'
# /etc/bash.bashrc

# Enable colors
export CLICOLOR=1
export LS_OPTIONS='--color=auto'

# Aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
EOF

log "Chroot environment prepared!"
log "Now entering chroot - this will run Chapter 7 packages"

# Copy sources to chroot
cp -r "$SOURCES" "$LFS/sources"

# Enter chroot and run Chapter 7
chroot "$LFS" /tools/bin/env -i \
    HOME=/root \
    TERM=xterm \
    PS1='(lfs chroot) \u@\h:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h << 'CHROOT_COMMANDS'

# Mount virtual filesystems
mount -t proc /proc /proc
mount -t sysfs /sys /sys
mount -t devpts /dev/pts /dev/pts

# Chapter 7 - Temporary Tools

# 7.5 Gettext
cd /sources
tar -xf gettext-0.22.tar.xz
cd gettext-0.22
./configure --disable-shared
make -j$(nproc)
cp -v intl/libintl.a /tools/lib
cp -v gettext-tools/src/msgfmt /tools/bin
cd /sources && rm -rf gettext-0.22

# 7.6 Bison
tar -xf bison-3.8.2.tar.xz
cd bison-3.8.2
./configure --prefix=/tools --without-libintl-prefix
make -j$(nproc)
make install
cd /sources && rm -rf bison-3.8.2

# 7.7 Perl
tar -xf perl-5.40.1.tar.xz
cd perl-5.40.1
sh Configure -des -Dprefix=/tools -Dprivlib=/tools/lib/perl5/5.40.1 -Darchlib=/tools/lib/perl5/5.40.1/x86_64-linux
make -j$(nproc)
cp -v perl cpan/podlators/pod2text /tools/bin/
rm -rf /tools/lib/perl5
cd /sources && rm -rf perl-5.40.1

# 7.8 Python
tar -xf Python-3.13.1.tar.xz
cd Python-3.13.1
./configure --prefix=/tools --without-ensurepip --disable-test-modules
make -j$(nproc)
make install
cd /sources && rm -rf Python-3.13.1

# 7.9 Texinfo
tar -xf texinfo-7.1.tar.xz
cd texinfo-7.1
./configure --prefix=/tools
make -j$(nproc)
make install
cd /sources && rm -rf texinfo-7.1

# 7.10 Util-linux (for chroot)
tar -xf util-linux-2.40.2.tar.xz
cd util-linux-2.40.2
./configure --prefix=/tools \
    --disable-makeinstall-chown \
    --without-python \
    --without-systemd \
    --without-tmpfiles \
    PKG_CONFIG=:
make -j$(nproc)
make install
cd /sources && rm -rf util-linux-2.40.2

echo "Chapter 7 temporary tools complete!"
CHROOT_COMMANDS

log "Step 3 complete - ready for step 4 (base system)"