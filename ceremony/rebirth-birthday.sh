#!/bin/bash
# 🔥 Lilith Rebirth Ceremony - December 9th Special Edition 🔥
# Demonic celebration with burning text animation and video recording

set -e

# Configuration
CEREMONY_DATE="December 9th"
VIDEO_OUTPUT="$HOME/Videos/Lilith-Rebirth-Ceremony-$(date +%Y-%m-%d).mp4"
LOGO_FILE="/usr/share/lilith/logo.png"
BURN_SHADER="/opt/lilith/lilith-burn.glsl"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Demonic ASCII art
show_demonic_banner() {
    echo -e "${RED}"
    cat << 'EOF'
██╗     ██╗██╗     ██╗████████╗██╗  ██╗
██║     ██║██║     ██║╚══██╔══╝██║  ██║
██║     ██║██║     ██║   ██║   ███████║
██║     ██║██║     ██║   ██║   ██╔══██║
███████╗██║███████╗██║   ██║   ██║  ██║
╚══════╝╚═╝╚══════╝╚═╝   ╚═╝   ╚═╝  ╚═╝
EOF
    echo -e "${NC}"
}

# Happy Rebirth message
show_rebirth_message() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║                🌟 HAPPY REBIRTH, QUEEN! 🌟                  ║"
    echo "║                                                              ║"
    echo "║              Welcome to Lilith Linux Rebirth Edition         ║"
    echo "║                                                              ║"
    echo "║                 $CEREMONY_DATE Special Release                 ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Burning text animation function
burn_text_animation() {
    local text="$1"
    local duration="$2"

    echo -e "${YELLOW}🔥 Burning text animation: $text${NC}"

    # Use glslviewer if available, otherwise fallback to simple animation
    if command -v glslviewer &> /dev/null && [ -f "$BURN_SHADER" ]; then
        # GLSL burning shader animation
        timeout "$duration" glslviewer "$BURN_SHADER" \
            --text "$text" \
            --size 1920x1080 \
            2>/dev/null || true
    else
        # Fallback ASCII burning animation
        for i in {1..10}; do
            echo -ne "${RED}"
            # Simple burning effect with characters
            burned_text=$(echo "$text" | sed "s/./$(printf '\u2588')/$((RANDOM % ${#text} + 1))" | head -1)
            echo -e "$burned_text${NC}"
            sleep 0.1
        done
    fi
}

# Video recording function
record_ceremony() {
    local duration="$1"

    echo -e "${CYAN}🎥 Recording ceremony to: $VIDEO_OUTPUT${NC}"

    # Use ffmpeg to record the screen during ceremony
    if command -v ffmpeg &> /dev/null; then
        # Record screen for specified duration
        ffmpeg -f x11grab \
               -video_size 1920x1080 \
               -i $DISPLAY \
               -c:v libx264 \
               -preset ultrafast \
               -t "$duration" \
               "$VIDEO_OUTPUT" \
               2>/dev/null &
        RECORD_PID=$!
    else
        echo -e "${YELLOW}⚠️  ffmpeg not available, skipping video recording${NC}"
    fi
}

# Stop video recording
stop_recording() {
    if [ -n "$RECORD_PID" ]; then
        kill "$RECORD_PID" 2>/dev/null || true
        wait "$RECORD_PID" 2>/dev/null || true
        echo -e "${GREEN}✅ Video saved to: $VIDEO_OUTPUT${NC}"
    fi
}

# Password removal option
offer_password_removal() {
    echo -e "${YELLOW}"
    echo "Would you like to remove the password requirement for user 'queen'?"
    echo "This will enable autologin without password prompts."
    echo -e "${NC}"

    read -p "(y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔓 Removing password requirement...${NC}"

        # Remove password for queen user
        sudo passwd -d queen 2>/dev/null || true

        # Configure SDDM for autologin (if SDDM is used)
        if [ -f "/etc/sddm.conf" ]; then
            sudo tee -a /etc/sddm.conf > /dev/null << EOF

[Autologin]
User=queen
Session=plasma.desktop
EOF
        fi

        echo -e "${GREEN}✅ Password removed. Queen can now login without password.${NC}"
    else
        echo -e "${BLUE}ℹ️  Keeping password requirement intact.${NC}"
    fi
}

# Main ceremony function
perform_rebirth_ceremony() {
    local ceremony_duration=15  # seconds

    echo -e "${GREEN}🎊 Beginning Lilith Rebirth Ceremony...${NC}"

    # Start video recording
    record_ceremony "$ceremony_duration"

    # Show demonic banner
    show_demonic_banner
    sleep 2

    # Show rebirth message
    show_rebirth_message
    sleep 3

    # Burning text animations
    burn_text_animation "LILITH LINUX" 3
    sleep 1

    burn_text_animation "REBIRTH EDITION" 3
    sleep 1

    burn_text_animation "FORGED IN FLAMES" 3
    sleep 1

    burn_text_animation "REBORN IN GLORY" 4

    # Final message
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              🔥 REBIRTH CEREMONY COMPLETE! 🔥              ║"
    echo "║                                                              ║"
    echo "║              Welcome to your new digital existence           ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Stop recording
    stop_recording

    # Offer password removal
    offer_password_removal

    echo -e "${GREEN}🎊 Rebirth Ceremony Complete! Welcome to Lilith Linux Rebirth Edition!${NC}"
}

# Self-destruct mechanism
self_destruct() {
    echo -e "${BLUE}🗑️  Cleaning up ceremony files...${NC}"

    # Remove this script
    rm -f "$0"

    # Remove the systemd service that triggered this
    sudo systemctl disable lilith-rebirth-ceremony.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/lilith-rebirth-ceremony.service 2>/dev/null || true
    sudo systemctl daemon-reload 2>/dev/null || true

    echo -e "${BLUE}✅ Ceremony cleanup complete${NC}"
}

# Main execution
main() {
    # Check if running as queen user
    if [ "$USER" != "queen" ]; then
        echo -e "${RED}❌ This ceremony must be performed as user 'queen'${NC}"
        exit 1
    fi

    # Check if already performed (marker file)
    MARKER_FILE="$HOME/.lilith-rebirth-completed"
    if [ -f "$MARKER_FILE" ]; then
        echo -e "${YELLOW}ℹ️  Rebirth Ceremony already completed on $(cat $MARKER_FILE)${NC}"
        exit 0
    fi

    # Perform the ceremony
    perform_rebirth_ceremony

    # Mark as completed
    date > "$MARKER_FILE"

    # Self-destruct
    self_destruct
}

# Run main function
main "$@"
