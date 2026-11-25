#!/bin/bash
# Acende a TV (chamado pela unidade lg-buddy-wake.service quando Shift/Ctrl e pressionado com a TV apagada pelo LG Buddy).
LOCK="/run/user/$(id -u)/lg_buddy/lock"; mkdir -p "$(dirname "$LOCK")"
flock -w 60 "$LOCK" timeout 60 "$HOME/.local/bin/LG_Buddy_Screen_On"
# recuperacao de sinal so faz sentido se a saida esperada existir (config com a A2000 e a TV em DP-3)
[ -e /sys/class/drm/card0-DP-3/status ] && "$HOME/.local/bin/tv-wake-recover.sh"
exit 0
