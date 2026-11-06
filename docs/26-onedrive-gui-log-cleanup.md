# 26 — Limpeza dos logs do OneDriveGUI em /tmp

**Problema (2026-10-05):** o OneDriveGUI (`app-OneDriveGUI@autostart.service`) escreve em `/tmp/onedrive-gui/onedrive-gui.log` ~10 GB/dia
(linhas "Processing: ... / The file has not changed", varredura da pasta Google Fotos/Takeout). `/tmp` fica no `/` (290 GB):
em 3 dias o disco chegou a 100% (17 MB livres) e quase derrubou o repricer do JoiasMax e os volumes Docker (Postgres/MySQL).

**Fix:** timer systemd de usuario, de hora em hora:
- apaga `onedrive-gui.log.*` (rotacionados);
- zera o log ativo (`: >`, o servico mantem o fd aberto) se > 500 MB.

Arquivos (reference copies; deploy manual):
- `configs/scripts/onedrive-gui-log-cleanup.sh` -> `~/.local/bin/`
- `configs/systemd/onedrive-gui-log-cleanup.{service,timer}` -> `~/.config/systemd/user/`
- `systemctl --user daemon-reload && systemctl --user enable --now onedrive-gui-log-cleanup.timer`

Causa raiz nao resolvida: verbosidade do log nas configuracoes do OneDriveGUI. Se resolvida, este timer pode sair.
