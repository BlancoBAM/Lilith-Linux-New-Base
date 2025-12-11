# 🔥 Lilith Linux - Rebirth Edition 🔥

*"Forged in flames, reborn in glory"*

## 🎂 December 9th Special Release

This directory contains the **complete Rebirth Edition** build system for Lilith Linux, featuring:

- **AI Stack Integration**: YAML bundle with RAG pipeline and LLM supervisor
- **Rebirth Ceremony**: Burning text animation with video recording
- **Hardware Optimization**: Tuned for i3-11xx, 4GB RAM, 256GB NVMe
- **Master Build Script**: Self-contained ISO generation

## 📁 Directory Structure

```
rebirth-edition/
├── lilith-rebirth-master-build.sh    # 🚀 Main build script
├── build-scripts/                    # Build system scripts
│   └── branding-hook.sh             # Rebirth Edition branding
├── ai-bundle/                       # AI components
│   └── lilith_bundle.yaml           # Embedded AI stack
├── ceremony/                        # Rebirth experience
│   └── rebirth-birthday.sh          # Ceremony script
└── docs/                           # Documentation
    └── README.md                    # This file
```

## 🚀 Quick Start

```bash

./lilith-rebirth-master-build.sh
```

This will:
1. Set up SSH keys (optional)
2. Sync repository
3. Embed AI bundle
4. Apply hardware optimizations
5. Create queen user
6. Configure services
7. Build the ISO

## 🎊 First Boot Experience

1. **Queen Autologin**: Seamless login as queen user
2. **Post-Install**: AI bundle extraction and setup
3. **Rebirth Ceremony**: Burning animations and video recording
4. **AI Activation**: Hotkey (Super+Space) with OCR support

## 🛠️ Components

### AI Stack (YAML Bundle)
- RAG pipeline scripts
- Fine-tuning dataset builder
- GCP training integration
- Lilith daemon (FastAPI)
- LLM supervisor (llama.cpp)
- Summon assistant (OCR hotkey)

### Rebirth Ceremony
- GLSL burning shader animations
- MP4 video recording
- Password removal option
- Self-destructing service

### Hardware Optimizations
- ZRAM for RAM efficiency
- CPU governor (powersave)
- Weekly fstrim for NVMe
- Ananicy process priorities

## 📋 Requirements

- 20GB+ free disk space
- Internet connection
- Ubuntu/Debian build environment
- sudo privileges

## 🎯 Output

Bootable ISO: `lilith-linux-rebirth-1.0-amd64.iso`

## 🔧 Manual Build Steps

If you prefer manual control:

```bash
# 1. Embed AI bundle
cp ai-bundle/lilith_bundle.yaml lilith-system-root/opt/lilith/

# 2. Apply hardware tweaks
sudo ./build-scripts/apply-hardware-tweaks.sh

# 3. Set up users and services
sudo ./build-scripts/setup-users.sh

# 4. Build ISO
sudo ./build-iso.sh
```

## 🎂 Rebirth Edition Features

- **Queen User**: Auto-created with autologin
- **Ceremony Video**: Recorded to `~/Videos/`
- **AI Hotkey**: Super+Space for instant assistance
- **Bundle Resurrection**: AI components "resurrect" on first boot
- **Hardware Optimized**: Perfect for low-spec laptops

---

**Ready for December 9th release!** 🔥✨
