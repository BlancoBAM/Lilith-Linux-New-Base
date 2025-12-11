#!/bin/bash
# 🔥 LILITH LINUX REBIRTH EDITION - MASTER BUILD SCRIPT 🔥
# Self-contained "Rebirth Edition" ISO builder for Lilith Linux
# Ubuntu Noble base with integrated AI stack and rebirth ceremony

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR"
REPO_URL="https://github.com/BlancoBAM/Lilith-Base.git"
BRANCH="master"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
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

# Phase 1: Pre-flight checks
preflight_checks() {
    log "🔍 Performing pre-flight checks..."

    # Check if running as root (shouldn't be for this script)
    if [ "$EUID" -eq 0 ]; then
        error "Do not run this script as root. It will use sudo when needed."
    fi

    # Check required tools
    local required_tools=("git" "curl" "wget" "sudo")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "Required tool '$tool' not found. Please install it first."
        fi
    done

    # Check available disk space (need at least 20GB)
    local available_space
    available_space=$(df "$BUILD_DIR" | tail -1 | awk '{print int($4/1024/1024)}')
    if [ "$available_space" -lt 20 ]; then
        error "Need at least 20GB free space. Found: ${available_space}GB"
    fi

    # Check internet connectivity
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        error "Internet connection required for build process"
    fi

    log "✅ Pre-flight checks passed"
}

# Phase 2: SSH setup (optional)
setup_ssh() {
    info "🔐 SSH Setup Phase"

    read -p "Do you want to set up SSH keys for repository access? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ ! -f "$HOME/.ssh/id_rsa" ] || [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
            info "Generating SSH key..."
            ssh-keygen -t rsa -b 4096 -C "lilith-rebirth-build@local" -f "$HOME/.ssh/id_rsa" -N ""
            log "✅ SSH key generated"
            log "Public key (add to GitHub):"
            cat "$HOME/.ssh/id_rsa.pub"
            echo ""
            read -p "Press Enter after adding the key to GitHub..."
        else
            log "✅ SSH key already exists"
            log "If you have issues with GitHub access, ensure the key is added to:"
            log "https://github.com/settings/keys"
        fi

        # Test SSH connection to GitHub
        info "Testing SSH connection to GitHub..."
        if ssh -T git@github.com -o StrictHostKeyChecking=no -o ConnectTimeout=10 2>&1 | grep -q "successfully authenticated"; then
            log "✅ SSH authentication successful"
        else
            warn "SSH authentication test failed - you may need to add the key to GitHub"
        fi
    else
        warn "Skipping SSH setup - using HTTPS authentication"
    fi
}

# Phase 3: Repository sync and push
sync_repo() {
    log "📦 Repository Sync Phase"

    cd "$BUILD_DIR"

    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        info "Initializing git repository..."
        git init
        git remote add origin "$REPO_URL"
    fi

    # Fetch latest changes
    info "Fetching latest changes..."
    git fetch origin "$BRANCH" || warn "Could not fetch from remote (non-fatal)"

    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        info "Committing local changes..."
        git add -A
        git commit -m "Auto-commit: Rebirth Edition build preparation" || warn "No changes to commit"
    fi

    # Push changes (optional)
    read -p "Push changes to remote repository? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push origin "$BRANCH" || error "Failed to push to repository"
        log "✅ Changes pushed to repository"
    else
        warn "Skipping repository push"
    fi
}

# Phase 4: Embed AI bundle into build system
embed_ai_bundle() {
    log "🤖 Embedding AI Bundle"

    local bundle_src="$BUILD_DIR/ai-bundle/lilith_bundle.yaml"
    local bundle_dest="$BUILD_DIR/lilith-system-root/opt/lilith/lilith_bundle.yaml"

    if [ -f "$bundle_src" ]; then
        mkdir -p "$(dirname "$bundle_dest")"
        cp "$bundle_src" "$bundle_dest"
        log "✅ AI bundle embedded at: $bundle_dest"
    else
        error "AI bundle not found at: $bundle_src"
    fi
}

# Phase 5: Apply hardware optimizations
apply_hardware_tweaks() {
    log "🔧 Applying Hardware Optimizations"

    # ZRAM configuration (already in build scripts)
    log "✅ ZRAM optimizations already configured"

    # CPU governor (powersave for low-power laptop)
    sudo tee /etc/init.d/lilith-cpu-tweaks > /dev/null << 'EOF'
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

    sudo chmod +x /etc/init.d/lilith-cpu-tweaks
    sudo update-rc.d lilith-cpu-tweaks defaults

    # fstrim weekly cron
    sudo tee /etc/cron.weekly/lilith-fstrim > /dev/null << 'EOF'
#!/bin/bash
# Weekly fstrim for NVMe optimization
fstrim -v /
EOF
    sudo chmod +x /etc/cron.weekly/lilith-fstrim

    # Ananicy rules for AI processes
    sudo mkdir -p /etc/ananicy.d
    sudo tee /etc/ananicy.d/lilith-ai.rules > /dev/null << 'EOF'
# AI Process Priority Rules
ollama nice=-10 ionice=2-2
llama.cpp nice=-5 ionice=2-2
python.*lilith.* nice=-8 ionice=2-2
chromadb nice=-3 ionice=3-3
EOF

    log "✅ Hardware optimizations applied"
}

# Phase 6: Create user and services
setup_users_and_services() {
    log "👤 Setting up Users and Services"

    # Create queen user
    if ! id "queen" &>/dev/null; then
        sudo useradd -m -s /bin/bash queen
        echo "queen:666" | sudo chpasswd
        sudo usermod -aG sudo,adm,dialout,cdrom,floppy,audio,dip,video,plugdev queen
        log "✅ Created user 'queen' with password '666'"
    else
        log "✅ User 'queen' already exists"
    fi

    # Create lilith user for AI services
    if ! id "lilith" &>/dev/null; then
        sudo useradd -m -s /bin/bash -d /opt/lilith lilith
        sudo usermod -aG dialout,audio,video lilith
        log "✅ Created user 'lilith' for AI services"
    else
        log "✅ User 'lilith' already exists"
    fi

    # Set up systemd services
    log "🔧 Configuring systemd services..."

    # SDDM autologin for queen
    if [ -f "/etc/sddm.conf" ]; then
        sudo tee -a /etc/sddm.conf > /dev/null << EOF

[Autologin]
User=queen
Session=plasma.desktop
EOF
        log "✅ SDDM autologin configured for queen"
    fi

    # One-shot rebirth ceremony service
    sudo tee /etc/systemd/system/lilith-rebirth-ceremony.service > /dev/null << EOF
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

    sudo systemctl enable lilith-rebirth-ceremony.service
    log "✅ Rebirth ceremony service configured"
}

# Phase 7: Set up first boot integration
setup_first_boot() {
    log "🚀 Setting up First Boot Integration"

    # Create first boot directory
    sudo mkdir -p /opt/lilith-firstboot

    # Copy rebirth ceremony script
    local ceremony_src="$BUILD_DIR/build-system/sources/scripts/ai-integration/rebirth-birthday.sh"
    if [ -f "$ceremony_src" ]; then
        sudo cp "$ceremony_src" /opt/lilith-firstboot/
        sudo chmod +x /opt/lilith-firstboot/rebirth-birthday.sh
        log "✅ Rebirth ceremony script installed"
    fi

    # Create lilith-post-install.sh for first boot
    sudo tee /opt/lilith-firstboot/lilith-post-install.sh > /dev/null << "EOF"
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

# Install dependencies
apt update
apt install -y python3 python3-pip python3-venv curl tesseract-ocr ffmpeg glslviewer

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
for dirname in ['services', 'scripts', 'config', 'knowledge-base', 'logs', 'training-data']:
    Path(f'$EXTRACT_DIR/{dirname}').mkdir(parents=True, exist_ok=True)

# Extract files
for filename, content_b64 in bundle['files'].items():
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

# Create lilith user home if needed
if [ ! -d "/opt/lilith" ]; then
    mkdir -p /opt/lilith
    chown lilith:lilith /opt/lilith
fi

# Set up AI directories
mkdir -p /opt/lilith/{services,scripts,config,knowledge-base,logs,training-data,run}
chown -R lilith:lilith /opt/lilith

# Download Phi-3 Mini model
log "📥 Downloading Phi-3 Mini model..."
sudo -u lilith ollama pull phi3:mini

# Enable services
systemctl enable lilith-daemon.service 2>/dev/null || true

# Set up hotkey (Super+Space)
log "🔥 Setting up hotkey (Super+Space)..."
sudo -u queen mkdir -p /home/queen/.config/sxhkd
cat << 'EOF' | sudo -u queen tee /home/queen/.config/sxhkd/sxhkdrc > /dev/null
super + space
    /opt/lilith/scripts/summon-assistant.sh
EOF
sudo chown queen:queen /home/queen/.config/sxhkd/sxhkdrc 2>/dev/null || log "Note: File ownership may already be correct"

# Clean up
rm -f "$BUNDLE_FILE"
log "✅ Post-install complete! AI system ready."
EOF

    sudo chmod +x /opt/lilith-firstboot/lilith-post-install.sh

    # Add to rc.local for first boot execution
    sudo tee -a /etc/rc.local > /dev/null << 'EOF'

# Lilith first boot setup
if [ ! -f /var/lib/lilith-first-boot-completed ]; then
    /opt/lilith-firstboot/lilith-post-install.sh >> /var/log/lilith-first-boot.log 2>&1
    touch /var/lib/lilith-first-boot-completed
fi
EOF

    log "✅ First boot integration configured"
}

# Phase 8: Call the main ISO build script
build_iso() {
    log "💿 Building ISO"

    # Check if build-iso.sh exists
    local build_script="$BUILD_DIR/build-iso.sh"
    if [ -f "$build_script" ]; then
        log "Calling ISO build script..."
        sudo "$build_script"
    else
        warn "build-iso.sh not found. ISO build must be done manually."
        warn "Expected location: $build_script"
    fi
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

    🔥 REBIRTH EDITION MASTER BUILD 🔥
EOF
    echo -e "${NC}"

    preflight_checks
    setup_ssh
    sync_repo
    embed_ai_bundle
    apply_hardware_tweaks
    setup_users_and_services
    setup_first_boot
    build_iso

    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              🔥 LILITH LINUX REBIRTH EDITION 🔥             ║
║                                                              ║
║                   BUILD PROCESS COMPLETE!                    ║
║                                                              ║
║              Ready for rebirth ceremony on first boot        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    log "🎊 Build complete! Burn ISO and experience the rebirth ceremony!"
}

# Run main function
main "$@"
