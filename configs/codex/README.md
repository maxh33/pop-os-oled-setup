# Codex (openai/codex-plugin-cc)

Plugin oficial da OpenAI para o Claude Code — orquestração/delegação de tarefas pesadas para o Codex CLI (`/codex:rescue`, `/codex:review`, `/codex:adversarial-review`, `/codex:transfer`, `/codex:status`, `/codex:result`, `/codex:cancel`).

## Reinstalação nesta máquina

```bash
npm install -g @openai/codex
claude plugin marketplace add openai/codex-plugin-cc
claude plugin install codex@openai-codex
codex login   # conta ChatGPT ou API key da OpenAI — nunca hardcodear a key
```

`config.toml` neste diretório é uma cópia de referência de `~/.codex/config.toml` (modelo/effort escolhidos pelo usuário, entradas de `trust_level` por projeto). Regra de roteamento (quando delegar pro Codex) documentada em `configs/claude/CLAUDE.md`, seção "AI Orchestration — Route Heavy Work to Codex".

**Não** foi adicionada uma entrada `trust_level = "trusted"` para o pop-os-oled-setup: os scripts deste projeto escrevem em hardware real via `sudo hda-verb`, então a revisão manual de todo diff do Codex (regra já global) fica ainda mais importante aqui do que em projetos containerizados.
