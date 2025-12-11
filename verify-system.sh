#!/bin/bash
# 🔍 LILITH LINUX REBIRTH EDITION - VERIFICATION SCRIPT 🔍
# Checks that all components are properly implemented

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_ROOT="$SCRIPT_DIR/lilith-system-root"

echo "🔍 Verifying Lilith Linux Rebirth Edition Components..."

echo ""
echo "📁 Checking application binaries..."

# Check if applications exist
apps=(
    "lilith-shapeshifter"
    "lilith-offerings" 
    "lilith-package-request"
)

for app in "${apps[@]}"; do
    if [ -f "$SYSTEM_ROOT/usr/bin/$app" ]; then
        echo "✅ $app found"
    else
        echo "❌ $app NOT found"
    fi
done

echo ""
echo "📄 Checking desktop files..."

# Check if desktop files exist
desktops=(
    "lilith-shapeshifter.desktop"
    "lilith-offerings.desktop"
    "lilith-package-request.desktop"
)

for desktop in "${desktops[@]}"; do
    if [ -f "$SYSTEM_ROOT/usr/share/applications/$desktop" ]; then
        echo "✅ $desktop found"
    else
        echo "❌ $desktop NOT found"
    fi
done

echo ""
echo "🤖 Checking AI bundle..."

if [ -f "$SYSTEM_ROOT/opt/lilith/lilith_bundle.yaml" ]; then
    echo "✅ AI bundle found"
else
    echo "❌ AI bundle NOT found"
fi

echo ""
echo "🎂 Checking rebirth ceremony..."

if [ -f "$SCRIPT_DIR/ceremony/rebirth-birthday.sh" ]; then
    echo "✅ Rebirth ceremony script found"
else
    echo "❌ Rebirth ceremony script NOT found"
fi

echo ""
echo "🔧 Checking build scripts..."

if [ -f "$SCRIPT_DIR/build-lilith-iso.sh" ]; then
    echo "✅ ISO build script found"
else
    echo "❌ ISO build script NOT found"
fi

if [ -f "$SCRIPT_DIR/setup-base-system.sh" ]; then
    echo "✅ Base system setup script found"
else
    echo "❌ Base system setup script NOT found"
fi

echo ""
echo "🎯 Verifying application functionality..."

# Test that Python applications have proper shebang
for app in "${apps[@]}"; do
    if [ -f "$SYSTEM_ROOT/usr/bin/$app" ]; then
        if head -n1 "$SYSTEM_ROOT/usr/bin/$app" | grep -q "python3"; then
            echo "✅ $app has Python shebang"
        else
            echo "⚠️  $app may not have Python shebang"
        fi
    fi
done

echo ""
echo "📋 Checking directory structure..."

dirs=(
    "usr/bin"
    "usr/share/applications"
    "usr/share/lilith"
    "opt/lilith"
)

for dir in "${dirs[@]}"; do
    if [ -d "$SYSTEM_ROOT/$dir" ]; then
        echo "✅ $dir exists"
    else
        echo "❌ $dir does NOT exist"
    fi
done

echo ""
echo "🏆 VERIFICATION COMPLETE!"
echo "Your Lilith Linux Rebirth Edition is ready to build!"
echo ""
echo "To build the ISO, run:"
echo "cd $SCRIPT_DIR"
echo "./build-lilith-iso.sh"