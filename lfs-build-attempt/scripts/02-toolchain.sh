#!/bin/bash
# Aaron Linux - Step 2: Build Temporary Toolchain
# Chapter 5-6: Cross-compiler and temporary tools

set -e

AARON_ROOT="/workspaces/Aaron-Linux"
LFS="/mnt/lfs"
SOURCES="$LFS/sources"
LOG_DIR="$AARON_ROOT/logs"

export LFS TARCH=x86_64 TARGET=x86_64-lfs-linux-gnu
export PATH="$LFS/tools/bin:$PATH"

mkdir -p "$LOG_DIR"

log() {
    echo -e "\033[1;32m[$(date '+%Y-%m-%d %H:%M:%S')]\033[0m $1" | tee -a "$LOG_DIR/02-toolchain.log"
}

err() {
    echo -e "\033[1;31mERROR:\033[0m $1" | tee -a "$LOG_DIR/02-toolchain.log"
    exit 1
}

[ -d "$SOURCES" ] || err "Sources not found - run step 1 first"
log "Starting toolchain build..."

# Function to build a package
build_pkg() {
    local pkg=$1
    local logf="$LOG_DIR/build-${pkg%.tar*}.log"
    log "Building $pkg..."
    
    tar -xf "$SOURCES/$pkg" -C /tmp 2>/dev/null || return 1
    local dir=$(ls -d /tmp/${pkg%.tar*}* 2>/dev/null | head -1)
    
    if [ -z "$dir" ]; then
        err "Failed to extract $pkg"
    fi
    
    cd "$dir"
    ./configure --prefix=/tools > "$logf" 2>&1 || { err "Configure failed for $pkg"; }
    make >> "$logf" 2>&1 || { err "Make failed for $pkg"; }
    make install >> "$logf" 2>&1 || { err "Install failed for $pkg"; }
    cd /tmp
    rm -rf "$dir"
    log "Completed: $pkg"
}

# Step 5.2 - Creating the $LFS/tools Directory
log "Creating tools directory..."
mkdir -pv "$LFS/tools"
ln -sf "$LFS/tools" /tools

# Step 5.4 - Create passwd file
log "Creating essential files..."
cat > /tmp/limit.sh << 'EOF'
#!/bin/bash
EOF
chmod +x /tmp/limit.sh

# Create lfs user
groupadd lfs 2>/dev/null || true
useradd -s /bin/bash -g lfs -m -k /dev/null lfs 2>/dev/null || true
chown -v lfs:lfs "$LFS/tools"
chown -v lfs:lfs "$LFS/sources"

log "Toolchain setup complete!"
log "IMPORTANT: This script needs to run as root with lfs user created"
log "Continuing with binutils..."

# Binutils - Pass 1
log "Building Binutils Pass 1..."
tar -xf "$SOURCES/binutils-2.43.tar.xz" -C /tmp
cd /tmp/binutils-2.43
mkdir -p build && cd build
../configure --prefix=/tools \
    --with-sysroot="$LFS" \
    --target="$TARGET" \
    --disable-nls \
    --disable-werror >> "$LOG_DIR/binutils-p1.log" 2>&1
make -j$(nproc) >> "$LOG_DIR/binutils-p1.log" 2>&1
make install >> "$LOG_DIR/binutils-p1.log" 2>&1
cd /tmp && rm -rf binutils-2.43*
log "Binutils Pass 1 complete"

# GCC Pass 1
log "Building GCC Pass 1..."
tar -xf "$SOURCES/gcc-14.2.0.tar.xz" -C /tmp
cd /tmp/gcc-14.2.0
tar -xf "$SOURCES/mpfr-4.2.1.tar.xz" -C gcc
mv -v gcc/mpfr-4.2.1 gcc/mpfr
tar -xf "$SOURCES/gmp-6.3.0.tar.xz" -C gcc
mv -v gcc/gmp-6.3.0 gcc/gmp
tar -xf "$SOURCES/mpc-1.3.1.tar.gz" -C gcc
mv -v gcc/mpc-1.3.1 gcc/mpc

mkdir -p build && cd build
../configure --prefix=/tools \
    --target="$TARGET" \
    --with-glibc-version=2.40 \
    --with-sysroot="$LFS" \
    --with-newlib \
    --disable-nls \
    --disable-shared \
    --disable-multilib \
    --disable-decimal-float \
    --disable-threads \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libvtv \
    --disable-libstdc++ \
    --enable-languages=c,c++ >> "$LOG_DIR/gcc-p1.log" 2>&1

make -j$(nproc) >> "$LOG_DIR/gcc-p1.log" 2>&1
make install >> "$LOG_DIR/gcc-p1.log" 2>&1
cd /tmp && rm -rf gcc-14.2.0*
log "GCC Pass 1 complete"

# Linux API Headers
log "Building Linux API Headers..."
tar -xf "$SOURCES/linux-6.12.7.tar.xz" -C /tmp
cd /tmp/linux-6.12.7
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include "$LFS/tools"
cd /tmp && rm -rf linux-6.12.7*
log "Linux API Headers complete"

# Glibc
log "Building Glibc..."
tar -xf "$SOURCES/glibc-2.40.tar.xz" -C /tmp
cd /tmp/glibc-2.40
mkdir -p build && cd build
../configure --prefix=/tools \
    --host="$TARGET" \
    --build="$(../scripts/config.guess)" \
    --enable-kernel=4.19 \
    --with-headers="$LFS/tools/include" \
    --without-cvs \
    --without-selinux >> "$LOG_DIR/glibc.log" 2>&1

make -j$(nproc) >> "$LOG_DIR/glibc.log" 2>&1
make install >> "$LOG_DIR/glibc.log" 2>&1
cd /tmp && rm -rf glibc-2.40*
log "Glibc complete"

# Libstdc++ from GCC
log "Building Libstdc++..."
tar -xf "$SOURCES/gcc-14.2.0.tar.xz" -C /tmp
cd /tmp/gcc-14.2.0
tar -xf "$SOURCES/mpfr-4.2.1.tar.xz" -C gcc
mv -v gcc/mpfr-4.2.1 gcc/mpfr
tar -xf "$SOURCES/gmp-6.3.0.tar.xz" -C gcc
mv -v gcc/gmp-6.3.0 gcc/gmp
tar -xf "$SOURCES/mpc-1.3.1.tar.gz" -C gcc
mv -v gcc/mpc-1.3.1 gcc/mpc

mkdir -p build && cd build
../libstdc++-v3/configure --prefix=/tools \
    --host="$TARGET" \
    --disable-multilib \
    --disable-nls \
    --disable-libstdcxx-visibility \
    --with-gxx-include-dir=/tools/include/c++/14.2.0 >> "$LOG_DIR/libstdc++.log" 2>&1
make -j$(nproc) >> "$LOG_DIR/libstdc++.log" 2>&1
make install >> "$LOG_DIR/libstdc++.log" 2>&1
cd /tmp && rm -rf gcc-14.2.0*
log "Libstdc++ complete"

# Final fix for lib tool
log "Adjusting toolchain..."
mv -v /tools/bin/ld /tools/bin/ld-old
mv -v /tools/x86_64-lfs-linux-gnu/bin/ld /tools/x86_64-lfs-linux-gnu/bin/ld-old
mv -v /tools/bin/ld-new /tools/bin/ld
ln -sv /tools/bin/ld /tools/x86_64-lfs-linux-gnu/bin/ld

log "Toolchain build complete!"
log "Run step 3 to enter chroot and build the rest"