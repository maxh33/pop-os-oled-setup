# 27 — Disco cheio por syslog (OneDriveGUI) -> Brave com UI preta

**Sintoma (2026-10-09):** apos dias de uptime, o Brave mostra a pagina toda preta (conteudo existe, mas nao e pintado;
arrastar o mouse mostra um frame), popups de extensao ficam em "Loading, please wait". Reiniciar aba/navegador nao
resolve; so reboot. Causa: `/` em 100% (208 MB livres) — o Brave nao grava cache de GPU/shaders/temp.

**Causa raiz:** `/var/log/syslog` com 59 GB + `syslog.1` com 47 GB. O OneDriveGUI AppImage (programname
`OneDriveGUI-1.3.0-x86_64.AppImage`) loga "Processing: ... / The file has not changed" centenas de vezes/min no journal -> rsyslog.
(Distinto do doc 26, que trata do log em `/tmp/onedrive-gui/`; mesma origem, outro destino.)

**Diagnostico rapido:**
```bash
df -h /; ls -laS /var/log | head
tail -n 2000 /var/log/syslog | sed -E 's/[0-9]+/N/g' | sort | uniq -c | sort -rn | head
```

**Fix:**
1. Liberar espaco: `sudo truncate -s 0 /var/log/syslog && sudo rm -f /var/log/syslog.1`
2. Regra rsyslog: `configs/rsyslog/10-onedrive.conf` -> `/etc/rsyslog.d/10-onedrive.conf`, `sudo systemctl restart rsyslog`
3. Logrotate: `configs/logrotate/rsyslog` -> `/etc/logrotate.d/rsyslog` (adiciona `maxsize 500M` e `su root syslog`). **O `su root syslog` e essencial:** `/etc/logrotate.conf` tem `su root adm`, mas `/var/log` e `root:syslog 775`, entao o logrotate pulava o syslog ("parent directory has insecure permissions") e ele nunca rotacionava. Teste: `sudo logrotate -d /etc/logrotate.conf 2>&1 | grep -i insecure` (sem saida = ok)
4. Reabrir o Brave (sem reboot).

Causa raiz nao resolvida: verbosidade do OneDriveGUI/`onedrive --monitor -v` (flag `-v`). Se removida, a regra pode sair.
