#!/bin/bash
# Aaron Linux - Step 4: Build Base System
# Chapter 8-10: Full system packages

set -e

AARON_ROOT="/workspaces/Aaron-Linux"
LFS="/mnt/lfs"
SOURCES="$LFS/sources"
LOG_DIR="$AARON_ROOT/logs"

export LFS

log() {
    echo -e "\033[1;36m[$(date '+%Y-%m-%d %H:%M:%S')]\033[0m $1" | tee -a "$LOG_DIR/04-base.log"
}

err() { echo "ERROR: $1"; exit 1; }

log "Building full base system..."

# Enter chroot for Chapter 8-10
chroot "$LFS" /tools/bin/env -i \
    HOME=/root \
    TERM=xterm \
    PS1='(lfs chroot) \u@\h:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h << 'CHROOT_BUILD'

# Chapter 8 - Essential Software
cd /sources

# 8.2 Man-pages
tar -xf man-pages-6.13.tar.xz
cp -rv man-pages-6.13/* /usr/share/man
rm -rf man-pages-6.13

# 8.3 Glibc
tar -xf glibc-2.40.tar.xz
cd glibc-2.40
patch -Np1 -i ../glibc-2.40-fhs-1.patch
mkdir -p build && cd build
../configure --prefix=/usr \
    --disable-werror \
    --enable-kernel=4.19 \
    --enable-stack-protector=strong \
    --with-headers=/usr/include \
    libc_cv_slibdir=/lib
make -j$(nproc)
make install
rm -rf /usr/include/bits/buf*.h
ldconfig
cd /sources && rm -rf glibc-2.40*

# 8.4 GCC
tar -xf gcc-14.2.0.tar.xz
cd gcc-14.2.0
tar -xf ../mpfr-4.2.1.tar.xz -C gcc && mv gcc/mpfr-4.2.1 gcc/mpfr
tar -xf ../gmp-6.3.0.tar.xz -C gcc && mv gcc/gmp-6.3.0 gcc/gmp
tar -xf ../mpc-1.3.1.tar.gz -C gcc && mv gcc/mpc-1.3.1 gcc/mpc

mkdir -p build && cd build
../configure --prefix=/usr \
    --libdir=/usr/lib \
    --enable-linuxstd=8.0.0 \
    --enable-cet=auto \
    --enable-__cxa_atexit \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-install-libiberty \
    --disable-libmpx \
    --disable-multilib \
    --disable-system-z \
    --enable-languages=c,c++,fortran,go,lto,objc \
    --with-glibc-version=2.40 \
    --with-system-zlib \
    --with-headers=/usr/include \
    PKG_CONFIG_PATH=/tools/lib/pkgconfig
make -j$(nproc)
make install
ln -sf gcc /usr/bin/cc
cd /sources && rm -rf gcc-14.2.0*

# 8.5-8.7 Core utilities
tar -xf coreutils-9.5.tar.xz
cd coreutils-9.5
./configure --prefix=/usr --enable-install-program=hostname
make -j$(nproc)
make install
cd /sources && rm -rf coreutils-9.5*

tar -xf diffutils-3.10.tar.xz
cd diffutils-3.10
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf diffutils-3.10*

tar -xf findutils-4.9.0.tar.xz
cd findutils-4.9.0
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf findutils-4.9.0*

tar -xf gawk-5.3.0.tar.xz
cd gawk-5.3.0
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf gawk-5.3.0*

# 8.8 Grep, Gzip
tar -xf grep-3.11.tar.xz
cd grep-3.11
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf grep-3.11*

tar -xf gzip-1.13.tar.xz
cd gzip-1.13
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf gzip-1.13*

tar -xf tar-1.35.tar.xz
cd tar-1.35
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf tar-1.35*

# 8.9 Sed
tar -xf sed-4.9.tar.xz
cd sed-4.9
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf sed-4.9*

# 8.10 Psmisc
tar -xf psmisc-23.7.tar.xz
cd psmisc-23.7
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf psmisc-23.7*

# 8.11-8.14 Ncurses, Bash
tar -xf ncurses-6.5.tar.xz
cd ncurses-6.5
./configure --prefix=/usr \
    --with-shared \
    --without-debug \
    --without-ada \
    --enable-widec
make -j$(nproc) && make install
ln -sf libncursesw.so /usr/lib/libncurses.so
cd /sources && rm -rf ncurses-6.5*

tar -xf bash-5.2.37.tar.gz
cd bash-5.2.37
./configure --prefix=/usr \
    --without-bash-malloc \
    --with-installed-readline
make -j$(nproc) && make install
cd /sources && rm -rf bash-5.2.37*

# 8.15-8.17 Libtool, GDBM, Gperf
tar -xf libtool-2.5.4.tar.xz
cd libtool-2.5.4
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf libtool-2.5.4*

tar -xf gdbm-1.24.tar.gz
cd gdbm-1.24
./configure --prefix=/usr --disable-static
make -j$(nproc) && make install
cd /sources && rm -rf gdbm-1.24*

tar -xf gperf-3.1.tar.gz
cd gperf-3.1
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf gperf-3.1*

# 8.18-8.20 Expat, Intel, JSON-C
tar -xf expat-2.6.3.tar.xz
cd expat-2.6.3
./configure --prefix=/usr --disable-static
make -j$(nproc) && make install
cd /sources && rm -rf expat-2.6.3*

tar -xf libintl-0.22.tar.gz
cd libintl-0.22
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf libintl-0.22*

tar -xf json-c-0.18.tar.gz
cd json-c-0.18
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_STATIC=OFF
cmake --build build -j$(nproc)
cmake --install build
cd /sources && rm -rf json-c-0.18*

# 8.21-8.23 Libxml2, Lz4, Zstd
tar -xf libxml2-2.12.8.tar.xz
cd libxml2-2.12.8
./configure --prefix=/usr --with-python=no
make -j$(nproc) && make install
cd /sources && rm -rf libxml2-2.12.8*

tar -xf lz4-1.10.0.tar.gz
cd lz4-1.10.0
make -j$(nproc) PREFIX=/usr install
cd /sources && rm -rf lz4-1.10.0*

tar -xf zstd-1.5.6.tar.gz
cd zstd-1.5.6
make -j$(nproc) PREFIX=/usr install
cd /sources && rm -rf zstd-1.5.6*

# 8.24-8.25 Xz, File
tar -xf xz-5.6.2.tar.xz
cd xz-5.6.2
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf xz-5.6.2*

tar -xf file-5.45.tar.gz
cd file-5.45
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf file-5.45*

# Chapter 9 - Systemd Base
cd /sources

# 9.3 Libcap
tar -xf libcap-2.70.tar.xz
cd libcap-2.70
make -j$(nproc) prefix=/usr lib=lib
make -j$(nproc) prefix=/usr lib=lib install
cd /sources && rm -rf libcap-2.70*

# 9.4 Audit
tar -xf audit-3.1.5.tar.xz
cd audit-3.1.5
./configure --prefix=/usr --disable-static
make -j$(nproc) && make install
cd /sources && rm -rf audit-3.1.5*

# 9.5 Libselinux
tar -xf libselinux-3.7.tar.gz
cd libselinux-3.7
make -j$(nproc) prefix=/usr libexecdir=/usr/lib
make -j$(nproc) prefix=/usr libexecdir=/usr/lib install
cd /sources && rm -rf libselinux-3.7*

# 9.6 Libseccomp
tar -xf libseccomp-2.5.5.tar.gz
cd libseccomp-2.5.5
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf libseccomp-2.5.5*

# 9.7-9.10 D-Bus, systemd (Core)
tar -xf dbus-1.16.0.tar.gz
cd dbus-1.16.0
./configure --prefix=/usr \
    --disable-doxygen-docs \
    --disable-silent-rules \
    --enable-systemd \
    --enable-user-session
make -j$(nproc) && make install
cd /sources && rm -rf dbus-1.16.0*

tar -xf systemd-256.5.tar.gz
cd systemd-256.5
mkdir build && cd build
meson setup .. --prefix=/usr \
    --buildtype=release \
    -Dmode=combined \
    -Dstandalone-archive=false \
    -Dlink-udev-shared=true \
    -Drootprefix= \
    -Dsplit-usr=true \
    -Dsplit-bin=true \
    -Ddefault-priority=10 \
    -Dsysvinit-path= \
    -Dinitrd-path= \
    -Dboot-path=/boot \
    -Dpamconfdir=/etc/pam.d \
    -Dsystemdsystemunitdir=/lib/systemd/system \
    -Dman=false \
    -Defi=false
ninja -j$(nproc)
ninja install
cd /sources && rm -rf systemd-256.5*

# 9.11-9.14 Dbus-glib, openssl, pcre2
tar -xf pcre2-10.44.tar.bz2
cd pcre2-10.44
./configure --prefix=/usr --enable-utf8
make -j$(nproc) && make install
cd /sources && rm -rf pcre2-10.44*

tar -xf openssl-3.4.0.tar.gz
cd openssl-3.4.0
./config --prefix=/usr --openssldir=/etc/ssl shared
make -j$(nproc) && make install_sw install_ssldirs
cd /sources && rm -rf openssl-3.4.0*

# 9.15 Shadow (for useradd)
tar -xf shadow-4.16.1.tar.xz
cd shadow-4.16.1
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
./configure --sysconfdir=/etc --disable-setuid
make -j$(nproc) && make install
pwconv
grpconv
cd /sources && rm -rf shadow-4.16.1*

# Chapter 10 - Network & Utils
cd /sources

# 10.1-10.2 kmod, libelf
tar -xf kmod-33.tar.xz
cd kmod-33
./configure --prefix=/usr --with-xz --with-zstd --with-selinux
make -j$(nproc) && make install
ln -sf kmod /usr/bin/lsmod
cd /sources && rm -rf kmod-33*

tar -xf libelf-0.191.tar.gz
cd libelf-0.191
./configure --prefix=/usr --disable-static --enable-lib64
make -j$(nproc) && make install
cd /sources && rm -rf libelf-0.191*

# 10.3-10.4 OpenSSH
tar -xf openssh-9.8p1.tar.gz
cd openssh-9.8p1
./configure --prefix=/usr --sysconfdir=/etc/ssh
make -j$(nproc) && make install
cd /sources && rm -rf openssh-9.8p1*

# 10.5 Procps-ng
tar -xf procps-ng-4.0.0.tar.xz
cd procps-ng-4.0.0
./configure --prefix=/usr --disable-kill
make -j$(nproc) && make install
cd /sources && rm -rf procps-ng-4.0.0*

# 10.6 E2fsprogs
tar -xf e2fsprogs-1.47.1.tar.gz
cd e2fsprogs-1.47.1
./configure --prefix=/usr --disable-libblkid --disable-libuuid
make -j$(nproc) && make install
cd /sources && rm -rf e2fsprogs-1.47.1*

# 10.7-10.8 Iproute2, iputils
tar -xf iproute2-6.14.0.tar.xz
cd iproute2-6.14.0
./configure
make -j$(nproc) SBINDIR=/usr/sbin install
cd /sources && rm -rf iproute2-6.14.0*

tar -xf iputils-20240117.tar.gz
cd iputils-20240117
make -j$(nproc) USE_CAP=no
make -j$(nproc) USE_CAP=no install
cd /sources && rm -rf iputils-20240117*

# 10.9 Less, nano
tar -xf less-661.tar.gz
cd less-661
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf less-661*

tar -xf nano-8.1.tar.xz
cd nano-8.1
./configure --prefix=/usr
make -j$(nproc) && make install
cd /sources && rm -rf nano-8.1*

echo "Base system build complete!"
CHROOT_BUILD

log "Step 4 complete!"