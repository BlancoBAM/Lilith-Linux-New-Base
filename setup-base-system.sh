#!/bin/bash
# Setup script to create a base Ubuntu system in lilith-system-root

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_ROOT="$SCRIPT_DIR/lilith-system-root"
TEMP_MOUNT="/tmp/lilith-bind-mounts"
REQUIRED_TOOLS=("debootstrap" "squashfs-tools" "xorriso" "syslinux-common" "grub-pc-bin" "grub-efi-amd64-bin")

log "Setting up base Ubuntu system for Lilith Linux Rebirth Edition..."

# Phase 1: Pre-flight checks
log "🔍 Performing pre-flight checks..."

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    error "This script must be run with sudo privileges"
fi

# Check for required tools
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        warn "Required tool '$tool' not found. Installing..."
        apt update
        apt install -y "$tool"
    fi
done

# Check if system root is empty (just the opt directory from AI bundle)
if [ -d "$SYSTEM_ROOT" ] && [ -z "$(ls -A "$SYSTEM_ROOT" 2>/dev/null | grep -v opt)" ]; then
    warn "System root exists but appears to be empty (except for AI bundle)"
fi

# Phase 2: Install base Ubuntu system using debootstrap
log "📦 Installing base Ubuntu Noble system..."

# Create system root if it doesn't exist
mkdir -p "$SYSTEM_ROOT"

# Check if system root already has content
if [ -d "$SYSTEM_ROOT/bin" ] && [ -d "$SYSTEM_ROOT/usr" ] && [ -d "$SYSTEM_ROOT/lib" ]; then
    log "✅ Base system already appears to be present"
else
    log "Installing Ubuntu Noble base system..."
    
    # Determine architecture
    ARCH=$(dpkg --print-architecture)
    
    # Install base system
    debootstrap --arch="$ARCH" noble "$SYSTEM_ROOT" http://archive.ubuntu.com/ubuntu/
    
    log "✅ Base Ubuntu system installed"
fi

# Phase 3: Basic system configuration
log "⚙️  Configuring basic system..."

# Create necessary directories that bind mounts will use during chroot
mkdir -p "$SYSTEM_ROOT"/{dev,proc,sys,run,tmp}

# Create fstab (minimal)
cat > "$SYSTEM_ROOT/etc/fstab" << 'EOF'
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a device; this may
# be used with UUID= as a more robust way to name devices that works even if
# disks are added and removed. See fstab(5).
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
/dev/root / ext4 defaults 0 1
EOF

# Set hostname
echo "lilith-rebirth" > "$SYSTEM_ROOT/etc/hostname"

# Set hosts file
cat > "$SYSTEM_ROOT/etc/hosts" << 'EOF'
127.0.0.1	localhost
127.0.1.1	lilith-rebirth

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# Create sources.list for Ubuntu Noble
cat > "$SYSTEM_ROOT/etc/apt/sources.list" << 'EOF'
# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://archive.ubuntu.com/ubuntu/ noble main restricted
deb-src http://archive.ubuntu.com/ubuntu/ noble main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted
deb-src http://archive.ubuntu.com/ubuntu/ noble-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT be released
## with Ubuntu 18.04, but may be released for later Ubuntu releases.
deb http://archive.ubuntu.com/ubuntu/ noble universe
deb-src http://archive.ubuntu.com/ubuntu/ noble universe
deb http://archive.ubuntu.com/ubuntu/ noble-updates universe
deb-src http://archive.ubuntu.com/ubuntu/ noble-updates universe

deb http://archive.ubuntu.com/ubuntu/ noble multiverse
deb-src http://archive.ubuntu.com/ubuntu/ noble multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates multiverse
deb-src http://archive.ubuntu.com/ubuntu/ noble-updates multiverse

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT be published
## for Ubuntu 18.04 (though it may be published for later Ubuntu releases).
deb http://archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse

## Uncomment the following two lines to add software from Canonical's
## 'partner' repository.
## This software is not part of Ubuntu, but is offered by Canonical and the
## respective vendors as a service to Ubuntu users.
# deb http://archive.canonical.com/ubuntu bionic partner
# deb-src http://archive.canonical.com/ubuntu bionic partner

deb http://security.ubuntu.com/ubuntu/ noble-security main restricted
deb-src http://security.ubuntu.com/ubuntu/ noble-security main restricted
deb http://security.ubuntu.com/ubuntu/ noble-security universe
deb-src http://security.ubuntu.com/ubuntu/ noble-security universe
deb http://security.ubuntu.com/ubuntu/ noble-security multiverse
deb-src http://security.ubuntu.com/ubuntu/ noble-security multiverse
EOF

log "✅ Basic system configuration complete"

# Phase 4: Install basic packages needed for the Rebirth Edition
log "📦 Installing essential packages..."

# Mount necessary filesystems for chroot
mkdir -p "$TEMP_MOUNT"
mount --bind /dev "$SYSTEM_ROOT/dev"
mount --bind /proc "$SYSTEM_ROOT/proc" 
mount --bind /sys "$SYSTEM_ROOT/sys"
mount --bind /tmp "$SYSTEM_ROOT/tmp"

# Install essential packages in chroot
chroot "$SYSTEM_ROOT" apt update

# Install packages for a minimal KDE environment with necessary components
chroot "$SYSTEM_ROOT" apt install -y \
    linux-generic \
    casper \
    lupin-casper \
    ubuntu-standard \
    ubiquity-frontend-gtk \
    os-prober \
    laptop-detect \
    acpid \
    user-setup \
    sudo \
    plymouth-theme-spinner \
    sddm \
    plasma-workspace \
    plasma-workspace-wayland \
    sddm-theme-breeze \
    breeze-cursor-theme \
    breeze-icon-theme \
    fonts-noto* \
    fonts-liberation \
    fonts-ubuntu \
    openssh-server \
    curl \
    wget \
    git \
    python3 \
    python3-yaml \
    python3-pip \
    tesseract-ocr \
    ffmpeg \
    glslviewer \
    ollama \
    zram-tools \
    ananicy \
    f2fs-tools

# Install additional packages that are typical for AI workloads and customization
chroot "$SYSTEM_ROOT" apt install -y \
    htop \
    vim \
    nano \
    build-essential \
    software-properties-common \
    unattended-upgrades \
    needrestart \
    python3-venv \
    pipx \
    flatpak \
    appmenu-qt5

# Install custom branding
chroot "$SYSTEM_ROOT" mkdir -p /usr/share/lilith/

# Copy the official logo to the system first
if [ -f "/home/blanco/logo.png" ]; then
    cp "/home/blanco/logo.png" "$SYSTEM_ROOT/usr/share/lilith/logo.png"
    # Also copy to the build-scripts directory temporarily so the branding hook can find it
    mkdir -p "$SYSTEM_ROOT/tmp/branding-tmp"
    cp "/home/blanco/logo.png" "$SYSTEM_ROOT/tmp/branding-tmp/logo.png"
    # Update the branding hook script to look for logo in the right location within chroot
    cp "$SCRIPT_DIR/build-scripts/branding-hook.sh" "$SYSTEM_ROOT/tmp/branding-hook.sh"
    sed -i "s|LOGO_SOURCE=\"\$(dirname \"\$0\")/logo.png\"|LOGO_SOURCE=\"/tmp/branding-tmp/logo.png\"|" "$SYSTEM_ROOT/tmp/branding-hook.sh"
    chroot "$SYSTEM_ROOT" /bin/bash /tmp/branding-hook.sh
    rm -rf "$SYSTEM_ROOT/tmp/branding-tmp" "$SYSTEM_ROOT/tmp/branding-hook.sh"
else
    info "Official logo not found at /home/blanco/logo.png, applying basic branding..."
    # Apply basic branding
    cat > "$SYSTEM_ROOT/etc/os-release" << 'EOF'
NAME="Lilith Linux"
VERSION="1.0 (Rebirth Edition)"
ID=lilith
ID_LIKE=ubuntu
PRETTY_NAME="Lilith Linux 1.0 (Rebirth Edition)"
VERSION_ID="1.0"
HOME_URL="https://github.com/BlancoBAM/Lilith-Base"
SUPPORT_URL="https://github.com/BlancoBAM/Lilith-Base/issues"
BUG_REPORT_URL="https://github.com/BlancoBAM/Lilith-Base/issues"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=noble
UBUNTU_CODENAME=noble
EOF
fi

# Copy the AI bundle to the system
mkdir -p "$SYSTEM_ROOT/opt/lilith"
cp -r "$SCRIPT_DIR/ai-bundle/lilith_bundle.yaml" "$SYSTEM_ROOT/opt/lilith/" 2>/dev/null || true

# Create users and services inside the chroot
info "Creating users in chroot..."

# Create queen user
chroot "$SYSTEM_ROOT" useradd -m -s /bin/bash queen
chroot "$SYSTEM_ROOT" /bin/bash -c "echo 'queen:666' | chpasswd"
chroot "$SYSTEM_ROOT" usermod -aG sudo,adm,dialout,cdrom,floppy,audio,dip,video,plugdev queen

# Create lilith user for AI services
chroot "$SYSTEM_ROOT" useradd -m -s /bin/bash -d /opt/lilith lilith
chroot "$SYSTEM_ROOT" usermod -aG dialout,audio,video lilith

# Set up SDDM autologin for queen
if [ -f "$SYSTEM_ROOT/etc/sddm.conf" ]; then
    cat >> "$SYSTEM_ROOT/etc/sddm.conf" << 'EOF'

[Autologin]
User=queen
Session=plasma.desktop
EOF
    else
    # Create sddm.conf if it doesn't exist
    mkdir -p "$SYSTEM_ROOT/etc"
    cat > "$SYSTEM_ROOT/etc/sddm.conf" << 'EOF'
[Autologin]
User=queen
Session=plasma.desktop

[X11]
DisplayCommand=/usr/share/sddm/scripts/Xsetup
DisplayStopCommand=/usr/share/sddm/scripts/Xstop
# The following three values are in seconds
ServerTimeout=30
SessionTimeout=30
RestartServices=true
EOF
fi

# Create ceremony service
mkdir -p "$SYSTEM_ROOT/etc/systemd/system"
cat > "$SYSTEM_ROOT/etc/systemd/system/lilith-rebirth-ceremony.service" << 'EOF'
[Unit]
Description=Lilith Rebirth Ceremony (One-shot)
After=graphical.target
ConditionPathExists=!/home/queen/.lilith-rebirth-completed

[Service]
Type=oneshot
User=queen
Environment=DISPLAY=:0
ExecStart=/opt/lilith-firstboot/rebirth-birthday.sh
RemainAfterExit=no

[Install]
WantedBy=graphical.target
EOF

# Enable the service
chroot "$SYSTEM_ROOT" systemctl enable lilith-rebirth-ceremony.service

# Set up hardware optimizations in chroot
info "Setting up hardware optimizations..."

# CPU governor script
cat > "$SYSTEM_ROOT/etc/init.d/lilith-cpu-tweaks" << 'EOF'
#!/bin/bash
### BEGIN INIT INFO
# Provides:          lilith-cpu-tweaks
# Required-Start:    $all
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Lilith CPU optimizations
### END INIT INFO

case "$1" in
    start)
        echo "Applying Lilith CPU optimizations..."
        # Set CPU governor to powersave for i3-11xx
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            echo "powersave" > "$cpu" 2>/dev/null || true
        done
        echo "CPU governor set to powersave"
        ;;
    stop)
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
EOF

chroot "$SYSTEM_ROOT" chmod +x /etc/init.d/lilith-cpu-tweaks
chroot "$SYSTEM_ROOT" update-rc.d lilith-cpu-tweaks defaults

# fstrim weekly cron
cat > "$SYSTEM_ROOT/etc/cron.weekly/lilith-fstrim" << 'EOF'
#!/bin/bash
# Weekly fstrim for NVMe optimization
fstrim -v /
EOF
chroot "$SYSTEM_ROOT" chmod +x /etc/cron.weekly/lilith-fstrim

# Ananicy rules for AI processes
mkdir -p "$SYSTEM_ROOT/etc/ananicy.d"
cat > "$SYSTEM_ROOT/etc/ananicy.d/lilith-ai.rules" << 'EOF'
# AI Process Priority Rules
ollama nice=-10 ionice=2-2
llama.cpp nice=-5 ionice=2-2
python.*lilith.* nice=-8 ionice=2-2
chromadb nice=-3 ionice=3-3
EOF

# Set up first boot integration
mkdir -p "$SYSTEM_ROOT/opt/lilith-firstboot"

# Copy ceremony script
cp "$SCRIPT_DIR/ceremony/rebirth-birthday.sh" "$SYSTEM_ROOT/opt/lilith-firstboot/"
chmod +x "$SYSTEM_ROOT/opt/lilith-firstboot/rebirth-birthday.sh"

info "Setting up first boot script..."

# Create post-install script
cat > "$SYSTEM_ROOT/opt/lilith-firstboot/lilith-post-install.sh" << 'POST_INSTALL_EOF'
#!/bin/bash
# Lilith Post-Install Script - Runs on first boot

set -e

BUNDLE_FILE="/opt/lilith/lilith_bundle.yaml"
EXTRACT_DIR="/opt/lilith"

log() {
    echo "[$(date +'%H:%M:%S')] $1"
}

log "🔥 Lilith Post-Install: Extracting AI Bundle..."

# Check if bundle exists
if [ ! -f "$BUNDLE_FILE" ]; then
    log "❌ AI bundle not found at: $BUNDLE_FILE"
    exit 1
fi

# Install dependencies if needed
apt update 2>/dev/null
apt install -y python3 python3-pip curl tesseract-ocr ffmpeg glslviewer 2>/dev/null || true

# Extract bundle using Python
python3 -c "
import base64
import yaml
import os
from pathlib import Path

# Load bundle
with open('$BUNDLE_FILE', 'r') as f:
    bundle = yaml.safe_load(f)

# Create directories
for dirname in ['services', 'scripts', 'config', 'knowledge-base', 'logs', 'training-data', 'run']:
    Path(f'$EXTRACT_DIR/{dirname}').mkdir(parents=True, exist_ok=True)

# Extract files
for filename, content_b64 in bundle.get('files', {}).items():
    content = base64.b64decode(content_b64)
    filepath = Path('$EXTRACT_DIR') / filename

    with open(filepath, 'wb') as f:
        f.write(content)

    # Make scripts executable
    if filename.endswith('.sh') or filename.endswith('.py'):
        os.chmod(filepath, 0o755)

    print(f'Extracted: {filename}')

print('✅ Bundle extraction complete')
"

# Set up AI directories
mkdir -p /opt/lilith/{services,scripts,config,knowledge-base,logs,training-data,run}
chown -R lilith:lilith /opt/lilith 2>/dev/null || true

# Download Phi-3 Mini model
log "📥 Downloading Phi-3 Mini model..."
sudo -u lilith ollama pull phi3:mini 2>/dev/null || log "Note: Ollama not available or model download failed"

# Enable services
systemctl enable lilith-daemon.service 2>/dev/null || log "Note: Lilit daemon service not found"

# Set up hotkey (Super+Space)
log "🔥 Setting up hotkey (Super+Space)..."
sudo -u queen mkdir -p /home/queen/.config/sxhkd
cat << 'SXHKD_EOF' | sudo -u queen tee /home/queen/.config/sxhkd/sxhkdrc > /dev/null
super + space
    /opt/lilith/scripts/summon-assistant.sh
SXHKD_EOF
chown queen:queen /home/queen/.config/sxhkd/sxhkdrc 2>/dev/null || echo "Note: File ownership may already be correct"

# Clean up
rm -f "$BUNDLE_FILE"
log "✅ Post-install complete! AI system ready."
"

POST_INSTALL_EOF

chmod +x "$SYSTEM_ROOT/opt/lilith-firstboot/lilith-post-install.sh"

# Add to rc.local for first boot execution
sed -i '/exit 0/d' "$SYSTEM_ROOT/etc/rc.local" 2>/dev/null || true
cat >> "$SYSTEM_ROOT/etc/rc.local" << 'RC_EOF'

# Lilith first boot setup
if [ ! -f /var/lib/lilith-first-boot-completed ]; then
    /opt/lilith-firstboot/lilith-post-install.sh >> /var/log/lilith-first-boot.log 2>&1
    touch /var/lib/lilith-first-boot-completed
fi

exit 0
RC_EOF

log "✅ Essential packages and configurations installed"

# Phase 5: Unmount and finish
umount "$SYSTEM_ROOT/dev" || true
umount "$SYSTEM_ROOT/proc" || true
umount "$SYSTEM_ROOT/sys" || true
umount "$SYSTEM_ROOT/tmp" || true
rmdir "$TEMP_MOUNT" || true

log "🎉 Base Ubuntu system setup complete!"
log "   The lilith-system-root directory now contains a full Ubuntu Noble system"
log "   You can now run the ISO build script: sudo ./build-lilith-iso.sh"

echo -e "${GREEN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              🔥 BASE SYSTEM SETUP COMPLETE 🔥               ║
║                                                              ║
║        lilith-system-root now contains Ubuntu Noble         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"