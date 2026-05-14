#!/bin/bash
# Aaron Linux Build Script - LFS 12.3
# Main controller script

set -e

AARON_ROOT="/workspaces/Aaron-Linux"
LFS="/mnt/lfs"
LOG_DIR="$AARON_ROOT/logs"
BUILD_PACKAGES="$AARON_ROOT/scripts/packages"

export LFS

mkdir -p "$LOG_DIR" "$BUILD_PACKAGES"

log() {
    echo -e "\033[1;34m[$(date '+%Y-%m-%d %H:%M:%S')]\033[0m $1"
}

step() {
    log "=========================================="
    log "STEP: $1"
    log "=========================================="
}

usage() {
    echo "Aaron Linux Build Script"
    echo ""
    echo "Usage: $0 <step>"
    echo ""
    echo "Steps:"
    echo "  1-prepare      - Prepare partitions and filesystem"
    echo "  2-tools        - Build temporary toolchain (Ch5-6)"
    echo "  3-chroot       - Enter chroot environment (Ch7)"
    echo "  4-base         - Build base system (Ch8-10)"
    echo "  5-config       - System configuration"
    echo "  6-kernel       - Build Linux kernel"
    echo "  7-bootloader   - Install GRUB2"
    echo "  8-packages     - Install alpkg + DPKG + APT"
    echo "  9-iso          - Create live ISO"
    echo "  all            - Run all steps"
    echo ""
    echo "Logs: $LOG_DIR/"
}

case "$1" in
    1-prepare)
        step "1: Preparing partitions and filesystem"
        bash "$AARON_ROOT/scripts/01-prepare.sh"
        ;;
    2-tools)
        step "2: Building temporary toolchain"
        bash "$AARON_ROOT/scripts/02-toolchain.sh"
        ;;
    3-chroot)
        step "3: Entering chroot"
        bash "$AARON_ROOT/scripts/03-chroot.sh"
        ;;
    4-base)
        step "4: Building base system"
        bash "$AARON_ROOT/scripts/04-base-system.sh"
        ;;
    5-config)
        step "5: System configuration"
        bash "$AARON_ROOT/scripts/05-config.sh"
        ;;
    6-kernel)
        step "6: Building kernel"
        bash "$AARON_ROOT/scripts/06-kernel.sh"
        ;;
    7-bootloader)
        step "7: Installing GRUB2"
        bash "$AARON_ROOT/scripts/07-bootloader.sh"
        ;;
    8-packages)
        step "8: Installing package managers"
        bash "$AARON_ROOT/scripts/08-packages.sh"
        ;;
    9-iso)
        step "9: Creating ISO"
        bash "$AARON_ROOT/scripts/09-iso.sh"
        ;;
    all)
        log "Running full build - this will take some time, depending on your system's performance and specifications."
        for step in  2-tools 3-chroot 4-base 5-config 6-kernel 7-bootloader 8-packages 9-iso; do
            $0 $step
        done
        log "BUILD COMPLETE! Now run the iso with a VM or write it to a USB drive and boot it on real hardware."
        ;;
    *)
        usage 
        ;;
esac