#!/bin/bash
# 🔥 SIMPLE LILITH LINUX REBIRTH EDITION BUILD SCRIPT 🔥
# No complex here documents - just straightforward commands

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

log "🔥 Starting Lilith Linux Rebirth Edition Build..."

# Check if we're in the right directory
if [ ! -d "ai-bundle" ] || [ ! -d "ceremony" ]; then
    error "Please run this script from the rebirth-edition directory"
fi

# Embed AI bundle
log "🤖 Embedding AI bundle..."
mkdir -p lilith-system-root/opt/lilith/
cp ai-bundle/lilith_bundle.yaml lilith-system-root/opt/lilith/
log "✅ AI bundle embedded"

# Create first boot directory
log "🚀 Setting up first boot..."
sudo mkdir -p /opt/lilith-firstboot

# Copy ceremony script
sudo cp ceremony/rebirth-birthday.sh /opt/lilith-firstboot/
sudo chmod +x /opt/lilith-firstboot/rebirth-birthday.sh
log "✅ Ceremony script installed"

# Create post-install script (simple approach)
log "📦 Creating post-install script..."
sudo tee /opt/lilith-firstboot/lilith-post-install.sh > /dev/null << 'SIMPLE_EOF'
#!/bin/bash
echo "🔥 Lilith Post-Install Starting..."

# Simple bundle extraction
python3 -c "
import base64, yaml, os
from pathlib import Path

bundle_file = '/opt/lilith/lilith_bundle.yaml'
if os.path.exists(bundle_file):
    with open(bundle_file, 'r') as f:
        bundle = yaml.safe_load(f)

    for filename, content_b64 in bundle.get('files', {}).items():
        content = base64.b64decode(content_b64)
        filepath = Path('/opt/lilith') / filename
        with open(filepath, 'wb') as f:
            f.write(content)
        if filename.endswith(('.sh', '.py')):
            os.chmod(filepath, 0o755)
        print(f'Extracted: {filename}')

    os.remove(bundle_file)
    print('✅ Bundle extraction complete')
else:
    print('❌ Bundle file not found')
"

# Set up directories
sudo mkdir -p /opt/lilith/{services,scripts,config,knowledge-base,logs,training-data,run}
sudo chown -R lilith:lilith /opt/lilith 2>/dev/null || true

echo "✅ Post-install script created"
SIMPLE_EOF

sudo chmod +x /opt/lilith-firstboot/lilith-post-install.sh

# Add to rc.local
echo "
# Lilith first boot setup
if [ ! -f /var/lib/lilith-first-boot-completed ]; then
    /opt/lilith-firstboot/lilith-post-install.sh >> /var/log/lilith-first-boot.log 2>&1
    touch /var/lib/lilith-first-boot-completed
fi" | sudo tee -a /etc/rc.local > /dev/null

log "✅ First boot setup complete"

# Create users and services
log "👤 Setting up users and services..."

# Create queen user
if ! id "queen" &>/dev/null; then
    sudo useradd -m -s /bin/bash queen
    echo "queen:666" | sudo chpasswd
    sudo usermod -aG sudo,adm,dialout,cdrom,floppy,audio,dip,video,plugdev queen
    log "✅ Created user 'queen'"
fi

# Create lilith user
if ! id "lilith" &>/dev/null; then
    sudo useradd -m -s /bin/bash -d /opt/lilith lilith
    sudo usermod -aG dialout,audio,video lilith
    log "✅ Created user 'lilith'"
fi

# Set up SDDM autologin
if [ -f "/etc/sddm.conf" ]; then
    echo -e "\n[Autologin]\nUser=queen\nSession=plasma.desktop" | sudo tee -a /etc/sddm.conf > /dev/null
    log "✅ SDDM autologin configured"
fi

# Create ceremony service
sudo tee /etc/systemd/system/lilith-rebirth-ceremony.service > /dev/null << 'SERVICE_EOF'
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
SERVICE_EOF

sudo systemctl enable lilith-rebirth-ceremony.service
log "✅ Ceremony service configured"

# Apply hardware optimizations
log "🔧 Applying hardware optimizations..."

# CPU governor script
sudo tee /etc/init.d/lilith-cpu-tweaks > /dev/null << 'CPU_EOF'
#!/bin/bash
case "$1" in
    start)
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            echo "powersave" > "$cpu" 2>/dev/null || true
        done
        ;;
    stop)
        ;;
esac
CPU_EOF

sudo chmod +x /etc/init.d/lilith-cpu-tweaks
sudo update-rc.d lilith-cpu-tweaks defaults

# fstrim cron
sudo tee /etc/cron.weekly/lilith-fstrim > /dev/null << 'FSTRIM_EOF'
#!/bin/bash
fstrim -v /
FSTRIM_EOF

sudo chmod +x /etc/cron.weekly/lilith-fstrim

# Ananicy rules
sudo mkdir -p /etc/ananicy.d
sudo tee /etc/ananicy.d/lilith-ai.rules > /dev/null << 'ANANICY_EOF'
ollama nice=-10 ionice=2-2
llama.cpp nice=-5 ionice=2-2
python.*lilith.* nice=-8 ionice=2-2
chromadb nice=-3 ionice=3-3
ANANICY_EOF

log "✅ Hardware optimizations applied"

# Call main ISO build
log "💿 Building ISO..."
if [ -f "build-iso.sh" ]; then
    sudo ./build-iso.sh
    log "✅ ISO build completed!"
else
    log "⚠️  build-iso.sh not found - ISO build must be done manually"
fi

echo -e "${PURPLE}"
cat << 'SUCCESS_EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              🔥 LILITH LINUX REBIRTH EDITION 🔥             ║
║                                                              ║
║                   BUILD PROCESS COMPLETE!                    ║
║                                                              ║
║              Ready for rebirth ceremony on first boot        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
SUCCESS_EOF
echo -e "${NC}"

log "🎊 Lilith Linux Rebirth Edition build complete!"
