# VoxType Voice Dictation Setup

## Overview
Local voice-to-text using Whisper AI with GPU acceleration (Vulkan).
VoxType is fully standalone — it does **not** depend on OpenWhispr.

## Configuration
- **Binary**: `/usr/local/bin/voxtype` (Vulkan build)
- **Config**: `~/.config/voxtype/config.toml`
- **Model**: `large-v3-turbo` (~1.6 GB VRAM)
- **Models dir**: `~/.local/share/voxtype/models/`
- **Hotkey**: Scroll Lock (via COSMIC shortcut)
- **Languages**: English + Portuguese (auto-detected)

## Usage
1. Press **Scroll Lock** to start recording
2. Speak
3. Press **Scroll Lock** to stop and transcribe
4. Text appears at cursor position

## Autostart Architecture

### How VoxType Starts (systemd only)
VoxType starts via a **systemd user service** — NOT via XDG `.desktop` autostart.

The `.desktop` autostart file (`~/.config/autostart/voxtype.desktop`) is explicitly
disabled with `Hidden=true` to prevent COSMIC from launching a duplicate instance.

**Why systemd over .desktop autostart:**
- `Restart=on-failure` with 5s retry for reliability
- Proper dependency ordering (waits for PipeWire + graphical session)
- `ExecStartPre` cleans stale lock files to prevent "already running" errors
- `Environment=WAYLAND_DISPLAY=wayland-1` ensures `wtype` can connect to the compositor

### OpenWhispr Autostart Disabled
OpenWhispr is installed but its autostart is disabled (`Hidden=true` in both
`.desktop` files). VoxType does not use OpenWhispr — they are independent apps
with separate Whisper models. Disabling OpenWhispr saves ~10-25 GB RAM.

### COSMIC Desktop Autostart Gotcha
COSMIC desktop **ignores** `X-GNOME-Autostart-enabled=false`. To disable
autostart on COSMIC, you must use the standard XDG property `Hidden=true`.
Both properties are set for compatibility with GNOME-based desktops.

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

### VoxType shows "stopped" / "idle"
This is normal — it means the daemon is running and waiting for input.
Press Scroll Lock to test.

### "Another voxtype instance is already running"
A stale lock file exists from a crashed instance. The systemd service
handles this automatically via `ExecStartPre`, but to fix manually:
```bash
rm -f /run/user/1000/voxtype/voxtype.lock /run/user/1000/voxtype/pid
systemctl --user restart voxtype
```

### "Voxtype daemon is not running" (but systemd shows active)
The CLI can't find the daemon's PID file. Check:
```bash
ls /run/user/1000/voxtype/
# Should contain: pid, voxtype.lock, state
```

### Text truncated or garbled (especially Portuguese / Unicode)
The typing driver `wtype` needs `WAYLAND_DISPLAY` to connect to the compositor.
If the systemd service starts before COSMIC exports the variable, `wtype` fails
silently and VoxType falls back to clipboard paste — which truncates text,
drops Unicode chars (ç, ã, é), and behaves worse in browsers.

**Fix:** The service must have `Environment=WAYLAND_DISPLAY=wayland-1` (already set).
Also ensure `type_delay_ms` is at least `2` in config.toml for browser compatibility.

**Diagnosis:**
```bash
# Check for wtype failures in logs
journalctl --user -u voxtype | grep -i 'wtype failed'
# If you see "Wayland connection failed", WAYLAND_DISPLAY is missing

# Verify the daemon has it
cat /proc/$(pgrep -f 'voxtype daemon')/environ | tr '\0' '\n' | grep WAYLAND
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
nvidia-smi
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
| `~/.config/systemd/user/voxtype.service` | Autostart service |
| `~/.local/share/voxtype/models/` | Whisper models |
| `~/.config/autostart/voxtype.desktop` | XDG autostart (disabled, Hidden=true) |
| `~/.config/autostart/openwhispr.desktop` | OpenWhispr autostart (disabled) |
| `~/.config/autostart/openwhispr-x11.desktop` | OpenWhispr X11 autostart (disabled) |
| `/run/user/1000/voxtype/` | Runtime: pid, lock, state files |

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
- **Model load time**: ~1.4 seconds

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
nvidia-smi
```

## Installation from Repo
```bash
# Copy systemd service
cp configs/voxtype/voxtype.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable voxtype.service

# Disable XDG autostart duplicates (prevent COSMIC from launching duplicates)
cp configs/voxtype/voxtype.desktop ~/.config/autostart/
cp configs/voxtype/openwhispr.desktop ~/.config/autostart/
cp configs/voxtype/openwhispr-x11.desktop ~/.config/autostart/
```
