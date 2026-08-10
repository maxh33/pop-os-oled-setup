# OpenCode (sst/opencode)

CLI open-source de agentes de codificação — alternativa/suplemento ao Claude Code. Compatibilidade com o setup deste repositório documentada aqui.

## Reinstalação nesta máquina

```bash
# 1. Copiar as diretrizes globais (equivale ao ~/.claude/CLAUDE.md do Claude Code)
cp configs/opencode/AGENTS.md ~/AGENTS.md

# 2. Ativar RTK (compressão de tokens) no opencode
rtk init -g --opencode
# Cria ~/.config/opencode/plugins/rtk.ts — intercepta tool.execute.before,
# reescreve comandos Bash para rtk equivalents, transparente pro agente.
```

Reiniciar o opencode após instalar. Verificar com `git status` (output comprimido).

## Matriz de compatibilidade das ferramentas deste repo

| Ferramenta | Funciona no opencode? | Como |
|---|---|---|
| **RTK** | ✅ Nativamente | `rtk init -g --opencode` → plugin TypeScript (`tool.execute.before`) |
| **Caveman** | ❌ Não | Plugin do marketplace Claude Code; opencode não carrega plugins Claude Code |
| **Ponytail** | ⚠️ Parcial (replicável) | A escada YAGNI/stdlib-first foi embutida no `AGENTS.md` global — sem plugin equivalente dedicado |
| **Codex plugin** | ❌ Não | Orquestração `/codex:*` é do Claude Code |
| **Trivy** | ✅ Sim | CLI standalone (`~/.local/bin/trivy`) — auditoria manual, independente do agente |
| **Semgrep** | ✅ Sim | CLI standalone (`uv tool install semgrep`) — auditoria manual, independente do agente |
| **MCP servers** | ✅ Sim | Mesmos servidores (context7, desktop-commander, playwright, gemini...) configuráveis via `~/.config/opencode/opencode.json` |

## O que o AGENTS.md global cobre

O `configs/opencode/AGENTS.md` (deploy → `~/AGENTS.md`) replica as diretrizes globais independente da CLI:

- **Env-vars first** — credenciais só em `~/.secrets` (chmod 600), nunca hardcoded
- **Git guardrails** — hooks globais `~/bin/git-hooks/` (pre-commit/pre-push), `gemini-git-helper.sh`, conventional commits, sem trailers de IA
- **Token optimization (RTK)** — como funciona, escape hatch `rtk proxy`, analytics `rtk gain`
- **YAGNI/stdlib-first** — escada de decisão equivalente ao plugin Ponytail
- **Auditoria manual** — trivy/semgrep (com aviso de memória em WSL2)
- **MCP servers** — principais disponíveis

## Notas

- RTK é o único com integração nativa no opencode; os plugins de token/style do Claude Code (Caveman, Ponytail, Codex) não têm equivalente 1:1.
- Este documento é espelho de `configs/claude/CLAUDE.md` (que documenta o mesmo setup para Claude Code).
