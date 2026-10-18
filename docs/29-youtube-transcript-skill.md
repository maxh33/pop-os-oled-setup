# 29 — Skill global youtube-transcript

Skill do Claude Code que extrai a transcrição (legendas) de vídeos do YouTube. Cópia de referência em `configs/claude/skills/youtube-transcript/SKILL.md`.

## Por que existe

A skill `youtube-transcript-chrome`, que vem da pasta `~/.claude/skills/synced/` (sincronizada pela conta claude.ai e sobrescrita no sync), depende do Claude in Chrome. Ela falha quando a janela do Chrome do grupo de abas do MCP está minimizada ou em segundo plano: `document.visibilityState` fica `hidden`, o `requestAnimationFrame` não dispara e o YouTube nunca carrega o painel de transcrição. Não há contorno por JavaScript.

O método principal da skill nova é o `yt-dlp` só com legendas, sem navegador, sem conta e sem serviço de terceiros. O Chrome fica como plano B, com checagem de visibilidade antes.

## Instalação

```bash
mkdir -p ~/.claude/skills/youtube-transcript
cp configs/claude/skills/youtube-transcript/SKILL.md ~/.claude/skills/youtube-transcript/SKILL.md
```

Reiniciar o Claude Code: a lista de skills só é lida ao iniciar a sessão.

## Dependência

`yt-dlp` não está instalado no sistema. A skill usa o checkout em `/mnt/storage/Programacao/Repositorios/download-youtube-video-audio/yt-dlp`, chamado por `python3 -I` com `sys.path`. Em máquina nova, clonar o `yt-dlp` nesse caminho ou ajustar o caminho na skill (ou `uv tool install yt-dlp` e trocar o comando).

## Cuidados medidos

- Pedir um idioma por chamada. Pedir `en.*,pt.*` em dois vídeos seguidos deu HTTP 429 no segundo.
- Para legenda automática em português usar `pt-orig`.
- Legendas automáticas não têm pontuação e erram nomes e números.
- Não usar serviços pagos de transcrição de terceiros (ex.: TranscriptAPI), que recebem cada vídeo e exigem conta.
- Validado em 2026-10-18 com um vídeo de 7 min (EN) e um de 30 min (PT).

## Relacionado

- Pasta synced: `~/.claude/skills/synced/<org>_<user>/` (não editar, é gerenciada pela conta).
