# Antigravity Global Instructions

## Core Security Principles

### 🔒 Environment Variables First (MANDATORY)

**NEVER hardcode credentials, API keys, or sensitive data in code.**

This is a non-negotiable security requirement for ALL projects.

#### Required Practices

1. **Use environment variables for ALL credentials:**
   - API keys, tokens, passwords
   - Database connection strings
   - Service account credentials
   - OAuth client secrets

2. **Storage locations (in order of preference):**
   - `~/.secrets` (chmod 600) — Global credentials, sourced by ~/.bashrc
   - Project `.env` files — Project-specific vars (MUST be in .gitignore)

3. **Reference in code:**
   ```python
   # ✅ CORRECT
   api_key = os.getenv('GEMINI_API_KEY')

   # ❌ WRONG - NEVER DO THIS
   api_key = 'AIzaSyC...'  # Hardcoded key
   ```

   ```javascript
   // ✅ CORRECT
   const apiKey = process.env.GEMINI_API_KEY;

   // ❌ WRONG - NEVER DO THIS
   const apiKey = 'AIzaSyC...';  // Hardcoded key
   ```

4. **Defense mechanisms (already active):**
   - gemini-git-helper.sh scans for hardcoded secrets
   - Pre-commit hook blocks commits with secrets
   - Pre-push hook blocks pushes with secrets
   - gitleaks scans commit history

---

## Custom Scripts

### gemini-git-helper.sh

**Location:** `/home/max/bin/gemini-git-helper.sh`  
**Usage:** Run `gemini-git-helper.sh` in any git repository

AI-powered git commit assistant that:
- Self-check blocks execution if script contains hardcoded secrets
- Scans for sensitive content (API keys, passwords, tokens)
- Scans commit history for leaked secrets (uses gitleaks/trufflehog)
- Validates .gitignore/.dockerignore patterns
- Groups changes by topic
- Suggests conventional commit messages using Gemini API
- Requires `GEMINI_API_KEY` environment variable (no hardcoded keys)

#### Command-Line Options

| Flag | Description |
|------|-------------|
| `--local, -l` | Use local analysis only (no API call) |
| `--pre-commit` | Fast secrets-only scan for git hooks (exit 1 if found) |
| `--pre-push RANGE` | Scan commits being pushed (for pre-push hook) |
| `--scan-history, -s` | Scan commit history for secrets |
| `--commits N` | Number of commits to scan (default: 50) |
| `--all-history` | Scan entire git history |
| `--since REF` | Scan commits since ref (branch/tag/commit) |
| `--help, -h` | Show help message |

#### Usage Examples

```bash
# Commit helper mode (default)
gemini-git-helper.sh              # Full analysis with Gemini API
gemini-git-helper.sh --local      # Quick local analysis (no API)

# History scanning mode (audit for leaked secrets)
gemini-git-helper.sh --scan-history           # Scan last 50 commits
gemini-git-helper.sh -s --commits 100         # Scan last 100 commits
gemini-git-helper.sh -s --all-history         # Scan entire history
gemini-git-helper.sh -s --since main          # Scan since main branch
```

#### Global Pre-Commit and Pre-Push Hooks

**Hooks Location:** `/home/max/bin/git-hooks/`  
**Enabled via:** `git config --global core.hooksPath /home/max/bin/git-hooks/`

The hooks:
- **pre-commit**: Blocks commits containing secrets (API keys, tokens, passwords)
- **pre-push**: Blocks pushes with secrets in commit history
- Run automatically in ALL git repos
- Can be bypassed with `--no-verify` (not recommended)

---

## Token Optimization (RTK - Rust Token Killer)

**RTK** is installed and configured to optimize token usage on CLI commands:
- Whenever running shell commands, prioritize `rtk <cmd>` (e.g. `rtk git status`, `rtk docker ps`) where applicable to reduce context overhead by 60-90%.
- Meta commands:
  - `rtk gain`: Show token savings analytics.
  - `rtk gain --history`: Show history and savings.
  - `rtk proxy <cmd>`: Run raw command without filtering (debugging / escape hatch).

---

## Development Environment

### Directory Structure

```
/mnt/storage/Programacao/Repositorios/          # Main repositories
/mnt/onedrive_storage/Programacao/Repositorios/ # Cloud-synced repositories
/home/max/projects/                             # Local projects
/home/max/bin/                                  # Custom scripts and utilities
/home/max/bin/git-hooks/                        # Global git hooks
```

### Bash Enhancements

**ble.sh** (Bash Line Editor) is installed and configured:
- Syntax highlighting as you type
- Fish-style auto-suggestions from history
- Gruvbox dark theme (matches Kitty terminal)

**fzf** (Fuzzy Finder) is configured:
- **Ctrl+R**: Fuzzy history search
- **Ctrl+T**: Fuzzy file search
- **Alt+C**: Fuzzy directory change
- History size: 50,000 commands

**Configuration files:**
- `~/.blerc` - ble.sh configuration (Gruvbox theme)
- `~/.inputrc` - Readline configuration (case-insensitive completion)

**WakaTime** (terminal activity tracking) is installed and configured:
- Tracks git, npm, python, docker, vim commands
- Auto-detects projects from .git root, package.json, pyproject.toml
- Dashboard: https://wakatime.com/dashboard
- Terminal integration via terminal-wakatime v1.1.5

**Configuration files:**
- `~/.wakatime.cfg` - WakaTime API key (chmod 600)
- `~/.wakatime/terminal-wakatime` - Terminal tracking binary

---

## Best Practices

### Code Generation

When generating code, ALWAYS:
- Use environment variable patterns (`os.getenv()`, `process.env`, `$VAR_NAME`)
- Never generate hardcoded credentials
- Suggest appropriate `.gitignore` entries for sensitive files
- Include comments documenting required environment variables
- Reference gemini-git-helper.sh for validation before commits

**Example generated code:**
```python
import os

# Required environment variables:
# - GEMINI_API_KEY: Your Gemini API key from Google AI Studio
# - DATABASE_URL: PostgreSQL connection string

api_key = os.getenv('GEMINI_API_KEY')
if not api_key:
    raise ValueError("GEMINI_API_KEY environment variable not set")

db_url = os.getenv('DATABASE_URL')
if not db_url:
    raise ValueError("DATABASE_URL environment variable not set")
```

### Code Analysis & Review

When analyzing code, ALWAYS:
- **Flag hardcoded secrets** found in code immediately
- Suggest extraction to environment variables
- Warn about security risks (git leaks, logs, error messages)
- Recommend running `gemini-git-helper.sh` to scan for secrets
- Check that sensitive files are in `.gitignore`

**If you find hardcoded secrets:**
1. **Alert the user immediately** with clear warning
2. Suggest the environment variable pattern to use
3. Recommend appropriate storage location (`~/.secrets`, `.env`)
4. Verify `.gitignore` patterns are present
5. Suggest running `gemini-git-helper.sh --scan-history` if already committed

### Template & Example Code

When providing templates or examples:
- Use obvious placeholders: `'YOUR_API_KEY'`, `'your-api-key-here'`
- Document required environment variables in comments
- Show the correct environment variable pattern
- Never use realistic-looking fake credentials (could be mistaken for real ones)

---

## AI Orchestration — Route Heavy Work to Codex

The `codex@openai-codex` CLI is installed globally via npm (`@openai/codex`).

**Hand token-heavy execution tasks to Codex instead of running them here:**
- Bulk file edits across many files
- Well-specced builds where the requirements are already fully defined
- Bugs still failing after 2 fix attempts in this session

---

## Security Workflow Integration

### Before Committing Code

**Always remind the user to:**
```bash
# 1. Scan for hardcoded secrets
gemini-git-helper.sh

# 2. Review the output
# 3. Fix any issues found
# 4. Re-scan to verify clean
gemini-git-helper.sh

# 5. Then commit (hooks will also check)
git add .
git commit -m "feat: add feature"
```

### If Secrets Found in Commit History

**Guide the user through remediation:**
```bash
# 1. Scan commit history
gemini-git-helper.sh --scan-history --all-history

# 2. If secrets found, IMMEDIATELY:
#    a. Rotate/revoke exposed credentials
#    b. Clean git history with BFG or git filter-repo
#    c. Force push and notify collaborators
```

---

## Common Patterns by Language

### Python
```python
import os
from dotenv import load_dotenv  # Optional: python-dotenv package

load_dotenv()  # Load from .env file

api_key = os.getenv('GEMINI_API_KEY')
```

### Node.js/JavaScript
```javascript
// Using dotenv package
require('dotenv').config();

const apiKey = process.env.GEMINI_API_KEY;
```

### Bash/Shell
```bash
# Source from .env file
set -a
source .env
set +a

# Or use directly
API_KEY="${GEMINI_API_KEY}"
```

### Ruby
```ruby
require 'dotenv/load'  # Optional: dotenv gem

api_key = ENV['GEMINI_API_KEY']
```

### Go
```go
import "os"

apiKey := os.Getenv("GEMINI_API_KEY")
```

---

## Git Commit Convention

Use conventional commits format:
- `feat(scope): description` - New features
- `fix(scope): description` - Bug fixes
- `docs: description` - Documentation
- `refactor(scope): description` - Code refactoring
- `chore: description` - Maintenance tasks
- `test(scope): description` - Tests

**IMPORTANT COMMIT RULES:**
- **NEVER add `Co-Authored-By` trailers** to commit messages
- **NO AI attribution** in commits (no "Co-Authored-By: Claude" or "Co-Authored-By: Antigravity" or similar)
- Keep commit messages clean: just the conventional commit format, no trailers
- Single-line commit messages without additional attribution

---

## Git Aliases

Configured global git aliases for faster workflow:

### Basic Shortcuts
- `git st` → `git status`
- `git co` → `git checkout`
- `git br` → `git branch`
- `git cm "message"` → `git commit -m "message"`

### Viewing & Logs
- `git lg` → Beautiful graph log (oneline, all branches)
- `git ls` → Detailed log with dates and authors
- `git last` → Show last commit
- `git df` → Colored diff with word-level changes
- `git dfs` → Colored diff for staged changes

### Undo & Amend
- `git undo` → Undo last commit (keep changes staged)
- `git unstage` → Unstage files
- `git amend` → Amend last commit (no message change)
- `git amendc` → Amend last commit (edit message)

### Information
- `git aliases` → List all git aliases
- `git branches` → List all branches (local + remote)
- `git tags` → List all tags
- `git contributors` → Show commit counts by author

---

## Automação Agêntica de Navegador (Browser Session Policy)

### 🌐 Conexão Obrigatória com a Sessão Real do Usuário (Anti-Perfil Virgem)

Ao realizar qualquer tarefa de automação de navegador (inspeção de páginas, navegação agêntica, leitura de mensagens autenticadas, portais com SSO):
1. **SEMPRE priorizar a conexão com a sessão real do navegador indicada pelo usuário**:
   - Via MCP `claude-in-chrome` (bridge direto com a extensão ativa no Brave/Chrome principal).
   - Ou via CDP (`--remote-debugging-port=9222`) conectado ao processo real do navegador.
2. **NUNCA clonar perfis para `/tmp` nem criar instâncias virgens**:
   - Clonar pastas de perfil quebra a assinatura HMAC de segurança do Chromium (`Secure Preferences`), desabilitando silenciosamente todas as extensões do usuário (1Password, Dark Reader, adblockers).
   - Sessões virgens exigem reautenticação manual desnecessária e escaneamento de QR Code (ex: WhatsApp Web).
3. **Execução Local via MCP `claude-in-chrome`**:
   - Priorizar ferramentas de execução direta no DOM (`javascript_tool`, `get_page_text`, `navigate`, `tabs_context_mcp`, `browser_batch`).
   - Evitar ferramentas que invoquem APIs externas da Anthropic (como `find`), garantindo zero consumo de limites semanais e controle 100% autônomo pelo Antigravity / Gemini.

---

## This Applies to ALL Projects

**No exceptions:**
- Development scripts
- Test files
- Configuration files
- Database migrations
- CI/CD pipelines
- Documentation examples
- Jupyter notebooks
- Docker files
- Infrastructure as Code (Terraform, CloudFormation, etc.)

**NEVER hardcode credentials. ALWAYS use environment variables.**

