#!/bin/bash
# HDMI Audio Watchdog - keeps audio on HDMI (TV + soundbar)
# Runs via systemd timer every 30 seconds
# State is managed by audio-switch.sh — watchdog only reads it, never writes it

# "bluetooth" mode: let the user's choice stand
[ "$(cat "$HOME/.local/state/audio-output-mode" 2>/dev/null || echo hdmi)" = "hdmi" ] || exit 0

# Detected at runtime: the PCI address in the sink name changes with GPU/board changes
HDMI_SINK=$(pactl list sinks short 2>/dev/null | awk '$2 ~ /^alsa_output\..*hdmi/ {print $2; exit}')
[ -n "$HDMI_SINK" ] || exit 0

LOG_FILE="$HOME/.local/state/hdmi-audio-fix.log"
log() { echo "$(date): $1" >> "$LOG_FILE" 2>/dev/null || true; }

if [ "$(pactl get-default-sink 2>/dev/null)" != "$HDMI_SINK" ]; then
    log "Watchdog - setting default to $HDMI_SINK"
    pactl set-default-sink "$HDMI_SINK"
fi

# Lecture mode keeps streams where they are. Check the process, not a flag file that can go stale
pgrep -f 'lecture-capture\.sh' > /dev/null && exit 0

HDMI_INDEX=$(pactl list sinks short | awk -v name="$HDMI_SINK" '$2 == name {print $1}')
for input in $(pactl list sink-inputs short | awk -v sink="$HDMI_INDEX" '$2 != sink {print $1}'); do
    log "Watchdog - moving stream $input to HDMI"
    pactl move-sink-input "$input" "$HDMI_SINK" 2>/dev/null
done

exit 0
