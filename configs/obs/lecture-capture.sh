#!/bin/bash
# Lecture Capture Mode — routes Brave audio to lecture_capture sink
# Run before class, Ctrl+C to stop and restore normal routing
# Works alongside hdmi-audio-watchdog.sh without conflict

LECTURE_SINK="lecture_capture"
FLAG="$HOME/.local/state/lecture-mode"
LOG="$HOME/.local/state/hdmi-audio-fix.log"

cleanup() {
    echo "off" > "$FLAG"
    echo "$(date): lecture-capture — stopped, Brave restored to HDMI" >> "$LOG"
    echo "Lecture mode OFF — Brave routing restored to HDMI."
    exit 0
}
trap cleanup INT TERM

# Ensure virtual sink exists
if ! pactl list sinks short 2>/dev/null | grep -q "$LECTURE_SINK"; then
    echo "Creating lecture_capture virtual sink..."
    pactl load-module module-null-sink sink_name=lecture_capture sink_properties=device.description="Lecture_Capture"
    sleep 1
fi

LECTURE_INDEX=$(pactl list sinks short 2>/dev/null | grep "$LECTURE_SINK" | awk '{print $1}')
if [ -z "$LECTURE_INDEX" ]; then
    echo "ERROR: could not find lecture_capture sink. Aborting."
    exit 1
fi

echo "on" > "$FLAG"
echo "$(date): lecture-capture — started" >> "$LOG"
echo "Lecture mode ON — routing Brave to lecture_capture. Ctrl+C to stop."

while true; do
    # Find all Brave sink inputs and move them to lecture_capture
    BRAVE_INPUTS=$(pactl list sink-inputs 2>/dev/null | grep -B20 "brave\|Brave" | grep "^Sink Input" | grep -oP '\d+')
    for input in $BRAVE_INPUTS; do
        CURRENT=$(pactl list sink-inputs short 2>/dev/null | awk -v id="$input" '$1==id {print $2}')
        if [ "$CURRENT" != "$LECTURE_INDEX" ]; then
            pactl move-sink-input "$input" "$LECTURE_INDEX" 2>/dev/null
            echo "$(date): lecture-capture — moved Brave input $input to lecture_capture" >> "$LOG"
        fi
    done
    sleep 5
done
