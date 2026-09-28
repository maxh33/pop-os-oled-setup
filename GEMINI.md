# GEMINI.md - Pop!_OS OLED Setup & System Reference

This file provides guidance to Google Antigravity (AGY) when working with code in this repository.

## Repository Overview

**pop-os-oled-setup** is a comprehensive setup guide, system configuration reference, and script repository for Pop!_OS 24.04 LTS (COSMIC desktop) with NVIDIA GPU and LG OLED displays. It also serves as the recovery reference for global development environments (ble.sh, fzf, wakatime, trivy, semgrep, rtk, agy).

## System Stack & Hardware Target

- **OS**: Pop!_OS 24.04 LTS with COSMIC desktop (Wayland)
- **GPU**: NVIDIA RTX 30/40 series (RTX 3070)
- **Audio Stack**: PipeWire + WirePlumber with critical ALSA bypass for HDMI distortion
- **Critical Fix**: `api.alsa.path = "hw:NVidia,3"` in WirePlumber config (bypasses buggy SPA-ALSA adapter).

---

## Token Optimization — RTK (Rust Token Killer)

- RTK is active on this system (`~/.local/bin/rtk`).
- Always prioritize `rtk <cmd>` (e.g. `rtk git status`, `rtk docker ps`, `rtk diff`).
- **Se notar output truncado, corrompido ou incoerente** — especialmente em comandos que tocam hardware/estado real do sistema (`sudo hda-verb`, `systemctl`, `udevadm`, `xrandr`, os scripts em `scripts/hdmi-audio-*.sh`) — avisar o usuário imediatamente antes de agir sobre esse output.
- Escape hatch: `rtk proxy <comando>` roda sem filtro.

---

## Development & Security Best Practices

### Key Custom Scripts
- **[gemini-git-helper.sh](file:///home/notexam/bin/gemini-git-helper.sh)**: AI-assisted commit helper and secret scanner.
  - Active copy: `/home/notexam/bin/gemini-git-helper.sh`
  - Reference copy: `scripts/gemini-git-helper.sh`
- **Global Git Hooks**: Located in `/home/notexam/bin/git-hooks/` (pre-commit, pre-push) to block leaks.

### Git Commit Convention
- Conventional Commits obrigatório (`feat:`, `fix:`, `docs:`, `perf:`, `refactor:`, `test:`, `chore:`).
- **Sem trailers `Co-Authored-By` e sem qualquer menção de atribuição de IA**.
- Mensagens de linha única e diretas.

### AI Orchestration
- Hand token-heavy execution tasks to Codex (`@openai/codex`).

---

## Repository Structure

```
pop-os-oled-setup/
├── configs/          # Backups e referências de configuração
│   ├── antigravity/  # AGY global GEMINI.md e settings.json
│   ├── claude/       # Claude Code configurations
│   ├── shell/        # Bash configs (blerc, inputrc, fzf, wakatime)
│   ├── rtk/          # RTK proxy configs
│   ├── pipewire/     # Configurações de áudio HDMI sem distorção
│   └── ...
├── docs/             # Guias passo a passo (01 a 25)
│   ├── 02-nvidia-hdmi-audio.md
│   ├── 09-gemini-setup.md
│   ├── 18-wsl2-vmmem-freeze.md
│   └── 25-antigravity-setup.md
└── scripts/          # Automações de instalação e hooks
```
