#!/bin/bash
# HDMI Audio Watchdog - checks and fixes audio if needed
# Runs via systemd timer every 30 seconds, low resource usage

HDMI_SINK="alsa_output.pci-0000_0a_00.1.hdmi-stereo-extra1"
LOG_FILE="$HOME/.local/state/hdmi-audio-fix.log"

log() {
    echo "$(date): $1" >> "$LOG_FILE" 2>/dev/null || true
}

# Check if HDMI sink exists
if ! pactl list sinks short 2>/dev/null | grep -q "$HDMI_SINK"; then
    log "Watchdog - HDMI sink missing, running fix..."
    /home/max/.local/bin/hdmi-audio-fix.sh
    exit 0
fi

# Check if HDMI is default using pw-metadata
current_default=$(pw-metadata -n default 2>/dev/null | grep "default.audio.sink" | grep -oP 'name":"[^"]+' | cut -d'"' -f3)
if [ "$current_default" != "$HDMI_SINK" ]; then
    log "Watchdog - HDMI not default ($current_default), setting via pw-metadata..."
    pw-metadata -n default 0 default.audio.sink "{\"name\":\"$HDMI_SINK\"}" 2>/dev/null
fi

# Check pin status - if it's 0x00, re-enable it
pin_status=$(sudo /usr/bin/hda-verb /dev/snd/hwC0D0 0x05 0xf07 0 2>/dev/null | grep "value" | awk '{print $3}')
if [ "$pin_status" = "0x0" ]; then
    log "Watchdog - Pin disabled, re-enabling..."
    sudo /usr/bin/hda-verb /dev/snd/hwC0D0 0x05 0x707 0x40 2>/dev/null
fi

exit 0
