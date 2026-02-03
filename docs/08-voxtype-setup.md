# VoxType Voice Dictation Setup

## Overview
Local voice-to-text using Whisper AI with GPU acceleration (Vulkan).

## Configuration
- **Binary**: `/usr/local/bin/voxtype` (Vulkan build)
- **Config**: `~/.config/voxtype/config.toml`
- **Model**: `large-v3-turbo` (~1.6 GB VRAM)
- **Models dir**: `~/.local/share/voxtype/models/`
- **Hotkey**: Scroll Lock (via COSMIC shortcut)

## Usage
1. Press **Scroll Lock** to start recording
2. Speak
3. Press **Scroll Lock** to stop and transcribe
4. Text appears at cursor position

## Service Management
```bash
# Check status
voxtype status
systemctl --user status voxtype

# Restart
systemctl --user restart voxtype

# Stop
systemctl --user stop voxtype

# View logs
journalctl --user -u voxtype -f
```

## Troubleshooting

### VoxType shows "stopped"
```bash
systemctl --user start voxtype
```

### No transcription output
```bash
# Check if wtype is installed (Wayland text input)
which wtype || sudo apt install wtype

# Check audio input
pactl list sources short
```

### Slow transcription
```bash
# Verify GPU is being used (check for Vulkan in logs)
journalctl --user -u voxtype | grep -i vulkan

# Check GPU usage during transcription
nvidia-smi  # or radeontop for AMD
```

### Wrong audio device
Edit `~/.config/voxtype/config.toml`:
```toml
[audio]
device = "your-device-name"
```

### Model issues
```bash
# Re-download model
voxtype setup model
# Select: large-v3-turbo
```

## Files
| File | Purpose |
|------|---------|
| `/usr/local/bin/voxtype` | Binary (Vulkan) |
| `~/.config/voxtype/config.toml` | Configuration |
| `~/.config/voxtype/config.toml.backup` | Backup config |
| `~/.local/share/voxtype/models/` | Whisper models |
| `~/.config/systemd/user/voxtype.service` | Autostart service |

## COSMIC Shortcut
Located in `~/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom`:
```
(modifiers: [], key: "Scroll_Lock"): Spawn("voxtype record toggle")
```

## GPU Notes

### Current Setup
- **GPU**: NVIDIA RTX 3070 (8GB GDDR6)
- **Backend**: Vulkan
- **VRAM Usage**: ~1.6 GB for large-v3-turbo

### Multi-GPU Selection
whisper.cpp doesn't have built-in GPU selection. Workarounds:
```bash
# For CUDA builds - select specific GPU
CUDA_VISIBLE_DEVICES=0 voxtype daemon

# For Vulkan - check which GPU is detected
journalctl --user -u voxtype | grep -i vulkan
```

### Check GPU Usage
```bash
# NVIDIA
nvidia-smi

# AMD
radeontop
```
