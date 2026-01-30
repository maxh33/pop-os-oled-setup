#!/bin/bash
# HDMI Audio Hotplug Script - runs when TV turns on/off
# Triggered by udev rule: /etc/udev/rules.d/99-hdmi-audio-fix.rules

LOG_FILE="/tmp/hdmi-audio-fix.log"
echo "$(date): HDMI hotplug detected..." >> "$LOG_FILE"

# Wait for display to stabilize
sleep 3

# Check if HDMI is connected
if grep -q "^connected" /sys/class/drm/card0-HDMI-A-1/status 2>/dev/null; then
    echo "$(date): HDMI connected, fixing audio..." >> "$LOG_FILE"

    # Run as the user (udev runs as root)
    sudo -u max DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u max)/bus" \
        XDG_RUNTIME_DIR="/run/user/$(id -u max)" \
        /home/max/.local/bin/hdmi-audio-fix.sh >> "$LOG_FILE" 2>&1

    echo "$(date): Hotplug fix completed" >> "$LOG_FILE"
else
    echo "$(date): HDMI disconnected, skipping fix" >> "$LOG_FILE"
fi
