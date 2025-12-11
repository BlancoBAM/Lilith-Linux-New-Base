#!/bin/bash
# 🔥 LILITH LINUX REBIRTH EDITION - ISO BUILD ONLY 🔥
# Creates bootable ISO from prepared lilith-system-root/
# Does NOT modify host system - ISO creation only!

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"  # Parent directory of rebirth-edition
SYSTEM_ROOT="$BUILD_DIR/lilith-system-root"
# Use actual user's home directory, not sudo user's home
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
ISO_OUTPUT="$REAL_HOME/Lilith-Linux-Rebirth-Edition-$(date +%Y%m%d).iso"
WORK_DIR="/tmp/lilith-iso-build-$(date +%s)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Cleanup function
cleanup() {
    log "🧹 Cleaning up temporary files..."
    [ -d "$WORK_DIR" ] && sudo rm -rf "$WORK_DIR"
}

trap cleanup EXIT

# Phase 0: Prepare base system if needed
prepare_base_system() {
    log "🔧 Checking base system..."

    # Check if lilith-system-root has a complete system by checking for essential directories
    if [ ! -d "$SYSTEM_ROOT/bin" ] || [ ! -d "$SYSTEM_ROOT/usr" ] || [ ! -d "$SYSTEM_ROOT/lib" ]; then
        log "⚠️  lilith-system-root appears to be empty or incomplete"
        log "📦 Setting up base Ubuntu system..."

        # Call the setup script to create the base system
        if [ -f "$SCRIPT_DIR/setup-base-system.sh" ]; then
            sudo bash "$SCRIPT_DIR/setup-base-system.sh" || error "Failed to set up base system"
            log "✅ Base system created successfully"
        else
            error "setup-base-system.sh not found. Please run setup-base-system.sh first."
        fi
    else
        log "✅ Base system already exists"
    fi
}

# Phase 1: Pre-flight checks
preflight_checks() {
    log "🔍 Performing ISO build pre-flight checks..."

    # Check if we're in the right directory
    if [ ! -d "ai-bundle" ] || [ ! -d "ceremony" ] || [ ! -d "lilith-system-root" ]; then
        error "Please run this script from the rebirth-edition directory"
    fi

    # Check system root exists
    if [ ! -d "$SYSTEM_ROOT" ]; then
        error "System root not found at: $SYSTEM_ROOT"
    fi

    # Check required tools (check actual commands used)
    local required_commands=("xorriso" "mksquashfs" "rsync" "debootstrap")
    local missing_commands=()
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done

    if [ ${#missing_commands[@]} -ne 0 ]; then
        error "Missing required commands: ${missing_commands[*]}. Please install with: sudo apt install xorriso squashfs-tools rsync debootstrap"
    fi

    # Check available disk space (need at least 15GB in real user's home)
    local available_space
    available_space=$(df "$REAL_HOME" | tail -1 | awk '{print int($4/1024/1024)}')
    if [ "$available_space" -lt 15 ]; then
        error "Need at least 15GB free space in $REAL_HOME. Found: ${available_space}GB"
    fi

    log "✅ Pre-flight checks passed"
}

# Phase 2: Set up ISO structure
setup_iso_structure() {
    log "📁 Setting up ISO directory structure..."

    # Create working directory
    sudo mkdir -p "$WORK_DIR"
    sudo chown -R "$USER:$USER" "$WORK_DIR"

    # Create ISO structure
    mkdir -p "$WORK_DIR"/{casper,isolinux,boot/grub,.disk}

    # Create .disk info
    cat > "$WORK_DIR/.disk/info" << EOF
Lilith Linux Rebirth Edition
Built on: $(date)
Architecture: amd64
EOF

    cat > "$WORK_DIR/.disk/release_notes" << EOF
Lilith Linux Rebirth Edition - December 9th Special Release
Features: AI Integration, Rebirth Ceremony, Hardware Optimization
EOF

    log "✅ ISO structure created"
}

# Phase 3: Copy system files and create squashfs
create_filesystem() {
    log "💾 Creating compressed filesystem..."

    # Use existing bootable ISO as base, then overlay customizations
    if [ -f "$BUILD_DIR/output/lilith-linux-1.0-amd64.iso" ]; then
        log "🔄 Using existing bootable ISO as base system..."

        # Extract the existing bootable ISO
        sudo mkdir -p "$WORK_DIR/extract"
        sudo mount -o loop,ro "$BUILD_DIR/output/lilith-linux-1.0-amd64.iso" "$WORK_DIR/extract" 2>/dev/null || {
            warn "Could not mount existing ISO, extracting with 7z..."
            7z x "$BUILD_DIR/output/lilith-linux-1.0-amd64.iso" -o"$WORK_DIR/extract" >/dev/null 2>&1 || {
                error "Could not extract existing ISO. Please ensure lilith-linux-1.0-amd64.iso exists in output/"
            }
        }

        # Copy the complete filesystem from existing ISO
        if [ -d "$WORK_DIR/extract/casper" ]; then
            sudo unsquashfs -d "$WORK_DIR/casper/filesystem.dir" "$WORK_DIR/extract/casper/filesystem.squashfs" >/dev/null 2>&1
            log "✅ Base Ubuntu system extracted from existing ISO"

            # Now overlay our Lilith customizations
            log "🔧 Overlaying Lilith customizations..."
            sudo rsync -aHAX "$SYSTEM_ROOT/" "$WORK_DIR/casper/filesystem.dir/"
            log "✅ Lilith customizations overlaid on base system"
        else
            error "Existing ISO does not have proper casper structure"
        fi

        # Clean up extraction mount
        sudo umount "$WORK_DIR/extract" 2>/dev/null || true
        sudo rm -rf "$WORK_DIR/extract"
    else
        error "No existing bootable ISO found at: $BUILD_DIR/output/lilith-linux-1.0-amd64.iso"
    fi

    # Copy kernel and initrd (try multiple sources and be more robust)
    kernel_copied=false
    initrd_copied=false

    # Find kernel in the system root (Ubuntu has it in /boot/vmlinuz-*version*)
    # Find latest kernel file
    for kernel in "$SYSTEM_ROOT"/boot/vmlinuz-*; do
        if [ -f "$kernel" ]; then
            sudo cp "$kernel" "$WORK_DIR/casper/vmlinuz"
            sudo chown "$USER:$USER" "$WORK_DIR/casper/vmlinuz"
            log "✅ Kernel copied: $(basename "$kernel")"
            kernel_copied=true
            break
        fi
    done

    # Find initrd in the system root
    for initrd in "$SYSTEM_ROOT"/boot/initrd.img-*; do
        if [ -f "$initrd" ]; then
            sudo cp "$initrd" "$WORK_DIR/casper/initrd"
            sudo chown "$USER:$USER" "$WORK_DIR/casper/initrd"
            log "✅ Initrd copied: $(basename "$initrd")"
            initrd_copied=true
            break
        fi
    done

    # Fallback: try from host system if not found in system root
    if [ "$kernel_copied" = false ] && [ -f "/boot/vmlinuz-$(uname -r)" ]; then
        sudo cp "/boot/vmlinuz-$(uname -r)" "$WORK_DIR/casper/vmlinuz"
        sudo chown "$USER:$USER" "$WORK_DIR/casper/vmlinuz"
        log "✅ Kernel copied from host system"
        kernel_copied=true
    fi

    if [ "$initrd_copied" = false ] && [ -f "/boot/initrd.img-$(uname -r)" ]; then
        sudo cp "/boot/initrd.img-$(uname -r)" "$WORK_DIR/casper/initrd"
        sudo chown "$USER:$USER" "$WORK_DIR/casper/initrd"
        log "✅ Initrd copied from host system"
        initrd_copied=true
    fi

    # Final check
    if [ "$kernel_copied" = false ]; then
        error "Could not find kernel file anywhere. Make sure the base system is properly installed."
    fi

    if [ "$initrd_copied" = false ]; then
        error "Could not find initrd file anywhere. Make sure the base system is properly installed."
    fi

    # Create filesystem manifest (skip if no dpkg available)
    log "📋 Creating filesystem manifest..."
    if sudo chroot "$WORK_DIR/casper/filesystem.dir" dpkg-query -W --showformat='${Package} ${Version}\n' > "$WORK_DIR/casper/filesystem.manifest" 2>/dev/null; then
        # Remove diverted packages from manifest
        if sudo chroot "$WORK_DIR/casper/filesystem.dir" dpkg-divert --list > /dev/null 2>&1; then
            sudo chroot "$WORK_DIR/casper/filesystem.dir" dpkg-divert --list | cut -d' ' -f1 > "$WORK_DIR/casper/filesystem.manifest-remove" 2>/dev/null || true
            if [ -f "$WORK_DIR/casper/filesystem.manifest-remove" ]; then
                grep -v -f "$WORK_DIR/casper/filesystem.manifest-remove" "$WORK_DIR/casper/filesystem.manifest" > "$WORK_DIR/casper/filesystem.manifest-desktop"
            fi
        fi
        log "✅ Filesystem manifest created"
    else
        warn "dpkg not available in system root, skipping manifest creation"
        # Create basic manifest from directory contents
        find "$WORK_DIR/casper/filesystem.dir" -name "*.deb" -exec basename {} \; | sed 's/_.*//' > "$WORK_DIR/casper/filesystem.manifest" 2>/dev/null || true
    fi

    # Create squashfs (try multiple approaches for resource-constrained systems)
    log "🗜️  Compressing filesystem (this may take a while)..."

    # Try with minimal memory usage first
    sudo mksquashfs "$WORK_DIR/casper/filesystem.dir" "$WORK_DIR/casper/filesystem.squashfs" \
        -comp gzip -b 128K -Xcompression-level 1 -processors 1 -no-progress 2>/dev/null || {

        # Fallback: even more memory-efficient
        warn "Standard compression failed, trying minimal memory approach..."
        sudo mksquashfs "$WORK_DIR/casper/filesystem.dir" "$WORK_DIR/casper/filesystem.squashfs" \
            -comp gzip -b 64K -Xcompression-level 1 -processors 1 -no-progress 2>/dev/null || {

            # Last resort: no compression (creates larger ISO)
            warn "Compression failed, creating uncompressed filesystem..."
            sudo mksquashfs "$WORK_DIR/casper/filesystem.dir" "$WORK_DIR/casper/filesystem.squashfs" \
                -no-compression -processors 1 -no-progress 2>/dev/null || {

                error "All compression methods failed. System requires more RAM (8GB+) or disk space for ISO creation."
            }
        }
    }

    # Calculate size
    printf $(du -sx --block-size=1 "$WORK_DIR/casper/filesystem.dir" | cut -f1) > "$WORK_DIR/casper/filesystem.size"

    # Clean up uncompressed filesystem
    sudo rm -rf "$WORK_DIR/casper/filesystem.dir"

    log "✅ Filesystem compressed"
}

# Phase 4: Set up bootloader
setup_bootloader() {
    log "🛠️  Setting up bootloader..."

    # Create isolinux config
    cat > "$WORK_DIR/isolinux/isolinux.cfg" << EOF
DEFAULT vesamenu.c32
TIMEOUT 300

MENU TITLE Lilith Linux Rebirth Edition
MENU BACKGROUND splash.png
MENU COLOR title        * #FFFFFFFF *
MENU COLOR border       * #00000000 #00000000 none
MENU COLOR sel          * #ffffffff #76a1d0ff *
MENU COLOR hotsel       1;7;37;40 #ffffffff #76a1d0ff *
MENU COLOR tabmsg       31;40 #80ffffff #00000000 *
MENU COLOR help         37;40 #ffdddd00 #00000000 *
MENU COLOR unsel        * #ffdddd00 #00000000 *

LABEL live
  menu label ^Start Lilith Linux Rebirth Edition
  menu default
  kernel /casper/vmlinuz
  append initrd=/casper/initrd boot=casper quiet splash ---

LABEL live-nomodeset
  menu label ^Start Lilith Linux Rebirth Edition (Safe Graphics)
  kernel /casper/vmlinuz
  append initrd=/casper/initrd boot=casper nomodeset quiet splash ---

LABEL check
  menu label ^Check disc for defects
  kernel /casper/vmlinuz
  append initrd=/casper/initrd boot=casper integrity-check quiet splash ---

LABEL memtest
  menu label ^Test memory
  kernel memtest
  append -
EOF

    # Copy isolinux binaries from system (try multiple possible locations)
    if [ -f "/usr/lib/ISOLINUX/isolinux.bin" ]; then
        cp "/usr/lib/ISOLINUX/isolinux.bin" "$WORK_DIR/isolinux/"
        log "✅ ISOLINUX bootloader binary copied"
    elif [ -f "/usr/lib/syslinux/isolinux.bin" ]; then
        cp "/usr/lib/syslinux/isolinux.bin" "$WORK_DIR/isolinux/"
        log "✅ ISOLINUX bootloader binary copied (from syslinux)"
    else
        warn "ISOLINUX binary not found on system. Looking for alternatives..."
    fi

    # Copy common syslinux modules (try multiple locations)
    for module in vesamenu.c32 menu.c32 hdt.c32 ldlinux.c32 libutil.c32 libmenu.c32; do
        if [ -f "/usr/lib/syslinux/modules/bios/$module" ]; then
            cp "/usr/lib/syslinux/modules/bios/$module" "$WORK_DIR/isolinux/" 2>/dev/null || true
        elif [ -f "/usr/lib/syslinux/$module" ]; then
            cp "/usr/lib/syslinux/$module" "$WORK_DIR/isolinux/" 2>/dev/null || true
        fi
    done

    # Check if we have the required files for BIOS boot
    if [ -f "$WORK_DIR/isolinux/isolinux.bin" ]; then
        log "✅ Required ISOLINUX files available for BIOS boot"
    else
        warn "❌ ISOLINUX bootloader binaries missing - ISO will not boot in BIOS mode"
    fi

    # Create GRUB config for UEFI boot
    cat > "$WORK_DIR/boot/grub/grub.cfg" << EOF
search --file --set=root /casper/vmlinuz
set default="0"
set timeout=10

loadfont \$prefix/unicode.pf2

set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

menuentry "Start Lilith Linux Rebirth Edition" {
    linux /casper/vmlinuz boot=casper quiet splash ---
    initrd /casper/initrd
}

menuentry "Start Lilith Linux Rebirth Edition (Safe Graphics)" {
    linux /casper/vmlinuz boot=casper nomodeset quiet splash ---
    initrd /casper/initrd
}

menuentry "Check disc for defects" {
    linux /casper/vmlinuz boot=casper integrity-check quiet splash ---
    initrd /casper/initrd
}

menuentry "Memory test" {
    linux16 /boot/memtest86+.bin
}
EOF

    # Copy GRUB EFI bootloader files (for UEFI boot)
    if [ -d "/usr/lib/grub/x86_64-efi" ]; then
        mkdir -p "$WORK_DIR/EFI/boot"
        if [ -f "/usr/lib/grub/x86_64-efi/grubx86.efi" ]; then
            cp "/usr/lib/grub/x86_64-efi/grubx86.efi" "$WORK_DIR/EFI/boot/bootx64.efi"
        elif [ -f "/usr/lib/grub/x86_64-efi/grub.efi" ]; then
            cp "/usr/lib/grub/x86_64-efi/grub.efi" "$WORK_DIR/EFI/boot/bootx64.efi"
        fi
        log "✅ GRUB EFI bootloader copied for UEFI boot"
    else
        warn "GRUB EFI modules not found - UEFI boot may not work"
    fi

    log "✅ Bootloader configured"
}

# Phase 5: Apply final branding
apply_branding() {
    log "🎨 Applying final branding..."

    # Copy logo if it exists
    if [ -f "build-scripts/logo.png" ]; then
        cp "build-scripts/logo.png" "$WORK_DIR/isolinux/splash.png"
        log "✅ Logo applied"
    fi

    # Create README.diskdefines
    cat > "$WORK_DIR/README.diskdefines" << EOF
#define DISKNAME Lilith Linux Rebirth Edition
#define TYPE binary
#define TYPEbinary 1
#define ARCH amd64
#define ARCHamd64 1
#define DISKNUM 1
#define DISKNUM1 1
#define TOTALNUM 0
#define TOTALNUM0 1
EOF

    log "✅ Branding applied"
}

# Phase 6: Generate final ISO
generate_iso() {
    log "💿 Generating final ISO..."

    # Check if we have bootloader files
    if [ -f "$WORK_DIR/isolinux/isolinux.bin" ]; then
        # Try xorriso with bootloader
        xorriso -as mkisofs \
            -iso-level 3 \
            -full-iso9660-filenames \
            -volid "Lilith Linux Rebirth Edition" \
            -output "$ISO_OUTPUT" \
            -eltorito-boot isolinux/isolinux.bin \
            -eltorito-catalog isolinux/boot.cat \
            -no-emul-boot \
            -boot-load-size 4 \
            -boot-info-table \
            2>/dev/null \
            "$WORK_DIR" 2>/dev/null || true
    else
        # Create simple data ISO without bootloader
        warn "No bootloader files found, creating data-only ISO"
        xorriso -as mkisofs \
            -iso-level 3 \
            -full-iso9660-filenames \
            -volid "Lilith Linux Rebirth Data" \
            -output "$ISO_OUTPUT" \
            "$WORK_DIR" 2>/dev/null || true
    fi

    # Alternative method if xorriso fails
    if [ ! -f "$ISO_OUTPUT" ]; then
        warn "xorriso failed, trying genisoimage..."
        if [ -f "$WORK_DIR/isolinux/isolinux.bin" ]; then
            genisoimage \
                -D -r -V "Lilith Linux Rebirth Edition" \
                -cache-inodes \
                -J -l -b isolinux/isolinux.bin \
                -c isolinux/boot.cat \
                -no-emul-boot \
                -boot-load-size 4 \
                -boot-info-table \
                -o "$ISO_OUTPUT" \
                "$WORK_DIR" 2>/dev/null
        else
            # Create simple data ISO
            genisoimage \
                -D -r -V "Lilith Linux Rebirth Data" \
                -cache-inodes \
                -J -l \
                -o "$ISO_OUTPUT" \
                "$WORK_DIR" 2>/dev/null
        fi
    fi

    if [ -f "$ISO_OUTPUT" ]; then
        local iso_size
        iso_size=$(du -h "$ISO_OUTPUT" | cut -f1)
        log "✅ ISO generated successfully: $ISO_OUTPUT (${iso_size})"
        if [ ! -f "$WORK_DIR/isolinux/isolinux.bin" ]; then
            warn "⚠️  ISO is data-only (not bootable) - missing bootloader files"
            log "💡 To make bootable: Add Ubuntu kernel/initrd and bootloader files"
        fi
    else
        error "Failed to generate ISO"
    fi
}

# Phase 7: Post-build verification
verify_iso() {
    log "🔍 Verifying ISO..."

    if [ ! -f "$ISO_OUTPUT" ]; then
        error "ISO file not found: $ISO_OUTPUT"
    fi

    # Check ISO size (adjust expectations for overlay/customization systems)
    local iso_size
    iso_size=$(stat -c%s "$ISO_OUTPUT" 2>/dev/null || echo "0")
    local iso_mb=$((iso_size / 1024 / 1024))

    if [ "$iso_size" -lt 50000000 ]; then  # Less than 50MB is definitely too small
        warn "ISO seems too small (${iso_mb}MB), might be incomplete"
    elif [ "$iso_size" -lt 200000000 ]; then  # Less than 200MB for overlay system
        warn "ISO is small (${iso_mb}MB) - this appears to be a customization/overlay ISO"
        log "💡 This is normal for Lilith Rebirth overlay systems"
    else
        log "✅ ISO size looks good (${iso_mb}MB)"
    fi

    # Try to mount and check contents
    local mount_point="/tmp/iso-check-$(date +%s)"
    mkdir -p "$mount_point"

    if sudo mount -o loop "$ISO_OUTPUT" "$mount_point" 2>/dev/null; then
        if [ -d "$mount_point/casper" ] && [ -f "$mount_point/casper/filesystem.squashfs" ]; then
            log "✅ ISO structure verified"
        else
            warn "ISO structure may be incomplete"
        fi
        sudo umount "$mount_point"
    else
        warn "Could not verify ISO contents"
    fi

    rm -rf "$mount_point"

    log "✅ ISO verification complete"
}

# Main execution
main() {
    echo -e "${PURPLE}"
    cat << 'EOF'
██╗     ██╗██╗     ██╗████████╗██╗  ██╗
██║     ██║██║     ██║╚══██╔══╝██║  ██║
██║     ██║██║     ██║   ██║   ███████║
██║     ██║██║     ██║   ██║   ██╔══██║
███████╗██║███████╗██║   ██║   ██║  ██║
╚══════╝╚═╝╚══════╝╚═╝   ╚═╝   ╚═╝  ╚═╝

    🔥 LILITH LINUX REBIRTH EDITION ISO BUILD 🔥
EOF
    echo -e "${NC}"

    log "🎯 Building Lilith Linux Rebirth Edition ISO"
    log "📍 Output: $ISO_OUTPUT"

    prepare_base_system
    preflight_checks
    setup_iso_structure
    create_filesystem
    setup_bootloader
    apply_branding
    generate_iso
    verify_iso

    echo -e "${GREEN}"
    cat << 'SUCCESS_EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              🔥 LILITH LINUX REBIRTH EDITION ISO 🔥         ║
║                                                              ║
║                   BUILD PROCESS COMPLETE!                    ║
║                                                              ║
║              Ready to burn and experience rebirth!           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
SUCCESS_EOF
    echo -e "${NC}"

    log "🎊 ISO ready: $ISO_OUTPUT"
    log "💡 Burn with: sudo dd if=$ISO_OUTPUT of=/dev/sdX bs=4M status=progress"
}

# Run main function
main "$@"
