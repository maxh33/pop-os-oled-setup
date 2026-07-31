# Claude Code - Repository Context

## Repository Overview

**pop-os-oled-setup** is a comprehensive setup guide and configuration repository for Pop!_OS with NVIDIA GPU and OLED displays, specifically focused on solving HDMI audio distortion issues with PipeWire.

### Purpose

This repository serves as:
1. **System Configuration Reference** - Documented configs for recovery and replication
2. **Setup Scripts** - Automated installation and configuration tools
3. **Documentation Hub** - Guides for hardware, software, and workflow setup
4. **Backup Repository** - Critical system files and custom scripts

### Target Environment

- **OS**: Pop!_OS 24.04 LTS with COSMIC desktop
- **Hardware**: NVIDIA RTX 30/40 series + LG OLED TV/Monitor
- **Audio Stack**: PipeWire + WirePlumber (with critical HDMI fix)

---

## Claude Code — RTK (compressão de tokens)

O hook global do RTK (`rtk-ai/rtk`) está ativo e reescreve comandos Bash automaticamente para reduzir tokens de output (`~/.claude/settings.json`, hook `PreToolUse`/`Bash`). Já validado sem corrupção em `cat -n`/`grep -n`/`sed -n` no joiasmax-ecommerce.

**Se notar output truncado, corrompido ou incoerente** — especialmente em comandos que tocam hardware/estado real do sistema (`sudo hda-verb`, `systemctl`, `udevadm`, `xrandr`, os scripts em `scripts/hdmi-audio-*.sh`) — avisar o usuário imediatamente antes de agir sobre esse output. Escape hatch: `rtk proxy <comando>` roda sem filtro. Reverter tudo: restaurar `~/.claude/settings.json.bak`.

## Claude Code — Ponytail (disciplina anti-over-engineering)

Plugin `ponytail@ponytail` (`DietrichGebert/ponytail`) instalado globalmente — injeta, via hooks (`SessionStart`/`SubagentStart`/`UserPromptSubmit`), uma escada de decisão YAGNI/stdlib-first antes de qualquer implementação (existe necessidade real? já tem no código? stdlib resolve? recurso nativo? dependência já instalada? uma linha? só então código novo). Nível padrão fixado em `full` via `~/.config/ponytail/config.json`.

Validado com mini-benchmark próprio (3 tickets oficiais do projeto, n=1, Sonnet 5, repo `tiangolo/full-stack-fastapi-template`@`cd83fc10`): -60% linhas de código, -36% custo, -67% tempo no total dos 3 tickets vs. baseline sem o skill — sem cortar nenhuma checagem de segurança/permissão nos 6 diffs revisados manualmente. Um dos 3 tickets teve o efeito invertido (o skill escreveu *mais* código porque adicionou testes pro endpoint novo) — o objetivo declarado da ferramenta nunca foi "menos tokens", é "só o que a tarefa precisa, sem cortar validação/segurança".

## Trivy + Semgrep (varredura de segurança manual)

`trivy` (SCA/imagem/IaC) e `semgrep` (SAST) instalados localmente sem sudo — `configs/trivy/README.md` e `configs/semgrep/README.md` têm reinstalação completa. Cobrem o que o secret-scan dos git hooks não cobre. Ainda é uso manual — não está em hook de git nem em VPS nenhuma, decisão pendente até o workflow manual se provar no dia a dia.

**Cuidado com WSL2**: rodar `trivy image` em lote (várias imagens grandes) ou `semgrep --config=auto` num repo sem cap de memória configurado pode travar a VM inteira (não só um terminal — todo WSL, exige reboot do Windows). Ver `docs/18-wsl2-vmmem-freeze.md` e `configs/wsl/.wslconfig` antes de rodar essas ferramentas numa máquina WSL nova.

---

## Repository Structure

```
pop-os-oled-setup/
├── configs/          # System configuration files
│   ├── claude/       # Claude Code configurations
│   ├── gemini/       # Gemini CLI global instructions
│   ├── shell/        # Bash configs (blerc, inputrc, fzf, wakatime)
│   ├── kitty/        # Kitty terminal configuration
│   ├── pipewire/     # PipeWire/WirePlumber configs (HDMI audio fix)
│   ├── systemd/      # Systemd service files
│   ├── wakatime/     # WakaTime configuration
│   └── ...           # Other system configs
│
├── scripts/          # Custom automation scripts
│   ├── gemini-git-helper.sh    # AI-powered git commit assistant
│   ├── git-hooks/              # Global git hooks (pre-commit, pre-push)
│   ├── hdmi-audio-*.sh         # HDMI audio troubleshooting scripts
│   └── install.sh              # Main installation script
│
├── docs/             # Detailed setup documentation
│   ├── 02-nvidia-hdmi-audio.md       # CRITICAL: HDMI audio fix
│   ├── 05-development-tools.md       # Dev environment setup
│   ├── 09-gemini-setup.md            # Gemini CLI + git helper
│   ├── 10-fzf-history-search.md      # fzf setup
│   ├── 11-blesh-setup.md             # ble.sh setup
│   ├── 15-wakatime-setup.md          # WakaTime tracking
│   └── ...                            # Other guides
│
└── README.md         # Quick start and overview
```

---

## Key Scripts

### gemini-git-helper.sh

**Location (Active):** `/home/notexam/bin/gemini-git-helper.sh`
**Location (Reference):** `scripts/gemini-git-helper.sh`

AI-powered git commit assistant that:
- Scans for hardcoded secrets before commits
- Validates .gitignore/.dockerignore patterns
- Groups changes by topic
- Suggests conventional commit messages using Gemini API
- Scans commit history for leaked secrets

**Important:** The active copy is in `~/bin/`, the copy in this repo is a reference backup for system recovery.

See `docs/09-gemini-setup.md` for full documentation.

### Global Git Hooks

**Location (Active):** `/home/notexam/bin/git-hooks/`
**Location (Reference):** `scripts/git-hooks/`

- **pre-commit**: Fast secrets-only scan, blocks commits with sensitive data
- **pre-push**: Scans commit range being pushed, blocks if secrets found

Enabled globally via: `git config --global core.hooksPath ~/bin/git-hooks`

---

## Configuration Files

### Shell Enhancements

- **configs/shell/blerc** - ble.sh configuration (Gruvbox theme, auto-suggestions)
- **configs/shell/inputrc** - Readline config (case-insensitive completion)
- **configs/shell/bashrc-fzf** - fzf fuzzy finder configuration
- **configs/shell/bashrc-wakatime** - WakaTime terminal tracking

### AI Tool Configurations

- **configs/gemini/GEMINI.md** - Global security principles and patterns for Gemini CLI
- **configs/claude/CLAUDE.md** - This file, adapted for Claude Code

---

## Development Workflow

### Commit Convention

This repository uses conventional commits:
- `feat(scope): description` - New features
- `fix(scope): description` - Bug fixes
- `docs: description` - Documentation updates
- `refactor(scope): description` - Code refactoring
- `chore: description` - Maintenance tasks
- `test(scope): description` - Tests

**IMPORTANT COMMIT RULES:**
- **NEVER add `Co-Authored-By` trailers** to commit messages
- **NO AI attribution** in commits (no "Co-Authored-By: Claude" or similar)
- Keep commit messages clean: just the conventional commit format, no trailers
- Single-line commit messages without additional attribution

### Before Committing

1. **Run gemini-git-helper.sh** to scan for secrets and get commit suggestions:
   ```bash
   gemini-git-helper.sh              # Full analysis with Gemini API
   gemini-git-helper.sh --local      # Quick local analysis (no API)
   ```

2. **Review changes** and ensure no sensitive data is included

3. **Commit** using suggested messages (hooks will automatically verify):
   ```bash
   git add <files>
   git commit -m "feat(scope): description"
   ```

### Security Principles

**CRITICAL:** Never hardcode credentials in any file in this repository.

- API keys must be in `~/.secrets` or `.env` files (gitignored)
- Use environment variable patterns: `os.getenv()`, `process.env`, `$VAR_NAME`
- Pre-commit hooks will block commits containing secrets
- Run `gemini-git-helper.sh --scan-history` to audit commit history

---

## Common Tasks

### Adding New Configuration Files

1. **Place config in appropriate `configs/` subdirectory**
2. **Document in corresponding `docs/` markdown file**
3. **Update install.sh if auto-installation is needed**
4. **Test on a clean system or WSL instance**

### Adding New Scripts

1. **Place script in `scripts/` directory**
2. **Add documentation to relevant `docs/` file**
3. **Ensure script uses environment variables for any credentials**
4. **Make executable**: `chmod +x scripts/your-script.sh`
5. **Test thoroughly before committing**

### Updating Documentation

1. **Follow existing markdown structure**
2. **Use clear step-by-step instructions**
3. **Include command examples with expected output**
4. **Document prerequisites and dependencies**
5. **Add troubleshooting section if applicable**

---

## Special Considerations

### Path Differences

When adapting configs from this repository:
- **Original system**: `/home/max/`
- **WSL/Other systems**: Update paths accordingly (e.g., `/home/notexam/`)
- Scripts that reference hardcoded paths may need adjustment

### Environment-Specific Files

Some configs are environment-specific:
- **PipeWire/WirePlumber**: Requires NVIDIA GPU + HDMI audio setup
- **COSMIC desktop**: Pop!_OS specific
- **systemd services**: May need adjustment for other distributions

### Reusable Components

These are universally applicable:
- gemini-git-helper.sh (works on any Linux/WSL with Bash 4+)
- Git hooks (pre-commit, pre-push)
- Shell enhancements (ble.sh, fzf configs)
- Security patterns and conventions

---

## Testing & Verification

### After Making Changes

1. **Run gemini-git-helper.sh** to check for secrets
2. **Test scripts on a non-production system first**
3. **Verify documentation accuracy**
4. **Update version numbers if applicable**

### Before Pushing

1. **Ensure all sensitive data is removed**
2. **Run history scan**: `gemini-git-helper.sh --scan-history`
3. **Verify pre-push hook runs successfully**
4. **Check that all links in documentation work**

---

## Related Documentation

For global Claude Code context, see: `/home/notexam/CLAUDE.md`

For specific setup guides, see the `docs/` directory.
