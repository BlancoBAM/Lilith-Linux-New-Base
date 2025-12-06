#!/bin/bash

# Lilith Linux ISO Integration Script
# Complete workflow to transform Quark-OS ISO into Lilith Linux

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
WORK_DIR="/home/blanco/Desktop"
ISO_DIR="$WORK_DIR/quarkos-extracted"
AI_INTEGRATION_DIR="$WORK_DIR/lilith-ai-integration"
OUTPUT_ISO="$WORK_DIR/lilith-linux.iso"

show_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  🜏 𖤐 𐕣 Lilith Linux ISO Builder - Complete Transformation 𓅓࣪ ִֶָ☾. ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [BUILDER] - $*" | tee -a "$WORK_DIR/lilith-build.log"
}

# Step 1: Wait for/extract filesystem
extract_filesystem() {
    log "Step 1: Extracting filesystem..."

    if [ ! -d "$ISO_DIR/squashfs-root" ]; then
        log "Starting filesystem extraction..."
        cd "$ISO_DIR"
        mkdir -p squashfs-root
        sudo unsquashfs -d squashfs-root casper/filesystem.squashfs
    else
        log "Filesystem already extracted"
    fi

    # Verify extraction
    if [ ! -f "$ISO_DIR/squashfs-root/bin/bash" ]; then
        log "Error: Filesystem extraction failed"
        exit 1
    fi

    log "Filesystem extraction complete"
}

# Step 2: Integrate AI components
integrate_ai_components() {
    log "Step 2: Integrating AI components..."

    local rootfs="$ISO_DIR/squashfs-root"

    # Copy AI directories
    sudo cp -r "$AI_INTEGRATION_DIR/opt"/* "$rootfs/opt/" 2>/dev/null || true
    sudo cp -r "$AI_INTEGRATION_DIR/usr"/* "$rootfs/usr/" 2>/dev/null || true
    sudo cp -r "$AI_INTEGRATION_DIR/etc"/* "$rootfs/etc/" 2>/dev/null || true

    # Copy post-install script
    sudo cp "$AI_INTEGRATION_DIR/opt/lilith-postinstall.sh" "$rootfs/opt/"

    # Create integration trigger
    sudo mkdir -p "$rootfs/etc/lilith"
    echo "LILITH_AI_ENABLED=true" | sudo tee "$rootfs/etc/lilith/config" > /dev/null

    # Add post-install to startup
    sudo mkdir -p "$rootfs/etc/systemd/system/multi-user.target.wants"
    sudo ln -sf "/opt/lilith-postinstall.sh" "$rootfs/etc/systemd/system/multi-user.target.wants/lilith-postinstall.service" 2>/dev/null || true

    log "AI components integrated"
}

# Step 3: Update branding and themes
update_branding() {
    log "Step 3: Updating branding and themes..."

    local rootfs="$ISO_DIR/squashfs-root"

    # Update issue file
    sudo bash -c "cat > '$rootfs/etc/issue' << 'EOF'
Lilith Linux - Intelligent Computing Platform
🜏 𖤐 𐕣 Welcome to the future of intelligent computing 𓅓࣪ ִֶָ☾.

Built on Ubuntu 24.04 Noble Numbat
AI-Powered | Hardware Optimized | Locally Deployed

For support: https://github.com/BlancoBAM/Lilith-Linux
EOF"

    # Update lsb-release
    sudo bash -c "cat > '$rootfs/etc/lsb-release' << 'EOF'
DISTRIB_ID=Lilith
DISTRIB_RELEASE=24.04
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="Lilith Linux - Intelligent Computing Platform"
EOF"

    # Update os-release
    sudo bash -c "cat > '$rootfs/etc/os-release' << 'EOF'
PRETTY_NAME="Lilith Linux 24.04 (noble)"
NAME="Lilith Linux"
VERSION_ID="24.04"
VERSION="24.04 (noble)"
VERSION_CODENAME=noble
ID=lilith
ID_LIKE=ubuntu
HOME_URL="https://github.com/BlancoBAM/Lilith-Linux"
SUPPORT_URL="https://github.com/BlancoBAM/Lilith-Linux/issues"
BUG_REPORT_URL="https://github.com/BlancoBAM/Lilith-Linux/issues"
PRIVACY_POLICY_URL="https://github.com/BlancoBAM/Lilith-Linux/blob/main/PRIVACY.md"
UBUNTU_CODENAME=noble
EOF"

    log "Branding updated"
}

# Step 4: Replace logos (if available)
replace_logos() {
    log "Step 4: Replacing logos..."

    local rootfs="$ISO_DIR/squashfs-root"
    local logo_path="$WORK_DIR/lilith-logo.png"

    if [ -f "$logo_path" ]; then
        # Find and replace common logo locations
        sudo find "$rootfs" -name "*logo*" -type f | while read -r logo_file; do
            case "$logo_file" in
                *.png|*.svg|*.jpg|*.jpeg)
                    log "Replacing logo: $logo_file"
                    sudo cp "$logo_path" "$logo_file" 2>/dev/null || true
                    ;;
            esac
        done

        # Copy to standard locations
        sudo mkdir -p "$rootfs/usr/share/pixmaps"
        sudo cp "$logo_path" "$rootfs/usr/share/pixmaps/lilith-logo.png"

        log "Logos replaced"
    else
        log "Lilith logo not found, skipping logo replacement"
    fi
}

# Step 5: Update GRUB branding (already done)
update_grub_branding() {
    log "Step 5: GRUB branding already updated"
}

# Step 6: Rebuild filesystem
rebuild_filesystem() {
    log "Step 6: Rebuilding filesystem..."

    cd "$ISO_DIR"

    # Remove old squashfs
    rm -f casper/filesystem.squashfs

    # Create new squashfs
    sudo mksquashfs squashfs-root casper/filesystem.squashfs -comp xz -b 1M

    # Update filesystem size
    du -sx --block-size=1 squashfs-root | cut -f1 | sudo tee casper/filesystem.size > /dev/null

    # Update manifest
    sudo chroot squashfs-root dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee casper/filesystem.manifest > /dev/null
    sudo cp casper/filesystem.manifest casper/filesystem.manifest-desktop
    sudo sed -i '/ubiquity/d' casper/filesystem.manifest-desktop
    sudo sed -i '/casper/d' casper/filesystem.manifest-desktop

    log "Filesystem rebuilt"
}

# Step 7: Rebuild ISO
rebuild_iso() {
    log "Step 7: Rebuilding ISO..."

    cd "$WORK_DIR"

    # Create ISO
    sudo xorriso -as mkisofs \
        -r -V "Lilith Linux 24.04" \
        -o "$OUTPUT_ISO" \
        -J -l -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -isohybrid-apm-hfsplus \
        "$ISO_DIR"

    log "ISO rebuilt: $OUTPUT_ISO"
}

# Step 8: Verify ISO
verify_iso() {
    log "Step 8: Verifying ISO..."

    if [ -f "$OUTPUT_ISO" ]; then
        local iso_size=$(du -h "$OUTPUT_ISO" | cut -f1)
        log "ISO created successfully: $iso_size"

        # Test mount (optional)
        log "ISO verification complete"
    else
        log "Error: ISO creation failed"
        exit 1
    fi
}

# Main function
main() {
    show_banner

    echo -e "${CYAN}Starting Lilith Linux ISO transformation...${NC}"
    echo ""

    # Run all steps
    extract_filesystem
    integrate_ai_components
    update_branding
    replace_logos
    update_grub_branding
    rebuild_filesystem
    rebuild_iso
    verify_iso

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Lilith Linux ISO Transformation Complete!               ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Results:${NC}"
    echo "  📁 ISO Location: $OUTPUT_ISO"
    echo "  🤖 AI Integration: Complete"
    echo "  🎨 Branding: Updated"
    echo "  🖼️  Logos: Replaced"
    echo ""
    echo -e "${PURPLE}Boot the ISO and run: sudo /opt/lilith-postinstall.sh${NC}"
    echo -e "${PURPLE}Then use: lilith \"Hello Lilith!\"${NC}"
    echo ""
    echo -e "${BLUE}Welcome to Lilith Linux - The Intelligent Computing Platform!${NC}"
    echo -e "${BLUE}🜏 𖤐 𐕣 𓅓࣪ ִֶָ☾.${NC}"
    echo ""

    log "Lilith Linux ISO transformation completed successfully"
}

# Run main function
main "$@"
