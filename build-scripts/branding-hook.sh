#!/bin/bash
# Lilith Linux Identity Engine
# Replaces upstream branding (Ubuntu/Kubuntu) with Lilith Linux Identity
# Source Level Integration

set -e
LOGO_SOURCE="$(dirname "$0")/logo.png"
CHROOT_DIR="${1:-/home/blanco/lilith-distro-build/iso-build/chroot}"

echo "🔥 initializing Lilith Identity Engine..."

if [ ! -f "$LOGO_SOURCE" ]; then
    echo "❌ Logo not found at $LOGO_SOURCE"
    exit 1
fi

# 1. System Release Branding
echo "📝 Rewriting OS Release Identity..."
sed -i 's/Ubuntu/Lilith Linux/g' "$CHROOT_DIR/etc/os-release" 2>/dev/null || true
sed -i 's/Kubuntu/Lilith Linux/g' "$CHROOT_DIR/etc/os-release" 2>/dev/null || true
echo "PRETTY_NAME=\"Lilith Linux 1.0 (Rebirth Edition)\"" >> "$CHROOT_DIR/etc/os-release"

# 2. Rebranding Main Configurations
# Update LSB Release
cat <<EOF > "$CHROOT_DIR/etc/lsb-release"
DISTRIB_ID=Lilith
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=rebirth
DISTRIB_DESCRIPTION="Lilith Linux Rebirth Edition"
EOF

# 3. Logo Replacement (Plymouth & Icons)
echo "🎨 Injecting Lilith Logos..."
# Common logo locations - we replace generic start-here icons
find "$CHROOT_DIR/usr/share/icons" -name "start-here*" -exec cp "$LOGO_SOURCE" {} \;
find "$CHROOT_DIR/usr/share/icons" -name "distributor-logo*" -exec cp "$LOGO_SOURCE" {} \;
find "$CHROOT_DIR/usr/share/icons" -name "ubuntu-logo*" -exec cp "$LOGO_SOURCE" {} \;

# Install optimized logo to system
mkdir -p "$CHROOT_DIR/usr/share/lilith/"
cp "$LOGO_SOURCE" "$CHROOT_DIR/usr/share/lilith/logo.png"

# 4. GRUB Branding
echo "🛑 Customizing GRUB..."
sed -i 's/GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="Lilith Linux"/g' "$CHROOT_DIR/etc/default/grub" 2>/dev/null || true

# 5. "Request Official Package" Feature
echo "📦 Installing 'Request Package' Context Hook..."
mkdir -p "$CHROOT_DIR/usr/share/kservices5/ServiceMenus/"

cat << 'EOF' > "$CHROOT_DIR/usr/share/kservices5/ServiceMenus/lilith-request-package.desktop"
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=application/x-executable;application/x-sharedlib;application/vnd.appimage;
Actions=RequestOfficial;
X-KDE-Submenu=Lilith Linux

[Desktop Action RequestOfficial]
Name=Request Official Lilith Package
Icon=list-add
Exec=lilith-package-request %u
EOF

# Create the binary for the request (Python script)
cat << 'EOF' > "$CHROOT_DIR/usr/bin/lilith-package-request"
#!/usr/bin/env python3
import sys
import webbrowser
import urllib.parse
from PyQt6.QtWidgets import QApplication, QMessageBox

def main():
    app = QApplication(sys.argv)
    
    target = sys.argv[1] if len(sys.argv) > 1 else "Unknown App"
    filename = target.split('/')[-1]
    
    # Construct GitHub Issue URL
    base_url = "https://github.com/Lilith-Linux/packages/issues/new"
    title = f"Request Official Package: {filename}"
    body = f"""**Package Request**
    
    I would like to request that '{filename}' be made into an official, optimized Lilith Linux package.
    
    **Type:** App/Binary
    **Path:** {target}
    **Reason:** [Enter reason here]
    """
    
    params = {
        "title": title,
        "body": body,
        "labels": "package-request"
    }
    
    query = urllib.parse.urlencode(params)
    full_url = f"{base_url}?{query}"
    
    msg = QMessageBox()
    msg.setIcon(QMessageBox.Icon.Question)
    msg.setText(f"Request Official Package for {filename}?")
    msg.setInformativeText("This will open a GitHub issue template in your browser.")
    msg.setWindowTitle("Lilith Package Bazaar")
    msg.setStandardButtons(QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No)
    
    if msg.exec() == QMessageBox.StandardButton.Yes:
        print(f"Opening: {full_url}")
        webbrowser.open(full_url)

if __name__ == "__main__":
    main()
EOF
chmod +x "$CHROOT_DIR/usr/bin/lilith-package-request"

echo "✅ Identity Engine Applied Successfully."
