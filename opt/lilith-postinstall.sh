#!/bin/bash

# Lilith Linux Post-Installation Script
# Integrates Lilith AI system into a running Lilith Linux installation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
AI_DIR="/opt/lilith-ai"
SCRIPT_DIR="$AI_DIR/scripts"
CONFIG_DIR="$AI_DIR/config"
MODEL_DIR="$AI_DIR/models"
LOG_DIR="$AI_DIR/logs"

# Logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [POSTINSTALL] - $*" | tee -a /var/log/lilith-postinstall.log
}

show_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  🜏 𖤐 𐕣 Lilith Linux AI Integration - Post Installation 𓅓࣪ ִֶָ☾. ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        exit 1
    fi
}

# Install system dependencies
install_dependencies() {
    log "Installing system dependencies..."

    # Update package list
    apt-get update

    # Install core dependencies
    apt-get install -y \
        git \
        cmake \
        make \
        gcc \
        g++ \
        build-essential \
        pkg-config \
        python3 \
        python3-pip \
        python3-dev \
        jq \
        curl \
        wget

    # Install optimization libraries
    apt-get install -y \
        libopenblas-dev \
        libblas-dev \
        libatlas-base-dev \
        liblapack-dev \
        liblapacke-dev \
        libffi-dev \
        libssl-dev \
        libhdf5-dev \
        libyaml-dev

    log "Dependencies installed successfully"
}

# Setup AI directories and permissions
setup_directories() {
    log "Setting up AI directories..."

    # Create directories
    mkdir -p "$AI_DIR" "$SCRIPT_DIR" "$CONFIG_DIR" "$MODEL_DIR" "$LOG_DIR"

    # Set permissions
    chown -R root:root "$AI_DIR"
    chmod -R 755 "$AI_DIR"

    log "Directories created successfully"
}

# Install AI configuration files
install_config() {
    log "Installing AI configuration files..."

    # Configuration files should already be in place from the ISO
    # Verify they exist
    if [ ! -f "$CONFIG_DIR/ai-config.json" ]; then
        log "Error: Main AI config not found"
        exit 1
    fi

    for task in sysadmin academic coding writing techsupport research; do
        if [ ! -f "$CONFIG_DIR/tasks/${task}.json" ]; then
            log "Error: ${task} task config not found"
            exit 1
        fi
    done

    log "Configuration files verified"
}

# Install AI scripts
install_scripts() {
    log "Installing AI scripts..."

    # Scripts should already be in place
    # Make them executable
    chmod +x "$SCRIPT_DIR"/*.sh
    chmod +x "$SCRIPT_DIR"/*.py

    # Install main lilith command
    if [ -f "/usr/local/bin/lilith" ]; then
        chmod +x /usr/local/bin/lilith
        log "Main lilith command installed"
    else
        log "Warning: Main lilith command not found"
    fi
}

# Setup systemd service
setup_service() {
    log "Setting up systemd service..."

    # Reload systemd and enable service
    systemctl daemon-reload

    # Enable but don't start automatically (will be started on demand)
    systemctl enable lilith-ai

    log "Systemd service configured"
}

# Install llama.cpp for local AI processing
install_llamacpp() {
    log "Installing llama.cpp for local AI processing..."

    cd "$AI_DIR"

    # Clone llama.cpp if not already present
    if [ ! -d "llama.cpp" ]; then
        git clone --depth 1 https://github.com/ggerganov/llama.cpp.git
        cd llama.cpp

        # Build with optimizations
        mkdir build && cd build
        cmake .. \
            -DLLAMA_BUILD_ALL=1 \
            -DLLAMA_AVX=ON \
            -DLLAMA_AVX2=ON \
            -DLLAMA_AVX512=ON \
            -DLLAMA_FMA=ON \
            -DLLAMA_F16C=ON \
            -DLLAMA_CUBLAS=OFF \
            -DLLAMA_OPENBLAS=ON \
            -DLLAMA_BLAS_VENDOR=OpenBLAS \
            -DCMAKE_BUILD_TYPE=Release

        make -j$(nproc)
        cd "$AI_DIR"
    fi

    log "llama.cpp installed successfully"
}

# Download AI model (optional - can be done later by user)
download_model() {
    log "Checking for AI model..."

    # Check if model exists
    if [ -f "$MODEL_DIR/main-model.gguf" ]; then
        log "AI model already present"
        return
    fi

    log "AI model not found - will be downloaded on first use"
    log "Users can run: lilith --setup to download models"
}

# Install Python dependencies
install_python_deps() {
    log "Installing Python dependencies..."

    python3 -m pip install --upgrade pip
    python3 -m pip install requests

    log "Python dependencies installed"
}

# Setup desktop integration
setup_desktop_integration() {
    log "Setting up desktop integration..."

    # Install required tools
    apt-get install -y xdotool wmctrl

    # Create desktop hotkey script
    cat > /usr/local/bin/lilith-ai-hotkey.sh << 'HOTKEY_EOF'
#!/bin/bash

# Lilith AI Hotkey Handler
# Triggered by Ctrl+Alt+A

# Get active window info
ACTIVE_WINDOW=$(xdotool getactivewindow getwindowname 2>/dev/null || echo "Desktop")

# Create temporary files
TEMP_PROMPT="/tmp/lilith-prompt.txt"
TEMP_RESPONSE="/tmp/lilith-response.txt"

# Create context-aware prompt
cat > "$TEMP_PROMPT" << EOF
You are a helpful AI assistant specialized for Lilith Linux.

Current Context: $ACTIVE_WINDOW

How can I help you?
EOF

# Launch AI interface
zenity --text-info --title "Lilith AI Assistant" --filename="$TEMP_PROMPT" --editable \
    --width=600 --height=400 2>/dev/null |
tr '\n' ' ' > "$TEMP_PROMPT.input"

# If user provided input, process it
if [ -s "$TEMP_PROMPT.input" ]; then
    /usr/local/bin/lilith "$(cat "$TEMP_PROMPT.input")" > "$TEMP_RESPONSE"
    zenity --text-info --title "Lilith AI Response" --filename="$TEMP_RESPONSE" \
        --width=600 --height=400 2>/dev/null
fi

# Cleanup
rm -f "$TEMP_PROMPT" "$TEMP_PROMPT.input" "$TEMP_RESPONSE"
HOTKEY_EOF

    chmod +x /usr/local/bin/lilith-ai-hotkey.sh

    # Setup hotkey (this may need manual configuration per desktop environment)
    log "Desktop integration prepared (may need manual hotkey configuration)"
}

# Setup terminal integration
setup_terminal_integration() {
    log "Setting up terminal integration..."

    # Add to system PATH (should already be done)
    echo 'export PATH="$PATH:/opt/lilith-ai/scripts"' >> /etc/bash.bashrc

    # Create symlink for easy access
    ln -sf /usr/local/bin/lilith /usr/local/bin/lilith

    log "Terminal integration configured"
}

# Create documentation
create_documentation() {
    log "Creating documentation..."

    cat > "$AI_DIR/README.md" << 'DOC_EOF'
# Lilith Linux AI Integration

## Overview
Lilith Linux includes a locally-deployed AI assistant optimized for your hardware with specialized knowledge areas.

## Features
- Local processing (no cloud dependency)
- Hardware optimization with quantization
- Specialized knowledge areas
- Desktop integration
- Terminal commands

## Usage

### Desktop Integration
- **Hotkey**: Ctrl+Alt+A launches AI assistant
- **Context Menu**: Right-click files for AI analysis (configurable)

### Terminal Commands
Available commands (run with `lilith` or directly):

```bash
# Generic help
lilith "How do I configure network settings?"

# Specialized commands
ask "What is systemd?"
help "troubleshoot network"
diagnose "why can't I connect to wifi?"
fix "permission denied error"
analyze "this bash script"
debug "find the bug in this code"
generate "create a backup script"
```

### Specialized Areas
- **System Administration**: `ask`, `explain`, `help`, `diagnose`, `fix`
- **Code Assistant**: `analyze`, `debug`, `review`, `optimize`, `generate`
- **Creative Writing**: `write`, `edit`, `review`, `proofread`
- **Technical Support**: `diagnose`, `fix`, `guide`, `explain`
- **Research Helper**: `search`, `summarize`, `learn`, `research`

## Configuration

### Model Settings
- Location: `/opt/lilith-ai/models/main-model.gguf`
- Quantization: Configurable (Q2_K, Q3_K_L, Q4_K_M, etc.)
- Context length: Up to 8192 tokens

### Task Configuration
- Location: `/opt/lilith-ai/config/tasks/`
- JSON configurations for each specialized area
- Customizable system prompts and keywords

## Hardware Optimization

### Supported Quantization Levels
- **Q2_K**: Fastest, lowest memory (~1.5-3GB RAM)
- **Q3_K_L**: Balanced performance (~2-4GB RAM)
- **Q4_K_M**: Recommended default (~2.5-5GB RAM)
- **Q5_K_M**: Higher quality (~3-6GB RAM)
- **Q8_0**: Near full precision (~4-8GB RAM)

### Performance Estimates
- **Q4_K_M 7B model**: ~10-20 tokens/second
- **Q3_K_L 7B model**: ~15-25 tokens/second
- **Q2_K 7B model**: ~20-35 tokens/second

## Integration Options

### Hotkey Configuration
Edit: `~/.config/autostart/lilith-ai.desktop`

### Context Menu
Requires manual configuration per file manager (Dolphin, Nautilus, etc.)

### Terminal Integration
Automatically added to PATH via `/etc/bash.bashrc`

## Troubleshooting

### Service Not Starting
```bash
systemctl status lilith-ai
journalctl -u lilith-ai --no-pager
```

### Model Not Found
```bash
ls -la /opt/lilith-ai/models/
# Re-run setup if missing
```

### Low Performance
- Try lower quantization level (Q3_K_L or Q2_K)
- Reduce context length
- Check CPU usage: `htop`

### No Response
- Check logs: `tail -f /opt/lilith-ai/logs/lilith.log`
- Verify model file integrity
- Test basic functionality

## Customization

### Adding New Tasks
1. Create JSON config in `/opt/lilith-ai/config/tasks/`
2. Add keywords and system prompt
3. Restart AI service if needed

### Custom Models
1. Download quantized GGUF models to `/opt/lilith-ai/models/`
2. Update script paths in `/opt/lilith-ai/scripts/`
3. Test compatibility

### System Integration
Modify desktop integration in:
- `/usr/local/bin/lilith-ai-hotkey.sh`
- `/etc/bash.bashrc`

---

**Brought to you by Lilith Linux** 🔥
DOC_EOF

    log "Documentation created"
}

# Main installation function
main() {
    show_banner

    echo -e "${CYAN}Starting Lilith Linux AI Integration...${NC}"
    echo ""

    check_root

    install_dependencies
    setup_directories
    install_config
    install_scripts
    setup_service
    install_llamacpp
    download_model
    install_python_deps
    setup_desktop_integration
    setup_terminal_integration
    create_documentation

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Lilith AI Integration Complete!                         ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Start the AI service: systemctl start lilith-ai"
    echo "2. Test the system: lilith --status"
    echo "3. Download AI models: lilith --setup"
    echo "4. Enjoy Lilith Linux! 🜏 𖤐 𐕣"
    echo ""
    echo -e "${PURPLE}For more information, see: /opt/lilith-ai/README.md${NC}"
    echo ""

    log "Lilith AI integration completed successfully"
}

# Run main function
main "$@"
