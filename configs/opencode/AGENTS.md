# Global Guidelines — opencode

## 🔒 Environment Variables First (MANDATORY)

**NEVER hardcode credentials, API keys, or sensitive data in code.**

- API keys, tokens, passwords, DB connection strings, OAuth secrets → environment variables.
- Storage: `~/.secrets` (chmod 600, sourced by `~/.bashrc`) — global keys; project `.env` (MUST be gitignored).
- Reference in code: `os.getenv('VAR')`, `process.env.VAR`, `$VAR` — never literal values.
- If you find a hardcoded secret: stop, extract to env var, add to `.gitignore`, verify clean.

## Git Guardrails

- Global hooks at `~/bin/git-hooks/` (pre-commit, pre-push) via `git config --global core.hooksPath`:
  - Block commits/pushes containing secrets (scans via `gemini-git-helper.sh`).
  - Never bypass with `git commit --no-verify` / `git push --no-verify`.
- Run `gemini-git-helper.sh` before committing; `--scan-history` to audit leaked secrets.
- Commit convention: conventional commits (`feat(scope):`, `fix(scope):`, `docs:`, `refactor:`, `chore:`).
- **NEVER** add `Co-Authored-By` trailers or AI attribution to commit messages.

## Token Optimization (RTK)

- RTK (`rtk-ai/rtk`) is active globally and rewrites Bash commands automatically to reduce output tokens.
- Escape hatch: `rtk proxy <command>` runs without filtering. Analytics: `rtk gain`.
- If command output looks truncated/corrupted — especially for commands touching real system state (`sudo`, `systemctl`, `xrandr`, hardware) — warn the user before acting on that output.

## Implementation Discipline (YAGNI / stdlib-first)

Before writing new code, walk the ladder:
1. Is there a real need? 2. Does it already exist in the codebase? 3. Does the standard library solve it? 4. Native platform feature? 5. Already-installed dependency? 6. Does it fit in one line?
Only then write new code. Never cut security/permission checks in the name of brevity.

## Security Audit Tools (manual)

- `trivy` (SCA/image/IaC) and `semgrep` (SAST) are installed locally without sudo — manual audit, not hooks.
- Mind memory: on WSL2, heavy `trivy image`/`semgrep --config=auto` batches without a memory cap can freeze the whole VM.

## MCP Servers

Available: `context7` (docs), `desktop-commander` (system ops), `playwright` (browser), `gemini` (analysis), `linear` (issues), `server-configs-docs` (Claude Code config).
- Prefer context7 for library docs over web search.
- Offload heavy analysis to Gemini MCP to save context.

## Environment

- OS: Pop!_OS 24.04 LTS (COSMIC), NVIDIA + LG OLED, PipeWire.
- Paths: repos in `/mnt/storage/Programacao/Repositorios/`, projects in `/home/max/projects/`.
- See also: `~/.claude/CLAUDE.md` for the Claude Code equivalent of these guidelines.
