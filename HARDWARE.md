# Hardware Specifications

## Tested Configuration

### GPU — multi-GPU setup

This machine has four GPUs installed. Only one drives the OLED display; the
others are available for compute (AI/inference workloads — Whisper, etc.).

| GPU | VRAM | Role | Driver stack |
|---|---|---|---|
| **NVIDIA RTX A2000** | 12GB | Compute — currently the active workhorse for AI/inference workloads | NVIDIA (CUDA) |
| NVIDIA RTX 3070 (GA104) | 8GB GDDR6 | Display output — drives the OLED via HDMI (see HDMI audio fix below), available for compute too | NVIDIA (CUDA), driver 580.119.02, CUDA 13.0, PCI `0000:0a:00.1` (audio controller) |
| AMD Instinct MI50, flashed with Radeon VII VBIOS | 16GB HBM2 | Compute, available — not currently in active use | AMD (ROCm) — separate driver stack from the NVIDIA cards |
| AMD Radeon RX 6400 | 4GB | Compute, available — not currently in active use | AMD (amdgpu/Mesa, Vulkan) — RDNA2, not on the officially supported ROCm list |

Practical implication: CUDA-only tooling (faster-whisper/ctranslate2, most
NVIDIA-specific AI stacks) only targets the A2000/3070. The MI50 needs a
ROCm-based path; the RX 6400 realistically means Vulkan, not ROCm (crosses
vendors — see VoxType, which uses Vulkan for exactly this reason). When
picking which GPU a new service should use, don't assume "GPU 0" — verify
with `nvidia-smi -L` (NVIDIA cards) and
`rocm-smi` (MI50) which index maps to which card.

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
