# Global Claude Code Guidelines

## Core Development Principles

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
   - `~/.gemini/.env` — Gemini CLI-specific keys
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

   ```bash
   # ✅ CORRECT
   curl -H "Authorization: Bearer $GEMINI_API_KEY" https://api.example.com

   # ❌ WRONG - NEVER DO THIS
   curl -H "Authorization: Bearer AIzaSyC..." https://api.example.com
   ```

4. **Defense mechanisms (already active):**
   - gemini-git-helper.sh scans for hardcoded secrets
   - Pre-commit hook blocks commits with secrets
   - Pre-push hook blocks pushes with secrets
   - gitleaks scans commit history

#### When Writing Code

- **Before committing:** Run `gemini-git-helper.sh` to scan for secrets
- **Use placeholders in templates:** `'your-api-key-here'`, `'YOUR_API_KEY'`
- **Document env vars:** List required env vars in project README
- **Never bypass hooks:** Don't use `git commit --no-verify` to skip secret detection

#### If You Find Hardcoded Secrets

1. **Stop immediately** — Do NOT commit
2. Extract to environment variable
3. Add to appropriate `.gitignore` pattern
4. Run `gemini-git-helper.sh` to verify clean

**This applies to ALL programming languages, ALL frameworks, ALL projects.**

---

## Custom Scripts

### gemini-git-helper.sh (v3.0)
**Location:** `/home/max/bin/gemini-git-helper.sh`

AI-powered git commit assistant with **defense-in-depth** secret protection:
- Self-check blocks execution if script contains hardcoded secrets
- Pre-commit hook blocks commits with secrets
- Pre-push hook blocks pushes with secrets
- **`--quiet` mode** (NEW in v3.0 — suppresses decorative output, works in Claude Code/CI)
- **Improved `--local` mode** (NEW in v3.0 — directory-based grouping, multi-commit suggestions)
- **Capped file previews** (NEW in v3.0 — max 10 files/50 lines, reduces API token waste)
- Uses temp file for API requests (v2.5 — fixes "Argument list too long")
- Smart diff truncation at 100KB for API calls
- Scans commit history for leaked secrets (uses gitleaks)
- Validates .gitignore/.dockerignore patterns
- Groups changes by topic
- Suggests conventional commit messages
- Requires `GEMINI_API_KEY` environment variable (no hardcoded keys)

#### Commit Helper Mode (default)
```bash
cd /path/to/repo && gemini-git-helper.sh                   # Full analysis with Gemini API
cd /path/to/repo && gemini-git-helper.sh --quiet           # Minimal output (Claude Code/CI)
cd /path/to/repo && gemini-git-helper.sh --local           # Local grouped analysis (no API)
cd /path/to/repo && gemini-git-helper.sh --local --quiet   # Compact grouped suggestions
```

#### History Scanning Mode (audit existing commits)
```bash
# Scan last 50 commits (default)
gemini-git-helper.sh --scan-history

# Scan specific number of commits
gemini-git-helper.sh -s --commits 100

# Scan entire git history
gemini-git-helper.sh -s --all-history

# Scan commits since a branch/tag/commit
gemini-git-helper.sh -s --since main
gemini-git-helper.sh -s --since v1.0.0
gemini-git-helper.sh -s --since abc1234
```

#### Options
| Flag | Description |
|------|-------------|
| `--local, -l` | Use local analysis only (no API call) — now with grouped suggestions |
| `--quiet, -q` | Suppress decorative output (keep errors, warnings, suggestions) |
| `--pre-commit` | Fast secrets-only scan for git hooks (exit 1 if found) |
| `--pre-push RANGE` | Scan commits being pushed (for pre-push hook) |
| `--scan-history, -s` | Scan commit history for secrets |
| `--commits N` | Number of commits to scan (default: 50) |
| `--all-history` | Scan entire git history |
| `--since REF` | Scan commits since ref (branch/tag/commit) |
| `--help, -h` | Show help message |

#### Scanner Priority
- **Hooks (pre-commit, pre-push)**: gitleaks > native (speed-critical)
- **--scan-history mode**: gitleaks > trufflehog > native (thoroughness)

#### Install gitleaks (recommended)
```bash
sudo apt install gitleaks    # Debian/Ubuntu
sudo snap install gitleaks   # Snap
brew install gitleaks        # macOS
```

#### Global Git Hooks (Defense-in-Depth)
Global hooks are enabled via: `git config --global core.hooksPath /home/max/bin/git-hooks/`

**Pre-Commit Hook** (`/home/max/bin/git-hooks/pre-commit`):
- Runs `gemini-git-helper.sh --pre-commit`
- Blocks commits containing secrets
- Bypass: `git commit --no-verify` (not recommended)

**Pre-Push Hook** (`/home/max/bin/git-hooks/pre-push`):
- Runs `gemini-git-helper.sh --pre-push <range>`
- Scans commits being pushed for secrets
- Last-line defense before secrets reach remote
- Bypass: `git push --no-verify` (not recommended)

**Defense Chain:**
```
1. Self-check       -> Script refuses to run if it contains secrets
2. Pre-commit hook  -> Blocks commits with secrets
3. Pre-push hook    -> Blocks pushes with secrets
4. --scan-history   -> Audit existing commits
```

---

## MCP Servers

| Server | Purpose | Best For |
|--------|---------|----------|
| context7 | Library documentation | Current API docs, framework references |
| server-configs-docs | Claude Code configuration | Setup help, config file syntax |
| desktop-commander | File/process automation | System ops outside Claude sandbox |
| playwright | Browser automation | Web testing, scraping dynamic content |
| linear | Issue tracking | Project management automation |
| gemini | Gemini AI assistant | Heavy analysis, context offloading |

### MCP Strategy Guide

**Decision Matrix - Which MCP to use:**

| Task | Use This MCP | Why |
|------|--------------|-----|
| Need current library docs | context7 | Always up-to-date, reduces hallucination |
| Heavy file/codebase analysis | gemini | Saves Claude's context window |
| Web scraping/testing | playwright | Full browser automation |
| System file operations | desktop-commander | Works outside Claude sandbox |
| Project management | linear | Direct Linear integration |
| Claude Code setup help | server-configs-docs | Official config documentation |

**Context-Saving Strategy:**
1. Use Gemini MCP for large codebase analysis (>500 lines)
2. Use context7 for library docs instead of web search
3. Offload repetitive file operations to desktop-commander
4. Chain MCPs: Gemini analyzes → Linear creates issue

---

### context7 - Library Documentation

Up-to-date documentation for any library/framework. Avoids outdated info from training data.

**Usage Pattern:**
1. First resolve the library ID: `resolve-library-id`
2. Then query specific documentation: `query-docs`

**Tools:**
| Tool | Description |
|------|-------------|
| `resolve-library-id` | Find the correct library identifier |
| `query-docs` | Query documentation with specific topic |

**Examples:**
```
# Get React hooks documentation
1. resolve-library-id: "react"
2. query-docs: { libraryId: "/react/react", topic: "useEffect cleanup" }

# Get Node.js fs module docs
1. resolve-library-id: "nodejs"
2. query-docs: { libraryId: "/nodejs/node", topic: "fs promises API" }

# Get TypeScript configuration
1. resolve-library-id: "typescript"
2. query-docs: { libraryId: "/typescript/typescript", topic: "tsconfig strict mode" }
```

**Best For:**
- Current API references (avoids outdated training data)
- Framework-specific patterns and best practices
- Library migration guides
- Understanding new library features

---

### desktop-commander - System Automation

File and process operations outside Claude's sandbox. Use when Claude's built-in tools can't access something.

**Capabilities:**
| Tool | Description |
|------|-------------|
| `read_file` | Read any file on system |
| `read_multiple_files` | Read several files at once |
| `write_file` | Write/create files |
| `edit_block` | Edit specific blocks in files |
| `list_directory` | List directory contents |
| `create_directory` | Create new directories |
| `move_file` | Move/rename files |
| `get_file_info` | Get file metadata |
| `start_process` | Launch processes |
| `list_processes` | Show running processes |
| `kill_process` | Terminate processes |
| `read_process_output` | Get process stdout/stderr |

**Examples:**
```
# Read a system config file
read_file: { path: "/etc/nginx/nginx.conf" }

# List a protected directory
list_directory: { path: "/var/log" }

# Start a background process
start_process: { command: "npm", args: ["run", "dev"], cwd: "/path/to/project" }

# Monitor running processes
list_processes: {}

# Kill a stuck process
kill_process: { pid: 12345 }
```

**Best For:**
- Reading system configuration files
- Managing background processes
- File operations in protected directories
- Batch file operations
- Process monitoring and management

---

### playwright - Browser Automation

Full browser control for testing and web scraping. Handles JavaScript-rendered content.

**Capabilities:**
| Tool | Description |
|------|-------------|
| `browser_navigate` | Go to URL |
| `browser_snapshot` | Get page accessibility tree (for element selection) |
| `browser_click` | Click elements |
| `browser_fill` | Fill form fields |
| `browser_type` | Type text character by character |
| `browser_select_option` | Select dropdown options |
| `browser_hover` | Hover over elements |
| `browser_press_key` | Press keyboard keys |
| `browser_take_screenshot` | Capture screenshot |
| `browser_evaluate` | Run JavaScript in page context |
| `browser_wait_for` | Wait for element/condition |
| `browser_tabs` | Manage browser tabs |
| `browser_close` | Close the browser |

**Workflow:**
1. Navigate to page: `browser_navigate`
2. Get page structure: `browser_snapshot` (returns accessibility tree with element refs)
3. Interact using refs from snapshot: `browser_click`, `browser_fill`, etc.
4. Capture results: `browser_take_screenshot` or `browser_evaluate`

**Examples:**
```
# Navigate and get page structure
browser_navigate: { url: "https://example.com/login" }
browser_snapshot: {}  # Returns element refs like ref="login-button"

# Fill login form (use refs from snapshot)
browser_fill: { ref: "email-input", value: "test@example.com" }
browser_fill: { ref: "password-input", value: "password123" }
browser_click: { ref: "login-button" }

# Wait for navigation then screenshot
browser_wait_for: { selector: ".dashboard" }
browser_take_screenshot: {}

# Extract data with JavaScript
browser_evaluate: { expression: "document.querySelector('.price').textContent" }
```

**Best For:**
- Testing web applications end-to-end
- Scraping JavaScript-rendered content
- Form automation and submission
- Visual regression testing
- Debugging frontend issues

---

### linear - Issue Tracking

Direct integration with Linear project management. Automate issue creation and tracking.

**Capabilities:**
| Tool | Description |
|------|-------------|
| `create_issue` | Create new issue |
| `update_issue` | Update existing issue |
| `get_issue` | Get issue details |
| `list_issues` | List issues with filters |
| `create_comment` | Add comment to issue |
| `list_comments` | List issue comments |
| `list_projects` | List all projects |
| `get_project` | Get project details |
| `list_teams` | List teams |
| `get_team` | Get team details |
| `list_cycles` | List sprints/cycles |
| `create_document` | Create documentation |

**Examples:**
```
# Create a bug report
create_issue: {
  title: "Fix login timeout on slow connections",
  description: "Users report timeout errors when...\n\n## Steps to Reproduce\n1. ...",
  teamId: "TEAM_ID",
  priority: 2,
  labelIds: ["bug", "high-priority"]
}

# List open bugs assigned to me
list_issues: {
  filter: {
    assignee: { isMe: { eq: true } },
    state: { type: { eq: "started" } },
    labels: { name: { eq: "bug" } }
  }
}

# Update issue status
update_issue: {
  issueId: "ISSUE_ID",
  stateId: "STATE_ID_FOR_DONE"
}

# Add implementation notes
create_comment: {
  issueId: "ISSUE_ID",
  body: "Fixed in commit abc123. Root cause was..."
}
```

**Best For:**
- Automated issue creation from code analysis
- Project status queries and reporting
- Workflow automation (move issues through states)
- Linking code changes to issues

---

### server-configs-docs - Claude Code Configuration

Documentation for Claude Code configuration files and setup.

**Capabilities:**
| Tool | Description |
|------|-------------|
| `fetch_server_configs_docs` | Get configuration documentation |
| `search_server_configs_docs` | Search docs by keyword |
| `search_server_configs_code` | Search example configurations |

**Examples:**
```
# Get MCP server configuration help
fetch_server_configs_docs: { topic: "mcp-servers" }

# Search for hook examples
search_server_configs_docs: { query: "pre-commit hooks" }

# Find example configs
search_server_configs_code: { query: "settings.json example" }
```

**Best For:**
- Setting up Claude Code for first time
- Configuring MCP servers
- Understanding settings.json options
- Hook configuration examples

---

### gemini - AI Analysis Assistant

Offload heavy analysis to Gemini to preserve Claude's context window.

**Capabilities:**
| Tool | Works | Use Case |
|------|-------|----------|
| `gemini-analyze-code` | ✅ | Analyze code files |
| `gemini-analyze-text` | ✅ | Analyze text content |
| `gemini-analyze-image` | ✅ | Analyze images |
| `gemini-analyze-url` | ✅ | Analyze web pages |
| `gemini-search` | ✅ | Web search via Gemini |
| `gemini-summarize` | ✅ | Summarize long content |
| `gemini-summarize-pdf` | ✅ | Summarize PDF documents |
| `gemini-brainstorm` | ✅ | Generate ideas |
| `gemini-deep-research` | ✅ | In-depth research on topic |
| `gemini-youtube` | ✅ | Analyze YouTube videos |
| `gemini-youtube-summary` | ✅ | Summarize YouTube videos |
| `gemini-structured` | ✅ | Extract structured data |
| `gemini-extract` | ✅ | Extract specific info |

**Examples:**
```
# Analyze a large codebase
gemini-analyze-code: {
  files: ["/path/to/src/**/*.ts"],
  prompt: "Find security vulnerabilities"
}

# Research a topic
gemini-deep-research: {
  topic: "WebSocket vs SSE for real-time updates",
  depth: "comprehensive"
}

# Summarize a long document
gemini-summarize-pdf: {
  path: "/path/to/specification.pdf",
  focus: "API changes"
}

# Analyze a webpage
gemini-analyze-url: {
  url: "https://docs.example.com/api",
  prompt: "Extract all endpoint definitions"
}
```

**Offloading Strategy:**
- Large file analysis (>500 lines): Use Gemini
- Full codebase overview: Use Gemini
- Verification after changes: Use Gemini to review
- Research tasks: Use Gemini deep-research

---

## Gemini CLI Usage

Use Gemini CLI for large codebase analysis to **save Claude's context window**.

```bash
# Analyze single file
gemini -p "@src/main.py explain this file"

# Analyze directory
gemini -p "@src/ @tests/ analyze test coverage"

# Entire project
gemini -p "@./ give project overview"

# Verify implementation
gemini -p "@src/ has authentication been implemented?"
```

**Workflow:**
1. Use Gemini for heavy analysis (large files, full codebase)
2. Claude reads Gemini's response
3. Claude implements specific changes
4. Gemini verifies implementation

---

### MCP Best Practices

1. **Prefer context7 over Web Search** for library docs (more accurate, faster)
2. **Offload heavy analysis** to Gemini MCP to save Claude's context
3. **Use playwright** for any web interaction that needs JavaScript
4. **Chain MCPs** for workflows: Gemini analyzes → Linear creates issue
5. **Check MCP availability**: `claude mcp list`
6. **Use desktop-commander** when Claude's sandbox blocks file access
7. **Batch operations** with desktop-commander's `read_multiple_files`

---

## Development Directories

```
/mnt/storage/Programacao/Repositorios/   # Main repos (50+)
/mnt/storage/Programacao/Repo KodaLabs/  # KodaLabs projects
/home/max/projects/                                # Local projects
/home/max/LG_Buddy/                               # Current project
```

---

## Git Safety Rules

**Blocked by design:**
- `git commit` - Review manually
- `git push` - Prevents accidental pushes
- `git push --force` - Dangerous
- `git reset --hard` - Data loss risk

**Allowed:**
```bash
git status, git log, git diff, git branch
git checkout, git pull, git fetch, git add
git reset (soft), git stash, git show
```

**Commit workflow:**
```bash
# 1. Run AI helper
gemini-git-helper.sh

# 2. Review suggestions
# 3. Execute git add commands
# 4. Manually commit outside Claude
git commit -m "feat(scope): description"
```

**Commit rules:**
- **NEVER add `Co-Authored-By` trailers** to commit messages — the user does not want AI attribution in commits
- Keep commit messages clean: just the conventional commit format, no trailers

**Audit workflow (check for leaked secrets):**
```bash
# 1. Scan commit history for secrets
gemini-git-helper.sh --scan-history

# 2. If secrets found, rotate/revoke them immediately
# 3. Clean history with BFG or git filter-repo
# 4. Force push and notify collaborators
```

---

## Git Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `st` | `status` | Show working tree status |
| `co` | `checkout` | Switch branches |
| `cob` | `checkout -b` | Create and switch to new branch |
| `br` | `branch` | List/manage branches |
| `brm` | `branch -M` | Rename branch |
| `cm` | `commit -m` | Commit with message |
| `df` | `diff` | Show unstaged changes |
| `dfs` | `diff --staged` | Show staged changes |
| `lg` | `log --oneline --graph --decorate --all` | Pretty log view |
| `rb` | `rebase` | Rebase current branch |
| `pl` | `pull` | Pull from remote |
| `ps` | `push` | Push to remote |
| `psu` | `push -u origin` | Push and set upstream |
| `poh` | `push origin HEAD` | Push current branch to origin |
| `aa` | `add --all` | Stage all changes |
| `unstage` | `reset HEAD --` | Unstage files |
| `last` | `log -1 HEAD` | Show last commit |
| `amend` | `commit --amend --no-edit` | Amend last commit (keep message) |
| `undo` | `reset --soft HEAD~1` | Undo last commit (keep changes) |
| `stash-all` | `stash save --include-untracked` | Stash everything |
| `aliases` | `config --get-regexp alias` | List all aliases |

**Examples:**
```bash
git st                    # Quick status
git cob feature/login     # Create new branch
git aa && git cm "msg"    # Stage all and commit
git psu main              # Push and track upstream
git lg                    # Visual branch history
git undo                  # Oops, undo last commit
```

**Nuclear Option - Remove Git History:**
```bash
# WARNING: Irreversible! Removes ALL git history from project
rm -rf .git
git init
git add .
git commit -m "Initial commit"
```

---

## Sensitive Content Protection

**Always scan before commit.** The gemini-git-helper.sh detects:
- AWS keys (AKIA...)
- Google API keys (AIza...)
- GitHub tokens (ghp_, gho_, ghu_)
- Private keys (RSA, SSH, PGP)
- Passwords, secrets, tokens
- Database URLs with credentials
- JWT tokens
- Stripe, Slack, Twilio, SendGrid keys

**Required .gitignore patterns:**
```
.env
.env.local
.env*.local
*.pem
*.key
credentials.json
oauth_creds.json
secrets.json
id_rsa
id_ed25519
```

**If secrets leaked to git history:**
```bash
# 1. Scan history to find all leaks
gemini-git-helper.sh --scan-history --all-history

# 2. Rotate/revoke exposed credentials IMMEDIATELY

# 3. Clean history with BFG Repo-Cleaner (fast, recommended)
# https://rtyley.github.io/bfg-repo-cleaner/
bfg --replace-text passwords.txt repo.git
git reflog expire --expire=now --all && git gc --prune=now --aggressive

# 4. Or use git filter-repo (more flexible)
# https://github.com/newren/git-filter-repo
git filter-repo --replace-text expressions.txt

# 5. Force push (coordinate with team first!)
git push --force --all
```

### Centralized Secrets Strategy (~/.secrets)

All API keys and credentials are stored in `~/.secrets` (chmod 600), sourced by `~/.bashrc`:

```bash
# ~/.secrets format (NEVER commit this file)
export GEMINI_API_KEY='your-key-here'
export OTHER_API_KEY='your-other-key-here'
```

**Rules:**
- `~/.secrets` is **never committed** to any repository
- All repos should have `*secret*` in `.gitignore` as a safety net
- Do NOT use project-level `.env` files for global API keys — use `~/.secrets`
- After editing, run `source ~/.bashrc` or open a new terminal

---

## Dual-Boot Setup

| OS | Claude Config | MCP Config |
|----|---------------|------------|
| Windows 11 | `%APPDATA%\Claude\` | Same location |
| Pop!_OS | `~/.claude/` | `~/.claude.json` |

- Windows NTFS mounted read-only at `/mnt/windows`
- Shared project files at `/mnt/storage/Programacao/`
- Each OS has independent Claude configuration

---

## Command Permissions

**Unrestricted:**
```bash
npm, npx, node, yarn, pnpm, bun
docker, docker-compose
python, python3, pip, pip3
eslint, prettier, tsc, jest, vitest
curl, wget, ls, cat, grep, find
```

**Path-restricted (dev directories only):**
```bash
rm, mv, rmdir, chmod, chown
```

**System paths protected:**
```
/etc, /sys, /root, /var, /boot, /usr, /bin, /sbin
```

---

## System Change Tracking (pop-os-oled-setup)

**Repository:** `/mnt/storage/Programacao/Repositorios/pop-os-oled-setup/`
**Purpose:** System restoration — replicate current Pop!_OS setup from scratch.

**IMPORTANT:** When making system-level changes, ALWAYS suggest saving them to this repository. This includes:

| Change Type | Repo Location | Example |
|-------------|---------------|---------|
| Shell config (~/.bashrc, aliases) | `configs/shell/` | Adding new sourcing patterns |
| Systemd services/timers | `configs/systemd/` | New user services |
| Audio/PipeWire/WirePlumber | `configs/pipewire/`, `configs/wireplumber/` | Audio config changes |
| SSH config | `configs/ssh/` | SSH config templates |
| Sudoers rules | `configs/sudoers.d/` | New passwordless sudo rules |
| udev rules | `configs/udev/` | Hardware detection rules |
| Terminal config (Kitty) | `configs/kitty/` | Theme or shortcut changes |
| Claude/AI config | `configs/claude/` | CLAUDE.md, MCP servers |
| VSCodium settings | `configs/vscodium/` | Editor preferences |
| New tool setup | `docs/XX-tool-setup.md` | Documentation for new tools |
| Install steps | `scripts/install.sh` | New install automation |
| Package lists | `packages/` | New apt/flatpak/npm packages |

**Workflow:**
1. Make the system change (edit dotfile, create service, etc.)
2. Suggest: "This is a system-level change. Should I save it to pop-os-oled-setup?"
3. Copy/update the relevant config file in the repo
4. Update documentation if needed
5. Suggest running `gemini-git-helper.sh` for commit

**Rules:**
- NEVER save actual secrets or API keys to the repo
- Use placeholder values in templates (e.g., `your-key-here`)
- Config files in the repo are reference copies — `install.sh` deploys them
- Always check if the file already exists in the repo before creating duplicates

---

## Quick Reference

```bash
# Analyze codebase with Gemini
gemini -p "@./ analyze architecture"

# Git commit helper (suggest commits)
gemini-git-helper.sh

# Git history audit (scan for leaked secrets)
gemini-git-helper.sh --scan-history
gemini-git-helper.sh -s --commits 100    # Last 100 commits
gemini-git-helper.sh -s --all-history    # Full history

# Check MCP servers
claude mcp list

# Test MCP server
claude mcp get context7
```

---

## HDMI Audio Fix (NVIDIA + LG TV + Polk Soundbar)

**Hardware Setup:**
- GPU: NVIDIA RTX 3070 (GA104)
- Display: LG B3 OLED (HDMI 4 input)
- Audio: Polk Audio Soundbar (eARC on TV's HDMI 3)

**Known Issue:** NVIDIA HDMI audio has ELD detection problems on Linux. The codec detects the TV (`PD=1, ELDV=1`) but ALSA shows `eld_valid=0`.

### Automatic Fix (Systemd Service)
```bash
# Service file: ~/.config/systemd/user/hdmi-audio-fix.service
# Script: ~/.local/bin/hdmi-audio-fix.sh
# Runs automatically after PipeWire starts

# Check service status
systemctl --user status hdmi-audio-fix.service

# View logs
cat /tmp/hdmi-audio-fix.log
```

### Manual Fix Commands
If audio doesn't work after reboot, run these commands in order:

```bash
# 1. Set HDMI profile (creates the sink)
pactl set-card-profile alsa_card.pci-0000_0a_00.1 output:hdmi-stereo-extra1

# 2. Enable HDMI pin (Node 0x05) - may need to run multiple times
sudo hda-verb /dev/snd/hwC0D0 0x05 0x707 0x40

# 3. Set HDMI as default for keyboard volume (CRITICAL - must use wpctl!)
# First get the HDMI sink ID, then set it as default
wpctl status | grep "GA104.*HDMI"  # Find the node ID (e.g., 82)
wpctl set-default <ID>              # Replace <ID> with actual number

# 4. Verify keyboard volume works
wpctl get-volume @DEFAULT_AUDIO_SINK@
wpctl set-volume @DEFAULT_AUDIO_SINK@ 80%

# 5. Or just run the fix script
~/.local/bin/hdmi-audio-fix.sh
```

**Important:** COSMIC desktop uses `wpctl` for volume control, not `pactl` or `pw-metadata`. You MUST use `wpctl set-default` for keyboard volume to work.

### Microphone Fix (Rear Mic - Lavalier)
```bash
# Set input source to Rear Mic
amixer -c 1 sset 'Input Source' 'Rear Mic'
amixer -c 1 sset 'Rear Mic Boost' 100%
amixer -c 1 sset 'Capture' 100%
```

### Troubleshooting
```bash
# Check if TV is detected
cat /proc/asound/card0/eld#0.4
# Should show: monitor_present=1, codec_cvt_nid=0x8

# Check pin status (should be 0x40)
sudo hda-verb /dev/snd/hwC0D0 0x05 0xf07 0

# Check codec status
cat /proc/asound/card0/codec* | grep -A 8 "Node 0x05"

# If nothing works, try HDMI hotplug:
# 1. Unplug HDMI cable from PC
# 2. Wait 10 seconds
# 3. Replug HDMI cable
# 4. Run manual fix commands above
```

### Watchdog Timer (TV On/Off Fix)
The udev approach doesn't work reliably with NVIDIA, so a lightweight watchdog runs every 30 seconds:
```bash
# Check watchdog status
systemctl --user status hdmi-audio-watchdog.timer

# View watchdog logs
cat /tmp/hdmi-audio-fix.log | tail -20

# Manually trigger watchdog
systemctl --user start hdmi-audio-watchdog.service
```
The watchdog only runs the fix when needed (sink missing, wrong default, or pin disabled).

### Key Files
| File | Purpose |
|------|---------|
| `~/.local/bin/hdmi-audio-fix.sh` | Main fix script |
| `~/.local/bin/hdmi-audio-watchdog.sh` | Lightweight watchdog (checks every 30s) |
| `~/.config/systemd/user/hdmi-audio-fix.service` | Systemd service (runs on login) |
| `~/.config/systemd/user/hdmi-audio-watchdog.timer` | Watchdog timer (TV on/off) |
| `/etc/sudoers.d/hdmi-audio` | Passwordless sudo for hda-verb |

---

## Environment

- **OS:** Pop!_OS 24.04 LTS
- **Kernel:** 6.17.9
- **Node.js:** v24.13.0 (nvm)
- **Python:** 3.x
- **Shell:** bash

---

## JoiasMax Project (3-Repo Architecture)

### Repositories

| Repo | Linux Path | Purpose |
|------|-----------|---------|
| odoo | `/mnt/storage/Programacao/Repositorios/odoo` | Odoo 18 multi-tenant ERP (jewelry pricing module) |
| odoo-ecommerce | `/mnt/storage/Programacao/Repositorios/odoo-ecommerce` | WordPress/WooCommerce + Python integration layer |
| automation-platform | `/mnt/storage/Programacao/Repositorios/automation-platform` | n8n workflow automation |

Each repo has its own `CLAUDE.md` with project-specific instructions.

### Windows Planning Docs Archive

Planning docs were originally created in Windows Claude Code sessions at:
- **Windows path**: `C:\Users\Admin\.claude\plans\` (on `/dev/nvme0n1p3`)
- **Linux mount**: `/mnt/windows-inspect/Users/Admin/.claude/plans/` (read-only NTFS, mount on demand)

All 16 plan files (416KB) have been **copied to**: `odoo-ecommerce/docs/plans/`
- Master plan: `docs/plans/00-MASTER-5-WEEK-PLAN.md`
- The Windows copies are the originals; the odoo-ecommerce copies are the working versions

### Gemini API Keys (Dual-Boot)

- **Linux key** (`~/.secrets`): Active, used by gemini-git-helper.sh
- **Windows key**: Different key, exposed in Windows Claude Code config — should be revoked at Google AI Studio when convenient
