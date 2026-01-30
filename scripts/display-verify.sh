#!/bin/bash
# Verify and enforce 4K@120Hz on HDMI-A-1
# For NVIDIA RTX 3070 + LG B3 OLED

EXPECTED_RES="3840x2160"
EXPECTED_RATE="119.86"
OUTPUT="HDMI-A-1"

LOG_DIR="$HOME/.local/state"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/display-verify.log"

log() {
    echo "$(date): $1" >> "$LOG_FILE" 2>/dev/null || true
    echo "$1"
}

# Get current mode info
current_line=$(xrandr --query 2>/dev/null | grep "^$OUTPUT")
if [[ -z "$current_line" ]]; then
    log "ERROR: Output $OUTPUT not found"
    exit 1
fi

# Check if connected
if ! echo "$current_line" | grep -q "connected"; then
    log "ERROR: $OUTPUT is not connected"
    exit 1
fi

# Get current resolution and rate from the active mode line (marked with *)
current_mode=$(xrandr --query 2>/dev/null | grep "^$OUTPUT" -A 50 | grep '\*' | head -1)
current_res=$(echo "$current_mode" | awk '{print $1}')
current_rate=$(echo "$current_mode" | grep -oP '\d+\.\d+(?=\*)')

log "Current display: ${current_res}@${current_rate}Hz"

# Check if we need to fix
needs_fix=0
if [[ "$current_res" != "$EXPECTED_RES" ]]; then
    log "Resolution mismatch: expected $EXPECTED_RES, got $current_res"
    needs_fix=1
fi

if [[ ! "$current_rate" =~ ^119 ]]; then
    log "Refresh rate mismatch: expected ~120Hz, got ${current_rate}Hz"
    needs_fix=1
fi

if [[ $needs_fix -eq 1 ]]; then
    log "Attempting to set ${EXPECTED_RES}@120Hz..."
    xrandr --output "$OUTPUT" --mode "$EXPECTED_RES" --rate 120 2>&1
    if [[ $? -eq 0 ]]; then
        log "Display mode set successfully"
    else
        log "ERROR: Failed to set display mode"
        exit 1
    fi
else
    log "Display OK: ${current_res}@${current_rate}Hz"
fi

exit 0
