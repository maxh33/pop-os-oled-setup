# Pop!_OS OLED Setup Guide

A comprehensive guide for setting up Pop!_OS with NVIDIA GPU and OLED TV/Monitor, including the **critical HDMI audio fix** for PipeWire distortion.

## Hardware This Guide Is For

- **GPU**: NVIDIA RTX 30/40 series (tested on RTX 3070)
- **Display**: LG OLED TV (tested on B3) or any OLED monitor via HDMI
- **Audio**: TV speakers or soundbar via eARC/ARC
- **OS**: Pop!_OS 24.04 LTS with COSMIC desktop

## The Problem This Solves

If you're experiencing **audio distortion/crackling** when using NVIDIA HDMI output on Linux with PipeWire, this guide has the fix. The issue is caused by PipeWire's SPA-ALSA adapter - we bypass it entirely.

## Quick Start

### 1. Clone this repo
```bash
git clone https://github.com/maxh33/pop-os-oled-setup
cd pop-os-oled-setup
```

### 2. Run the installer
```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

### 3. Restart PipeWire
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### 4. Test audio
```bash
paplay /usr/share/sounds/freedesktop/stereo/complete.oga
```

## Documentation

| Doc | Description |
|-----|-------------|
| [HARDWARE.md](HARDWARE.md) | Full hardware specs and requirements |
| [02-nvidia-hdmi-audio.md](docs/02-nvidia-hdmi-audio.md) | **THE FIX** - HDMI audio distortion solution |
| [05-development-tools.md](docs/05-development-tools.md) | Dev environment setup |
| [06-kitty-shortcuts.md](docs/06-kitty-shortcuts.md) | Kitty terminal shortcuts |
| [07-epson-l3150-printer.md](docs/07-epson-l3150-printer.md) | Epson L3150 printer/scanner setup |
| [08-voxtype-setup.md](docs/08-voxtype-setup.md) | Voxtype speech-to-text setup |
| [09-gemini-setup.md](docs/09-gemini-setup.md) | Gemini AI CLI setup |
| [10-fzf-history-search.md](docs/10-fzf-history-search.md) | FZF fuzzy history search |
| [11-blesh-setup.md](docs/11-blesh-setup.md) | ble.sh syntax highlighting & auto-suggestions |

## Key Fix Summary

The HDMI audio distortion is fixed by adding this to WirePlumber config:

```lua
api.alsa.path = "hw:NVidia,3"
```

This bypasses PipeWire's buggy SPA-ALSA adapter and uses ALSA directly.

See [docs/02-nvidia-hdmi-audio.md](docs/02-nvidia-hdmi-audio.md) for full details.

## System Specs (Reference)

| Component | Version |
|-----------|---------|
| Pop!_OS | 24.04 LTS |
| Kernel | 6.17.9 |
| NVIDIA Driver | 580.119.02 |
| PipeWire | 1.5.84 |
| Desktop | COSMIC (Wayland) |

## Contributing

Found this helpful? Contributions welcome!

- Report issues
- Submit PRs for other OLED displays
- Share your configs

## License

MIT License - Use freely, share widely.

## Acknowledgments

- Pop!_OS / System76 team for COSMIC desktop
- The Linux audio community for PipeWire
- Everyone who helped debug this HDMI audio nightmare
