#!/bin/bash
# Aaron Linux - Step 8: Install Package Managers
# alpkg (native), DPKG, and APT

set -e

LFS="/mnt/lfs"
LOG_DIR="/workspaces/Aaron-Linux/logs"

log() { echo -e "\033[1;33m[$(date)]\033[0m $1" | tee -a "$LOG_DIR/08-packages.log"; }

log "Installing package managers..."

chroot "$LFS" /tools/bin/env -i \
    HOME=/root TERM=xterm PS1='(chroot) \u@\h:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login << 'PKGS'

# Create directories
mkdir -p /var/{packages,lib/{alpkg,dpkg},cache/{apt,alpkg},log}
mkdir -p /etc/{alpkg,dpkg,apt}

# ============ DPKG ============
cd /sources
tar -xf dpkg_1.19.13.tar.xz
cd dpkg-1.19.13

# Bootstrap DPKG
./configure --prefix=/usr --libdir=/usr/lib --with-db-path=/var/lib/dpkg
make -j$(nproc)
make install

# Initialize dpkg database
mkdir -p /var/lib/dpkg/{info,status,available}
touch /var/lib/dpkg/{status,available}
mkdir -p /var/lib/dpkg/info

cd /sources && rm -rf dpkg-1.19.13*

# ============ APT ============
cd /sources
tar -xf apt-2.7.14.tar.gz
cd apt-2.7.14

./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var \
    --disable-doc --disable-static
make -j$(nproc)
make install

cd /sources && rm -rf apt-2.7.14*

# ============ ALPKG (Native) ============
# Create alpkg package manager
mkdir -p /usr/share/alpkg
cat > /usr/bin/alpkg << 'ALPKG'
#!/bin/bash
# alpkg - Aaron Linux Package Manager

DB_DIR="/var/lib/alpkg"
PKG_DIR="/var/packages"
CACHE_DIR="/var/cache/alpkg"

help() {
    echo "alpkg - Aaron Linux Package Manager"
    echo "Usage: alpkg <command> [options]"
    echo ""
    echo "Commands:"
    echo "  install <file.alp>    Install a .alp package"
    echo "  remove <name>        Remove a package"
    echo "  list                 List installed packages"
    echo "  search <query>       Search packages"
    echo "  update               Update package database"
}

cmd_install() {
    local pkg=$1
    [ -f "$pkg" ] || { echo "Error: $pkg not found"; exit 1; }
    
    local name=$(basename "$pkg" .alp)
    echo "Installing $name..."
    
    # Extract
    local work=$(mktemp -d)
    cd "$work"
    tar -xf "$pkg"
    
    # Run install.sh if exists
    if [ -f install.sh ]; then
        chmod +x install.sh
        ./install.sh
    fi
    
    # Extract data
    if [ -f data.tar.xz ]; then
        tar -xf data.tar.xz -C /
    fi
    
    # Add to database
    echo "$name" >> "$DB_DIR/db"
    
    rm -rf "$work"
    echo "Installed: $name"
}

cmd_remove() {
    local name=$1
    grep -q "^$name$" "$DB_DIR/db" || { echo "Not found: $name"; exit 1; }
    echo "Removing $name..."
    # Basic removal - would need more logic for real removal
    sed -i "/^$name$/d" "$DB_DIR/db"
    echo "Removed: $name"
}

cmd_list() {
    cat "$DB_DIR/db"
}

cmd_search() {
    local query=$1
    ls "$PKG_DIR" 2>/dev/null | grep "$query"
}

cmd_update() {
    echo "Updating package database..."
    ls "$PKG_DIR" > "$DB_DIR/packages"
    echo "Done"
}

mkdir -p "$DB_DIR" "$PKG_DIR" "$CACHE_DIR"

case "$1" in
    install) cmd_install "$2" ;;
    remove) cmd_remove "$2" ;;
    list) cmd_list ;;
    search) cmd_search "$2" ;;
    update) cmd_update ;;
    *) help ;;
esac
ALPKG
chmod +x /usr/bin/alpkg

# Create alpkg config
cat > /etc/alpkg/alpkg.conf << 'EOF'
# alpkg configuration
PKG_DIR=/var/packages
DB_DIR=/var/lib/alpkg
CACHE_DIR=/var/cache/alpkg
EOF

# Create default APT sources
cat > /etc/apt/sources.list << 'EOF'
# Aaron Linux APT sources
deb http://deb.debian.org/debian stable main contrib non-free
deb http://security.debian.org/debian-security stable-security main
EOF

# Create APT preferences
cat > /etc/apt/preferences << 'EOF'
Package: *
Pin: release a=stable
Pin-Priority: 900
EOF

# Update APT database
apt-get update 2>/dev/null || true

log "Package managers installed!"
log "  - alpkg: /usr/bin/alpkg"
log "  - dpkg: /usr/bin/dpkg"
log "  - apt-get: /usr/bin/apt-get"
PKGS