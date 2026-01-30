# Hardware Specifications

## Tested Configuration

### GPU
- **Model**: NVIDIA GeForce RTX 3070
- **Codename**: GA104
- **VRAM**: 8GB GDDR6
- **Driver**: 580.119.02
- **CUDA**: 13.0
- **PCI Address**: `0000:0a:00.1` (audio controller)

### Display
- **Model**: LG B3 OLED TV (55")
- **Resolution**: 3840x2160 (4K)
- **Refresh Rate**: 120Hz
- **Connection**: HDMI 2.1 (HDMI 4 input on TV)
- **HDR**: Supported (Dolby Vision, HDR10)

### Audio
- **Output**: Polk Audio Soundbar
- **Connection**: TV eARC (HDMI 3 on TV)
- **Format**: PCM Stereo (S16LE, 48kHz)

### System
- **CPU**: AMD (document your specific model)
- **RAM**: (document your RAM)
- **Storage**: NVMe SSD for OS, NTFS partition for dual-boot

## TV Settings (LG B3)

### For 4K@120Hz
- **HDMI Deep Color**: 4K (enabled for HDMI 4)
- **Instant Game Response**: On
- **Game Optimizer**: On (optional)

### For Audio via eARC
- **Sound Out**: HDMI ARC Device
- **Digital Sound Out**: Auto (or PCM)
- **eARC Support**: On
- **Pass Through**: On

## HDMI Cable Requirements

For 4K@120Hz, you need:
- **Ultra High Speed HDMI cable** (48Gbps)
- **HDMI 2.1 certified**
- Short as possible (under 2m recommended)

## Compatibility Notes

### Should Work With
- NVIDIA RTX 20/30/40 series GPUs
- Any LG OLED (C1, C2, C3, B1, B2, B3, G series)
- Other OLED TVs/monitors with HDMI audio
- Any eARC/ARC soundbar

### May Require Adjustments
- AMD GPUs (different ALSA device names)
- Non-LG displays (different Deep Color settings)
- Older NVIDIA GPUs (different PCI addresses)

## Finding Your Hardware Info

### GPU PCI Address
```bash
lspci | grep -i nvidia
# Look for "Audio device" line
```

### ALSA Device Names
```bash
aplay -L | grep hdmi
```

### Current Display Mode
```bash
# X11
xrandr | grep " connected"

# Wayland (COSMIC)
cosmic-randr list
```

### Audio Sink Names
```bash
pactl list sinks | grep "Name:"
```
