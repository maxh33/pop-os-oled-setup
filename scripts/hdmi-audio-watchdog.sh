#!/bin/bash
# HDMI Audio Watchdog - checks and fixes audio if needed
# Runs via systemd timer every 30 seconds, low resource usage
# State-aware: respects user's choice of Bluetooth or HDMI output
# State is managed by audio-switch.sh — watchdog only reads it, never writes it

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

# Read audio output mode — only audio-switch.sh writes this
AUDIO_MODE=$(cat "$HOME/.local/state/audio-output-mode" 2>/dev/null || echo "hdmi")

if [ "$AUDIO_MODE" = "hdmi" ]; then
    # Mode is HDMI — enforce it (TV power cycle recovery)
    # Check where streams are actually going
    HDMI_INDEX=$(pactl list sinks short 2>/dev/null | grep "$HDMI_SINK" | awk '{print $1}')
    NON_HDMI_INPUTS=$(pactl list sink-inputs short 2>/dev/null | grep -v "$HDMI_INDEX" | awk '{print $1}')
    if [ -n "$NON_HDMI_INPUTS" ]; then
        log "Watchdog - found streams not on HDMI, moving them..."
        for input in $NON_HDMI_INPUTS; do
            pactl move-sink-input "$input" "$HDMI_INDEX" 2>/dev/null
        done
    fi

    # Also ensure configured default is HDMI
    configured_default=$(pw-metadata -n default 2>/dev/null | grep "default.configured.audio.sink" | grep -oP 'name":"[^"]+' | cut -d'"' -f3)
    if [ "$configured_default" != "$HDMI_SINK" ]; then
        log "Watchdog - HDMI not configured default, setting..."
        pw-metadata -n default 0 default.configured.audio.sink "{\"name\":\"$HDMI_SINK\"}" 2>/dev/null
        pw-metadata -n default 0 default.audio.sink "{\"name\":\"$HDMI_SINK\"}" 2>/dev/null
    fi
fi
# If mode is "bluetooth", do nothing with defaults — let the user's choice stand

# Always keep HDMI pin enabled (needed for instant switching back)
pin_status=$(sudo /usr/bin/hda-verb /dev/snd/hwC0D0 0x05 0xf07 0 2>/dev/null | grep "value" | awk '{print $3}')
if [ "$pin_status" = "0x0" ]; then
    log "Watchdog - Pin disabled, re-enabling..."
    sudo /usr/bin/hda-verb /dev/snd/hwC0D0 0x05 0x707 0x40 2>/dev/null
fi

exit 0
