---
name: display-status
description: Verifica se o display externo (HDMI/OLED) está em 4K@120Hz e corrige automaticamente via xrandr se não estiver, usando scripts/display-verify.sh. Use quando o usuário perguntar se o display está configurado corretamente, após reconectar o HDMI, ou para diagnosticar problema de imagem/refresh rate.
context: fork
agent: display-verifier
---

Invoque o agente `display-verifier`. Script real: `scripts/display-verify.sh` (verifica via `xrandr` e corrige resolução/taxa se necessário, já implementado).
