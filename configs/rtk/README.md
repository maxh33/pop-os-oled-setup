# RTK (rtk-ai/rtk)

Proxy CLI em Rust que comprime output de comandos Bash no Claude Code (60-90% de economia de tokens em operações de dev). Binário Rust, instalado via script oficial em `~/.local/bin/rtk`.

## Reinstalação nesta máquina

```bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
rtk init -g --auto-patch
```

Isso registra um hook `PreToolUse`/`Bash` em `~/.claude/settings.json` (chamando `rtk hook claude`) e cria `~/.claude/RTK.md`, referenciado via `@RTK.md` no `~/.claude/CLAUDE.md` global.

Escape hatch: `rtk proxy <comando>` roda sem filtro. Analytics: `rtk gain`.

**Cuidado com colisão de nome**: existe outro pacote "rtk" no crates.io ("Rust Type Kit") — não confundir se instalar via `cargo`.
