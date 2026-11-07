#!/bin/bash
# Recupera o sinal da TV LG B3 depois de acordar o PC (sem sinal / tela preta).
# Uso: tv-wake-recover.sh [--force]   (DRY_RUN=1 só mostra o que faria)
# Estado do hardware: RTX A2000 -> adaptador -> LG B3 em HDMI_4, saída DP-3 no COSMIC.

readonly OUTPUT="DP-3"
readonly STATUS_FILE="/sys/class/drm/card0-${OUTPUT}/status"
readonly TV_IP="192.168.X.X"
readonly TV_MAC="XX:XX:XX:XX:XX:XX"
readonly PC_INPUT="HDMI_4"
readonly OTHER_INPUT="HDMI_2"
readonly LGTV="/usr/bin/LG_Buddy_PIP/bin/bscpylgtvcommand"
readonly LOG_FILE="$HOME/.local/state/tv-wake-recover.log"
readonly LOCK_FILE="/run/user/$UID/tv-wake-recover.lock"

mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "$(date '+%F %T') $1" >> "$LOG_FILE"; }

run() {
    log "run: $*"
    [[ "${DRY_RUN:-0}" == "1" ]] || "$@" >> "$LOG_FILE" 2>&1
}

connector_connected() { [[ "$(cat "$STATUS_FILE" 2>/dev/null)" == "connected" ]]; }

bounce_tv_input() {
    ping -c1 -W1 "$TV_IP" > /dev/null 2>&1 || { run wakeonlan -q "$TV_MAC"; sleep 4; }
    run "$LGTV" "$TV_IP" set_input "$OTHER_INPUT"
    sleep 3
    run "$LGTV" "$TV_IP" set_input "$PC_INPUT"
}

# Um disparo por vez: swayidle pode chamar mais de uma vez no mesmo wake.
exec 9> "$LOCK_FILE"
flock -n 9 || { log "ja rodando, saindo"; exit 0; }

force=0
[[ "${1:-}" == "--force" ]] && force=1

sleep 6 # deixa o LG_Buddy_Screen_On terminar o set_input dele primeiro

was_connected=1
for _ in $(seq 1 20); do
    connector_connected && break
    was_connected=0
    sleep 1
done

if ! connector_connected; then
    log "$OUTPUT segue desconectada apos 20s: bounce de entrada da TV"
    bounce_tv_input
elif [[ $was_connected -eq 0 || $force -eq 1 ]]; then
    log "$OUTPUT voltou tarde ou --force: re-modeset e bounce de entrada"
    run cosmic-randr disable "$OUTPUT"
    sleep 2
    run cosmic-randr enable "$OUTPUT"
    sleep 3
    bounce_tv_input
else
    log "$OUTPUT conectada normal, nada a fazer"
fi

sleep 10
if connector_connected; then log "fim: $OUTPUT conectada"; else log "fim: $OUTPUT AINDA desconectada"; fi
