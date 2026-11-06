#!/bin/bash
# OneDriveGUI gera ~10 GB/dia de log em /tmp (varredura "Processing/not changed").
# Apaga rotacionados e zera o ativo (serviço mantém o fd aberto) se > 500 MB.
D=/tmp/onedrive-gui
[ -d "$D" ] || exit 0
find "$D" -name 'onedrive-gui.log.*' -type f -delete
[ "$(stat -c %s "$D/onedrive-gui.log" 2>/dev/null || echo 0)" -gt 524288000 ] && : > "$D/onedrive-gui.log"
exit 0
