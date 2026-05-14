#!/bin/bash
# Download all LFS 12.3 packages

SOURCES=/mnt/lfs/sources
LFS_VERSION=12.3

mkdir -p "$SOURCES"

cd "$SOURCES"

# LFS 12.3 packages - core packages
PACKAGES=(
    # Core packages - Chapter 5
    "binutils-2.43.tar.xz"
    "bison-3.8.2.tar.xz"
    "bzip2-1.0.8.tar.gz"
    "coreutils-9.5.tar.xz"
    "diffutils-3.10.tar.xz"
    "file-5.45.tar.gz"
    "findutils-4.9.0.tar.xz"
    "gawk-5.3.0.tar.xz"
    "gcc-14.2.0.tar.xz"
    "glibc-2.40.tar.xz"
    "gmp-6.3.0.tar.xz"
    "grep-3.11.tar.xz"
    "gzip-1.13.tar.xz"
    "linux-6.12.7.tar.xz"
    "m4-1.4.19.tar.xz"
    "make-4.4.1.tar.xz"
    "mpfr-4.2.1.tar.xz"
    "ncurses-6.5.tar.xz"
    "patch-2.7.6.tar.xz"
    "sed-4.9.tar.xz"
    "sysvinit-3.10.tar.xz"
    "tar-1.35.tar.xz"
    "texinfo-7.1.tar.xz"
    "util-linux-2.40.2.tar.xz"
    "xz-5.6.2.tar.xz"
    "zstd-1.5.6.tar.gz"

    # Chapter 6 additions
    "mpc-1.3.1.tar.gz"
    "isl-0.24.tar.xz"
    "expat-2.6.3.tar.xz"
    "libarchive-3.7.4.tar.xz"
    "libffi-8.1.0.tar.gz"
    "Python-3.13.1.tar.xz"
    "wheel-0.45.1.tar.gz"
    " Jinja2-3.1.4.tar.gz"
    "MarkupSafe-3.0.2.tar.gz"
    "dynamic-core-0.13.0.tar.gz"

    # Chapter 8 - Systemd packages
    "dbus-1.16.0.tar.gz"
    "systemd-256.5.tar.gz"
    "systemd-man-pages-256.3.tar.xz"
    "libcap-2.70.tar.xz"
    "libcap-PAM-1.5.1.tar.xz"
    "audit-3.1.5.tar.xz"
    "openssl-3.4.0.tar.gz"
    "libressl-3.8.9.tar.gz"
    "kmod-33.tar.xz"
    "popt-1.19.tar.gz"
    "acl-2.3.2.tar.xz"
    "attr-2.5.2.tar.xz"
    "libseccomp-2.5.5.tar.gz"
    "libselinux-3.7.tar.gz"
    "pcre2-10.44.tar.bz2"
    "shadow-4.16.1.tar.xz"
    "libgd-2.3.3.tar.xz"
    "ICU-76.1.tar.gz"
    "libxml2-2.12.8.tar.xz"
    "lz4-1.10.0.tar.gz"
    "curl-8.11.1.tar.gz"
    "nghttp2-1.63.0.tar.gz"
    "libpsl-0.21.5.tar.gz"
    "libssh2-1.11.1.tar.gz"
    "cmake-3.31.1.tar.gz"
    "ninja-1.12.1.tar.gz"
    "meson-1.6.0.tar.gz"

    # Base system
    "procps-ng-4.0.0.tar.xz"
    "util-linux-2.40.2.tar.xz"
    "e2fsprogs-1.47.1.tar.gz"
    "dosfstools-4.2.tar.gz"
    "logsave-1.21.1.tar.gz"
    "gdbm-1.24.tar.gz"
    "bc-6.7.0.tar.xz"
    "installwatch-0.7.0.tar.gz"

    # Boot
    "grub-2.12.tar.xz"
    "linux-6.12.7.tar.xz"

    # Shell and tools
    "bash-5.2.37.tar.gz"
    "zsh-5.9.tar.gz"

    # Compression
    "xz-5.6.2.tar.xz"
    "zstd-1.5.6.tar.gz"
    "lz4-1.10.0.tar.gz"

    # Networking
    "iproute2-6.14.0.tar.xz"
    "iputils-20240117.tar.gz"
    "network-manager-1.50.0.tar.gz"
    "resolvconf-1.93.tar.gz"

    # Text tools
    "vim-9.1.0801.tar.gz"
    "less-661.tar.gz"
    "nano-8.1.tar.gz"
    "tree-2.1.0.tgz"
    "htop-3.3.0.tar.gz"

    # Development
    "git-2.47.1.tar.gz"
    "gcc-14.2.0.tar.xz"
    "make-4.4.1.tar.xz"
    "cmake-3.31.1.tar.gz"
    "ninja-1.12.1.tar.gz"
    "meson-1.6.0.tar.gz"

    # Package management
    "dpkg_1.19.13.tar.xz"
    "apt-2.7.14.tar.gz"

    # alpkg - custom
)

# Base URL for packages
BASE_URL="https://ftp.osuosl.org/pub/lfs/lfs-packages/12.3/"

for pkg in "${PACKAGES[@]}"; do
    if [ ! -f "$pkg" ]; then
        echo "Downloading $pkg..."
        wget -q --show-progress "$BASE_URL/$pkg" || \
        wget -q --show-progress "https://www.linuxfromscratch.org/lfs/downloads/12.3/$pkg" || \
        echo "WARNING: Could not download $pkg"
    fi
done

echo "Download complete!"
