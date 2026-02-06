# NVIDIA HDMI Audio Fix for PipeWire

## The Problem

When using NVIDIA HDMI audio output on Linux with PipeWire, you may experience:
- Audio distortion
- Crackling/static noise
- Garbled sound

**Key symptom**: ALSA direct playback sounds clean, but PipeWire playback is distorted.

## Root Cause

PipeWire's **SPA-ALSA adapter** introduces distortion when processing NVIDIA HDMI audio. This is a bug in PipeWire (tested on version 1.5.84).

## THE FIX

Bypass PipeWire's SPA-ALSA adapter by forcing direct ALSA hardware access:

```lua
api.alsa.path = "hw:NVidia,3"
```

## Configuration Files

### 1. WirePlumber Config (THE KEY FIX)

**File**: `~/.config/wireplumber/wireplumber.conf.d/99-hdmi-alsa-direct.conf`

```lua
# NVIDIA HDMI Audio Fix - Bypass PipeWire's SPA-ALSA adapter
# This fixes audio distortion by using direct ALSA hardware access
monitor.alsa.rules = [
  {
    matches = [
      {
        node.name = "~alsa_output.pci-0000_0a_00.1.*"
      }
    ]
    actions = {
      update-props = {
        audio.format = "S16LE"
        audio.rate = 48000
        audio.channels = 2
        api.alsa.path = "hw:NVidia,3"
        api.alsa.open.ucm = false
        api.alsa.use-acp = false
        session.suspend-timeout-seconds = 0
      }
    }
  }
]
```

**Important**: Adjust `pci-0000_0a_00.1` to match your GPU's PCI address. Find it with:
```bash
pactl list sinks | grep "Name:.*hdmi"
```

### 2. PipeWire Config

**File**: `~/.config/pipewire/pipewire.conf.d/10-hdmi-buffer.conf`

```lua
# NVIDIA HDMI Audio - Standard 48kHz settings
context.properties = {
    default.clock.rate = 48000
    default.clock.allowed-rates = [ 48000 ]
}
```

### 3. ALSA Config (Optional fallback)

**File**: `~/.asoundrc`

```
pcm.hdmi_out {
    type plug
    slave {
        pcm "hw:NVidia,3"
        format S16_LE
        rate 48000
        channels 2
    }
}
pcm.!default {
    type plug
    slave.pcm "hdmi_out"
}
```

## Systemd Services

### HDMI Audio Fix Service

**File**: `~/.config/systemd/user/hdmi-audio-fix.service`

```ini
[Unit]
Description=Enable NVIDIA HDMI Audio
After=pipewire.service wireplumber.service
Wants=pipewire.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 3
ExecStart=%h/.local/bin/hdmi-audio-fix.sh
RemainAfterExit=yes

[Install]
WantedBy=default.target
```

### Watchdog Timer (keeps audio working after TV power cycles)

**File**: `~/.config/systemd/user/hdmi-audio-watchdog.timer`

```ini
[Unit]
Description=Run HDMI Audio Watchdog every 30 seconds

[Timer]
OnBootSec=10s
OnUnitActiveSec=30s
AccuracySec=5s

[Install]
WantedBy=timers.target
```

## Sudo Configuration

The fix requires `hda-verb` to enable the HDMI audio pin. Add passwordless sudo:

**File**: `/etc/sudoers.d/hdmi-audio`

```
your_username ALL=(ALL) NOPASSWD: /usr/bin/hda-verb
```

## Installation

### Manual Installation

1. Create config directories:
```bash
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
mkdir -p ~/.config/pipewire/pipewire.conf.d
mkdir -p ~/.config/systemd/user
mkdir -p ~/.local/bin
```

2. Copy the config files (see above)

3. Copy the scripts from `scripts/` to `~/.local/bin/`

4. Enable services:
```bash
systemctl --user enable hdmi-audio-fix.service
systemctl --user enable hdmi-audio-watchdog.timer
systemctl --user start hdmi-audio-watchdog.timer
```

5. Restart PipeWire:
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### Using the Install Script

```bash
./scripts/install.sh
```

## Verification

### Test audio is working
```bash
paplay /usr/share/sounds/freedesktop/stereo/complete.oga
```

### Check format
```bash
pactl list sinks | grep -E "(Name:.*hdmi|Sample Spec)"
# Should show: s16le 2ch 48000Hz
```

### Check HDMI pin status
```bash
sudo hda-verb /dev/snd/hwC0D0 0x05 0xf07 0
# Should return: 0x40
```

### Test ALSA direct (to confirm hardware works)
```bash
systemctl --user stop pipewire pipewire-pulse wireplumber
aplay -D hw:NVidia,3 /tmp/test.wav
systemctl --user start pipewire pipewire-pulse wireplumber
```

## Known Quirk: HDMI Handshake

After TV power cycle, you may need to toggle **HDMI Deep Color** in TV settings to trigger an HDMI handshake:

**LG TV**: Settings → General → Devices → HDMI Settings → HDMI Deep Color → Toggle Off/On

This forces the audio to reinitialize properly.

## Troubleshooting

### No audio at all
1. Check HDMI pin is enabled:
   ```bash
   sudo hda-verb /dev/snd/hwC0D0 0x05 0x707 0x40
   ```
2. Set HDMI as default:
   ```bash
   pw-metadata -n default 0 default.audio.sink '{"name":"alsa_output.pci-0000_0a_00.1.hdmi-stereo-extra1"}'
   ```

### Audio on wrong output
```bash
~/.local/bin/hdmi-audio-fix.sh
```

### Still distorted
If audio is still distorted after applying this fix:
1. Verify you're using the correct ALSA device (`hw:NVidia,3`)
2. Check with `aplay -L | grep hdmi` to list available devices
3. Try different device numbers (0, 1, 2, 3)

## What We Tried (Before Finding This Fix)

| Setting | Result |
|---------|--------|
| S16LE format only | Distorted |
| S24LE format | No sound (TV doesn't support) |
| S32LE format | No sound |
| Larger quantum (2048, 4096) | Distorted or no sound |
| Disable resampling | Distorted |
| Disable channelmix | Distorted |
| Disable dithering | Distorted |
| Disable tsched | No sound |
| **api.alsa.path = "hw:NVidia,3"** | **CLEAN!** |

## Technical Details

- **PCI Address**: `0000:0a:00.1` (NVIDIA GPU audio controller)
- **ALSA Card**: `NVidia`
- **ALSA Device**: 3 (HDMI output to LG TV)
- **Audio Format**: S16LE (16-bit signed little-endian)
- **Sample Rate**: 48000 Hz
- **Channels**: 2 (stereo)
- **HDA Codec Node**: 0x05 (HDMI audio pin)
- **Pin Enable Value**: 0x40

## Bluetooth Audio Switching

The system supports switching between HDMI (ARC) and Bluetooth audio outputs using `audio-switch.sh`.

### Usage

```bash
audio-switch.sh                    # Toggle HDMI <-> Bluetooth
audio-switch.sh hdmi               # Switch to HDMI (ARC/Polk soundbar)
audio-switch.sh bluetooth           # Switch to Bluetooth (most recent device)
audio-switch.sh bluetooth xm5      # Switch to Sony WH-1000XM5
audio-switch.sh bluetooth punker   # Switch to Punker speaker
```

**Keyboard shortcut**: `Super+A` toggles audio output.

### How It Works

- **State file** (`~/.local/state/audio-output-mode`): tracks "hdmi" or "bluetooth"
- **Watchdog** respects the state — only enforces HDMI when mode is "hdmi"
- **Stream moving**: `pactl move-sink-input` moves all active streams (WirePlumber's `default.audio.sink` metadata is unreliable with BT devices connected)
- **Boot default**: HDMI (set by `hdmi-audio-fix.sh` on login)

### Bluetooth Configuration

- **BT autoswitch disabled**: `bluetooth.autoswitch-to-headset-profile = false` — prevents WirePlumber from switching headsets (e.g. Sony WH-1000XM5) from A2DP (high quality) to HSP/HFP (low quality + mic) when recording
- **Dedicated microphone always used**: Rear Mic on Starship/Matisse HD Audio Controller
- **Trusted devices**: Set via `bluetoothctl trust <MAC>` for auto-reconnect

### Known Behavior

WirePlumber (1.5.84) stubbornly controls `default.audio.sink` metadata when a Bluetooth device has higher `priority.session` (BT=1010 vs HDMI=632). The `*` indicator in `wpctl status` may show the BT device even when audio is routing through HDMI. This is cosmetic — the actual audio routing is controlled by stream connections, not the default indicator.

## References

- [Arch Wiki - PipeWire](https://wiki.archlinux.org/title/PipeWire)
- [PipeWire GitLab](https://gitlab.freedesktop.org/pipewire/pipewire)
- [ALSA Project](https://www.alsa-project.org/)
