#!/bin/bash
# VoxType Watchdog - restarts voxtype.service if GameMode's end-hook
# never fired (e.g. a game was force-killed instead of exiting cleanly),
# leaving voxtype stuck stopped with no game actually running.
# Runs via systemd timer, low resource usage.

LOG_FILE="$HOME/.local/state/voxtype-watchdog.log"

log() {
    echo "$(date): $1" >> "$LOG_FILE" 2>/dev/null || true
}

if systemctl --user is-active --quiet voxtype.service; then
    exit 0
fi

if gamemoded -s 2>/dev/null | grep -q "gamemode is active"; then
    # A game is genuinely running (or GameMode thinks so) — leave it stopped.
    exit 0
fi

log "voxtype inactive and no game running — restarting"
systemctl --user start voxtype.service

exit 0
