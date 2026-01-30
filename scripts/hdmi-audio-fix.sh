#!/bin/bash
# HDMI Audio Fix Script for NVIDIA + LG TV + Polk Soundbar
# This script enables HDMI audio after PipeWire starts

LOG_DIR="$HOME/.local/state"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/hdmi-audio-fix.log"

log() {
    echo "$(date): $1" >> "$LOG_FILE" 2>/dev/null || true
}

log "Starting HDMI audio fix..."

# Step 0: Verify display is at 4K@120Hz
if [[ -x "$HOME/.local/bin/display-verify.sh" ]]; then
    log "Running display verification..."
    "$HOME/.local/bin/display-verify.sh" >> "$LOG_FILE" 2>&1
fi

# Step 1: Set HDMI profile FIRST (this creates the sink)
pactl set-card-profile alsa_card.pci-0000_0a_00.1 output:hdmi-stereo-extra1 2>/dev/null
sleep 1

# Step 2: Enable HDMI audio pin (must be done AFTER profile is set)
sudo /usr/bin/hda-verb /dev/snd/hwC0D0 0x05 0x707 0x40 2>/dev/null
sleep 0.5

# Step 3: Enable pin again (PipeWire sometimes resets it)
sudo /usr/bin/hda-verb /dev/snd/hwC0D0 0x05 0x707 0x40 2>/dev/null

# Step 4: Set HDMI as default output using pw-metadata (most reliable method)
HDMI_SINK="alsa_output.pci-0000_0a_00.1.hdmi-stereo-extra1"
pw-metadata -n default 0 default.audio.sink "{\"name\":\"$HDMI_SINK\"}" 2>/dev/null
log "Set pw-metadata default.audio.sink to HDMI"
# Also set via pactl for compatibility
pactl set-default-sink "$HDMI_SINK" 2>/dev/null

# Step 5: Enable pin one more time after setting default
sleep 0.5
sudo /usr/bin/hda-verb /dev/snd/hwC0D0 0x05 0x707 0x40 2>/dev/null

# Step 6: Set microphone defaults
amixer -c 1 sset 'Input Source' 'Rear Mic' 2>/dev/null
amixer -c 1 sset 'Rear Mic Boost' 3 2>/dev/null
amixer -c 1 sset 'Capture' 100% 2>/dev/null

log "HDMI audio fix completed"
exit 0
