#!/bin/bash
# Audio Output Switch - Toggle between HDMI (ARC) and Bluetooth
# Usage:
#   audio-switch.sh                  # Toggle HDMI <-> Bluetooth
#   audio-switch.sh hdmi             # Switch to HDMI
#   audio-switch.sh bluetooth        # Switch to Bluetooth (most recent device)
#   audio-switch.sh bluetooth xm5    # Switch to specific BT device (name filter)
#   audio-switch.sh bluetooth punker # Switch to specific BT device (name filter)

STATE_FILE="$HOME/.local/state/audio-output-mode"
HDMI_SINK="alsa_output.pci-0000_0a_00.1.hdmi-stereo-extra1"
LOG_FILE="$HOME/.local/state/hdmi-audio-fix.log"

log() { echo "$(date): $1" >> "$LOG_FILE" 2>/dev/null || true; }

# Find Bluetooth sink — optional name filter, prefers most recently connected
find_bt_sink() {
    local filter="$1"
    local sinks

    if [ -n "$filter" ]; then
        # Match by description (friendly name) — case insensitive
        local all_bt_sinks
        all_bt_sinks=$(pactl list sinks short 2>/dev/null | grep "bluez_output" | awk '{print $2}')
        for sink in $all_bt_sinks; do
            local desc
            desc=$(pactl list sinks 2>/dev/null | grep -A2 "$sink" | grep "Description" | cut -d: -f2- | xargs)
            if echo "$desc" | grep -qi "$filter"; then
                echo "$sink"
                return
            fi
        done
    else
        # No filter — pick the most recently connected (last in list)
        pactl list sinks short 2>/dev/null | grep "bluez_output" | awk '{print $2}' | tail -1
    fi
}

# Set default sink and move all active streams to it
set_default_sink() {
    local sink_name="$1"
    local sink_index

    # Set both configured and session defaults
    pw-metadata -n default 0 default.configured.audio.sink "{\"name\":\"$sink_name\"}" 2>/dev/null
    pw-metadata -n default 0 default.audio.sink "{\"name\":\"$sink_name\"}" 2>/dev/null
    pactl set-default-sink "$sink_name" 2>/dev/null

    # Move all active streams to the target sink
    sink_index=$(pactl list sinks short 2>/dev/null | grep "$sink_name" | awk '{print $1}')
    if [ -n "$sink_index" ]; then
        for input in $(pactl list sink-inputs short 2>/dev/null | awk '{print $1}'); do
            pactl move-sink-input "$input" "$sink_index" 2>/dev/null
        done
    fi
}

# Get friendly name for a sink
get_sink_description() {
    pactl list sinks 2>/dev/null | grep -A2 "$1" | grep "Description" | cut -d: -f2- | xargs
}

# Determine target mode
CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "hdmi")
if [ -n "$1" ]; then
    MODE="$1"
else
    [ "$CURRENT" = "hdmi" ] && MODE="bluetooth" || MODE="hdmi"
fi

if [ "$MODE" = "bluetooth" ]; then
    BT_FILTER="$2"
    BT_SINK=$(find_bt_sink "$BT_FILTER")
    if [ -z "$BT_SINK" ]; then
        if [ -n "$BT_FILTER" ]; then
            notify-send -i audio-card "Audio Switch" "No Bluetooth device matching '$BT_FILTER'" 2>/dev/null
            echo "No Bluetooth device matching '$BT_FILTER'. Available:"
            pactl list sinks short 2>/dev/null | grep "bluez_output" | while read -r _ name _; do
                echo "  - $(get_sink_description "$name") ($name)"
            done
        else
            notify-send -i audio-card "Audio Switch" "No Bluetooth speaker connected" 2>/dev/null
            echo "No Bluetooth audio sink found. Is a speaker connected?"
        fi
        exit 1
    fi
    set_default_sink "$BT_SINK"
    echo "bluetooth" > "$STATE_FILE"
    BT_NAME=$(get_sink_description "$BT_SINK")
    notify-send -i audio-card "Audio Switch" "Switched to Bluetooth: ${BT_NAME:-$BT_SINK}" 2>/dev/null
    log "Audio switch: bluetooth ($BT_SINK)"
    echo "Switched to Bluetooth: ${BT_NAME:-$BT_SINK}"
else
    set_default_sink "$HDMI_SINK"
    echo "hdmi" > "$STATE_FILE"
    notify-send -i audio-card "Audio Switch" "Switched to HDMI (ARC)" 2>/dev/null
    log "Audio switch: hdmi"
    echo "Switched to HDMI (ARC)"
fi
