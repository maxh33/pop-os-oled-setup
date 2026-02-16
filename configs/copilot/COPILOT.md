# Global Context for Copilot CLI

## Quick Start: MCP Setup

**First time setup:**
```bash
# Create Copilot MCP configuration (auto-detects changes)
# Restart Copilot CLI after setup
copilot --version   # Verify installation
```

**Required environment variables** (from ~/.secrets):
- `GEMINI_API_KEY` - For Gemini MCP analysis
- `GITHUB_PERSONAL_ACCESS_TOKEN` - For GitHub integration

---

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
   - `~/.copilot/.env` — Copilot CLI-specific keys (if needed)
   - Project `.env` files — Project-specific vars (MUST be in .gitignore)

3. **Reference in code:**
   ```python
   # ✅ CORRECT
   api_key = os.getenv('GEMINI_API_KEY')

   # ❌ WRONG - NEVER DO THIS
   api_key = 'AIzaSyC...'  # Hardcoded key
   ```

4. **Defense mechanisms (already active):**
   - gemini-git-helper.sh scans for hardcoded secrets
   - Pre-commit hook blocks commits with secrets
   - Pre-push hook blocks pushes with secrets

#### When Writing Code

- **Before committing:** Run `gemini-git-helper.sh` to scan for secrets
- **Use placeholders in templates:** `'your-api-key-here'`, `'YOUR_API_KEY'`
- **Document env vars:** List required env vars in project README
- **Never bypass hooks:** Don't use `git commit --no-verify` to skip secret detection

---

## Custom Scripts

### gemini-git-helper.sh (v3.0+)

**Location:** `/home/max/bin/gemini-git-helper.sh`

AI-powered git commit assistant with secret scanning and intelligent commit grouping.

#### Commit Helper Mode (default)
```bash
cd /path/to/repo && gemini-git-helper.sh                   # Full analysis with Gemini API
cd /path/to/repo && gemini-git-helper.sh --quiet           # Minimal output (CI-friendly)
cd /path/to/repo && gemini-git-helper.sh --local           # Local grouped analysis (no API)
```

#### History Scanning Mode (audit existing commits)
```bash
gemini-git-helper.sh --scan-history                # Scan last 50 commits
gemini-git-helper.sh -s --commits 100              # Scan last 100 commits
gemini-git-helper.sh -s --all-history              # Scan entire git history
gemini-git-helper.sh -s --since main               # Scan since branch
gemini-git-helper.sh -s --since v1.0.0             # Scan since tag
```

#### Options
| Flag | Description |
|------|-------------|
| `--local, -l` | Use local analysis only (no API call) |
| `--quiet, -q` | Suppress decorative output (keep errors/warnings) |
| `--pre-commit` | Fast secrets-only scan for git hooks |
| `--pre-push RANGE` | Scan commits being pushed |
| `--scan-history, -s` | Scan commit history for secrets |
| `--commits N` | Number of commits to scan (default: 50) |
| `--all-history` | Scan entire git history |
| `--since REF` | Scan commits since ref |
| `--help, -h` | Show help message |

#### Secrets Detected
```
AWS: AKIA..., aws_access_key_id, aws_secret_access_key
Google: AIza..., ya29...
GitHub: ghp_, gho_, ghu_, ghs_, ghr_, github_pat_
Private Keys: RSA, OPENSSH, EC, PGP
Generic: api_key, api_secret, secret_key, access_token, password
Database URLs: mysql://, postgresql://, mongodb://, redis:// with credentials
JWT: eyJ... tokens
Service Keys: Slack (xox...), Stripe (sk_live_, pk_live_), Twilio (SK...), SendGrid (SG...)
```

---

## Copilot CLI Tools & Agents

### Understanding Task Agents

Copilot has specialized agents for different types of work. Each agent type has specific capabilities optimized for its task.

#### Built-in Agents

**1. explore** — Fast code exploration
- Best for: Finding files, searching code, understanding codebase patterns
- Speed: Very fast (uses Haiku model)
- Safe: Can be run in parallel
- Tools: grep, glob, view
- Output: Focused answers (~300 words max)

**Example:**
```bash
copilot "Explore the codebase to find all API endpoints"
copilot "Where is the authentication logic implemented?"
```

**2. task** — Execute commands with minimal output
- Best for: Tests, builds, lints, dependency installs
- Output: Brief on success ("All 247 tests passed"), full on failure
- Keeps main context clean
- Tools: All CLI tools
- When to use: When you only need success/failure status

**Example:**
```bash
copilot "Run npm test and report results"
copilot "Build the project with npm run build"
```

**3. code-review** — High-signal code analysis
- Best for: Reviewing staged/unstaged changes, finding real bugs
- Focus: Only surfaces genuine issues (bugs, security, logic errors)
- Ignores: Style, formatting, trivial matters
- Tools: All CLI tools (investigation only)
- Key: Never modifies code, only analyzes

**Example:**
```bash
copilot "Review my recent changes for security vulnerabilities"
copilot "Check if my implementation has logic errors"
```

**4. general-purpose** — Full-capability agent
- Best for: Complex multi-step tasks
- Model: Sonnet (better reasoning)
- Context: Runs in separate window (keeps main clean)
- Tools: Complete toolset
- Use when: Explore/task/code-review aren't sufficient

**Example:**
```bash
copilot "Refactor this authentication module to use JWT tokens"
```

#### Custom Agents (Your Environment)

**cross-repo-scout** — Read-only exploration across all 3 JoiasMax repos
- Find model definitions, API schemas, workflows
- Safe: Read-only, no modifications

**project-navigator** — Summarize planning docs, track project status
- Read planning documentation
- Track 5-week timeline progress
- Understand project context

### Effective Agent Usage

**Decision Matrix: Which Agent to Use**

| Task | Agent | Why |
|------|-------|-----|
| Find files by pattern | explore | Fast, parallel-safe |
| Search for specific code | explore | Uses grep efficiently |
| Understand codebase | explore | Returns focused answers |
| Run tests/build | task | Brief success/failure |
| Identify bugs/security issues | code-review | High signal-to-noise |
| Complex refactoring | general-purpose | Multi-step reasoning |
| Analyze large codebase | general-purpose | Sonnet model, better analysis |
| Explore multiple repos | cross-repo-scout | Reads all 3 JoiasMax repos |
| Track project status | project-navigator | Reads planning docs |

**Best Practices:**

1. **Use agents, don't just ask Claude** — Agents are optimized for specific tasks
2. **Parallel where possible** — explore/code-review can run simultaneously
3. **Combine agents** — Use explore for discovery, then general-purpose for implementation
4. **Check agent availability** — Use `copilot mcp list` to see available agents
5. **Provide complete context** — Each agent is stateless, so include all needed info in your prompt

---

## MCP Servers (Model Context Protocol)

MCP servers extend Copilot's capabilities through specialized tools. They're similar to Claude's MCPs but configured for Copilot CLI.

### Registered MCP Servers

| Server | Purpose | Tools | API Required |
|--------|---------|-------|--------------|
| **github-mcp-server** | GitHub integration | List/search repos, PRs, issues, workflows | GitHub token |
| **context7** | Library documentation | Resolve library ID, query docs | None |
| **desktop-commander** | System automation | Read/write files, manage processes | None |
| **playwright** | Browser automation | Navigate, interact, screenshot | None |
| **linear** | Issue tracking | Create/update issues, manage projects | Linear token |
| **gemini** | AI analysis | Analyze code, research, summarize | GEMINI_API_KEY |

### Using MCPs in Copilot

**GitHub Integration** (Built-in - `github-mcp-server`)
```bash
# List repositories
copilot "List my GitHub repositories"

# Search for code
copilot "Find all uses of 'authenticateUser' function across GitHub"

# Check workflow status
copilot "Show recent GitHub Actions runs for my project"

# Manage issues
copilot "Create an issue for the authentication refactor"
```

**Code Documentation** (context7 MCP)
```bash
# Get current library docs (more accurate than training data)
copilot "What's the latest React hooks API?"

# Framework guidance
copilot "How do I use async/await in TypeScript?"
```

**System Automation** (desktop-commander MCP)
```bash
# Read protected files
copilot "Read /etc/nginx/nginx.conf and explain the configuration"

# Manage processes
copilot "List all running Node.js processes"

# File operations
copilot "Find all .gitignore files and show their contents"
```

**Browser Testing** (playwright MCP)
```bash
# Test web application
copilot "Navigate to example.com and take a screenshot"

# Form automation
copilot "Log into the application and verify the dashboard loads"
```

**Issue Tracking** (linear MCP)
```bash
# Create issue
copilot "Create a Linear issue: Fix login timeout on slow connections"

# Query issues
copilot "Show all open bugs assigned to me"

# Track progress
copilot "Move issue 123 to 'In Progress' status"
```

**AI Analysis** (gemini MCP)
```bash
# Analyze large codebase
copilot "Use Gemini to analyze src/ for architectural patterns"

# Research
copilot "Deep research: WebSocket vs SSE for real-time updates"

# Summarize
copilot "Summarize this 50-page API documentation PDF"
```

---

## GitHub Integration

Copilot has native GitHub integration via the `github-mcp-server`. This enables powerful workflows without additional setup.

### Common GitHub Tasks

#### Search & Discover
```bash
copilot "Find all repositories in my GitHub account"
copilot "Search for 'authentication' code across my repos"
copilot "List all open issues labeled 'bug'"
```

#### Pull Requests
```bash
copilot "List all open pull requests in the project"
copilot "Show the diff for PR #123"
copilot "Get the status of checks on PR #456"
```

#### Workflows & Actions
```bash
copilot "List recent GitHub Actions workflow runs"
copilot "Show logs for workflow run #789"
copilot "Check why the CI failed in the last commit"
```

#### Issues & Projects
```bash
copilot "Get details on issue #234"
copilot "List issues created in the last 7 days"
copilot "Search for issues mentioning 'performance'"
```

#### Commits & History
```bash
copilot "Show commits by author maxh33 in the last month"
copilot "Get the diff for commit abc123"
copilot "List commits that touched src/auth.ts"
```

---

## MCP Configuration Setup

### File Location
- **Config file:** `~/.copilot/settings.json` (auto-detected by Copilot)
- **Credentials:** Environment variables from `~/.secrets`
- **MCP data:** `~/.copilot/mcp-data/` (created automatically)

### Required Environment Variables

Add these to `~/.secrets` (chmod 600):
```bash
export GEMINI_API_KEY='your-gemini-api-key'
export GITHUB_PERSONAL_ACCESS_TOKEN='your-github-token'
```

**Never commit these to any repository.**

### MCP Server Configuration Format

```json
{
  "mcpServers": {
    "github-mcp-server": {
      "command": "npx",
      "args": ["@githubcopilot/github-mcp-server"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "desktop-commander": {
      "command": "npx",
      "args": ["@wonderwhy-er/desktop-commander@latest"]
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp"]
    },
    "linear": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.linear.app/sse"]
    },
    "gemini": {
      "command": "npx",
      "args": ["-y", "@rlabs-inc/gemini-mcp"],
      "env": {
        "GEMINI_API_KEY": "${GEMINI_API_KEY}"
      }
    }
  }
}
```

### Testing MCP Configuration

After creating `~/.copilot/settings.json`:

```bash
# Verify MCPs are available
copilot mcp list

# Test specific MCP
copilot mcp get github-mcp-server

# Use in query
copilot "List my GitHub repositories"  # Tests GitHub MCP

copilot "What's the latest React hooks API?"  # Tests context7 MCP
```

---

## Git Workflow & Conventions

### Git Safety Rules

**Blocked by design (prevent accidental damage):**
- Force pushes to main branches
- Destructive operations without verification

**Allowed & recommended:**
```bash
git status, git log, git diff, git branch
git checkout, git pull, git fetch, git add
git reset (soft), git stash, git show
```

### Commit Workflow

```bash
# 1. Make changes
git add <files>

# 2. Run AI helper
gemini-git-helper.sh

# 3. Review suggestions
# 4. Execute git add commands from helper output
git add <files>

# 5. Manually commit outside Copilot
git commit -m "feat(scope): description"
```

### Conventional Commits Format

```
feat(scope): description           # New features
fix(scope): description            # Bug fixes
docs: description                  # Documentation
refactor(scope): description       # Code refactoring
chore: description                 # Maintenance tasks
test(scope): description           # Tests
perf(scope): description           # Performance improvements
ci: description                    # CI/CD changes
```

**Example commits:**
```
feat(auth): implement JWT token validation
fix(api): handle null response in error handler
docs: add API authentication guide
refactor(db): migrate from MongoDB to PostgreSQL
chore: update dependencies to latest versions
test(auth): add unit tests for token validation
```

### ⚠️ CRITICAL RULE: NO Co-authored-by Trailers

**NEVER add `Co-authored-by` trailers to commits in this workflow.**

When Copilot CLI assists with commits:
1. Follow gemini-git-helper.sh suggestions exactly
2. Use conventional commit format only
3. **DO NOT** add `Co-authored-by` trailers
4. **DO NOT** add any co-author information

**✅ CORRECT:**
```bash
feat(scope): description
- Change 1
- Change 2
```

**❌ WRONG (DO NOT DO THIS):**
```bash
feat(scope): description
- Change 1
- Change 2

Co-authored-by: Copilot <...>
```

This is YOUR workflow. This rule is NON-NEGOTIABLE. If this rule is violated, the setup cannot be used.

### Git Aliases (Pre-configured)

| Alias | Command | Usage |
|-------|---------|-------|
| `st` | `status` | `git st` |
| `co` | `checkout` | `git co main` |
| `cob` | `checkout -b` | `git cob feature/auth` |
| `br` | `branch` | `git br` |
| `cm` | `commit -m` | `git cm "msg"` |
| `df` | `diff` | `git df` |
| `dfs` | `diff --staged` | `git dfs` |
| `aa` | `add --all` | `git aa && git cm "msg"` |
| `lg` | `log --oneline --graph --all` | `git lg` |

---

## Sensitive Content Protection

### Before Every Commit

```bash
gemini-git-helper.sh  # Scans for secrets automatically
```

### Required .gitignore Patterns

```
.env
.env.local
.env*.local
*.pem
*.key
credentials.json
oauth_creds.json
secrets.json
*.secret
id_rsa
id_ed25519
```

### If Secrets Are Leaked

```bash
# 1. Scan history to find all leaks
gemini-git-helper.sh --scan-history --all-history

# 2. Rotate/revoke exposed credentials IMMEDIATELY

# 3. Clean history with BFG Repo-Cleaner (fast, recommended)
bfg --replace-text passwords.txt repo.git
git reflog expire --expire=now --all && git gc --prune=now --aggressive

# 4. Or use git filter-repo (more flexible)
git filter-repo --replace-text expressions.txt

# 5. Force push (coordinate with team first!)
git push --force --all
```

---

## System Change Tracking

### Pop!_OS Setup Repository

**Repository:** `/mnt/storage/Programacao/Repositorios/pop-os-oled-setup/`

When making system-level changes, ALWAYS suggest saving them to this repository.

| Change Type | Repo Location | Example |
|-------------|---------------|---------|
| Shell config | `configs/shell/` | ~/.bashrc patterns |
| Systemd services | `configs/systemd/` | New user services |
| Audio/PipeWire | `configs/pipewire/` | HDMI audio fixes |
| SSH config | `configs/ssh/` | SSH templates |
| Terminal (Kitty) | `configs/kitty/` | Theme/shortcuts |
| Copilot config | `configs/copilot/` | COPILOT.md, settings.json |
| Tool setup docs | `docs/XX-tool-setup.md` | New tool documentation |
| Install steps | `scripts/install.sh` | Automation |

**Rules:**
- NEVER save actual secrets or API keys
- Use placeholder values in templates
- Config files are reference copies — `install.sh` deploys them

---

## Development Directories

```
/mnt/storage/Programacao/Repositorios/        # Main repositories (50+)
/mnt/storage/Programacao/Repo KodaLabs/       # KodaLabs projects
/home/max/projects/                           # Local projects
/home/max/LG_Buddy/                           # Current active project
```

### Directory Organization Best Practices

```
repo/
├── src/                    # Source code
├── tests/                  # Test files
├── docs/                   # Documentation
│   ├── setup.md
│   ├── api.md
│   └── architecture.md
├── .github/
│   ├── workflows/          # GitHub Actions
│   └── ISSUE_TEMPLATE/
├── .gitignore              # Security-first patterns
├── README.md
└── package.json / requirements.txt
```

---

## Workflow Integration: Copilot + Gemini + Claude

### Tool Selection Guide

| Task | Primary Tool | Secondary | Why |
|------|-------------|-----------|-----|
| Code exploration | Copilot (explore agent) | Gemini CLI | Fast, parallel-safe |
| Write code | Claude Code | Copilot | Better reasoning |
| Git commits | Gemini CLI | Copilot | Specialized script |
| Large file analysis | Gemini CLI | Copilot (general-purpose) | Context efficiency |
| Browser testing | Copilot (playwright MCP) | Claude | Playwright MCP ready |
| Issue management | Copilot (linear MCP) | Claude | Direct Linear API |
| Architecture review | Gemini CLI | Copilot | Deep analysis |
| System automation | Copilot (desktop-commander) | Bash scripts | Safe file ops |

### Integration Pattern

```
User Request
    ↓
[Copilot - Quick analysis]
    ↓
    ├─→ Simple? Use Copilot directly
    │
    └─→ Complex/Large? Delegate to Gemini CLI
         or offload to MCP (playwright, linear, gemini)
    ↓
[Implement with Claude Code]
    ↓
[Verify & commit with Gemini CLI]
```

### Cross-Tool Workflows

**Example: Implement Authentication**
1. Copilot: "Explore codebase for existing auth patterns" (explore agent)
2. Gemini: "Analyze auth implementation and suggest improvements"
3. Claude Code: Implement JWT authentication
4. Copilot: "Review my changes for security issues" (code-review agent)
5. Gemini: Run `gemini-git-helper.sh` to commit

**Example: Fix CI Failure**
1. Copilot: "Check GitHub Actions logs for latest failure" (github-mcp-server)
2. Copilot: "Analyze the build error" (code-review agent)
3. Claude Code: Fix the issue
4. Copilot: "Search for similar issues in GitHub" (github-mcp-server)

---

## Quick Reference

### Most Common Commands

```bash
# Code exploration
copilot "Find where user authentication happens"
copilot "Search for API endpoints"

# MCP tools
copilot "List my GitHub issues"
copilot "Check the latest React documentation"
copilot "Take a screenshot of example.com"

# Git workflow
gemini-git-helper.sh              # Suggest commits
git st                             # Status
git lg                             # Visual log
git aa && git cm "message"         # Stage & commit

# Security
gemini-git-helper.sh --scan-history --all-history  # Audit for secrets
```

### Environment Setup (One-time)

```bash
# 1. Add to ~/.secrets (chmod 600)
export GEMINI_API_KEY='your-key'
export GITHUB_PERSONAL_ACCESS_TOKEN='your-token'

# 2. Create ~/.copilot/settings.json with MCP servers
# 3. Restart Copilot CLI
copilot --version

# 4. Verify MCPs work
copilot mcp list
```

### Troubleshooting

**MCP not available?**
```bash
# Check configuration
copilot mcp list

# Verify settings.json exists and is valid JSON
cat ~/.copilot/settings.json | jq .

# Check environment variables
echo $GEMINI_API_KEY
echo $GITHUB_PERSONAL_ACCESS_TOKEN
```

**Secrets detected in code?**
```bash
# View what was detected
gemini-git-helper.sh

# Clean the secrets (don't commit yet)
# Then run again
gemini-git-helper.sh
```

**Agent not responding?**
```bash
# Use sync mode for longer tasks
copilot --sync "Your query here"

# Check if agent is available
copilot mcp list | grep <agent-name>
```

---

## Related Global Guides

- **CLAUDE.md** — Claude Code global context (MCP servers, security, system setup)
- **GEMINI.md** — Gemini CLI global context (git-helper.sh, custom scripts)

These guides complement each other. Copilot uses patterns from both.

---

## Resources & Tools

### Installed Tools
- **Node.js:** v24.13.0 (via nvm)
- **Python:** 3.x
- **git:** Pre-configured with aliases and hooks
- **Gemini CLI:** `gemini` command available
- **GitHub CLI:** `gh` command for API access

### Custom Scripts
- **gemini-git-helper.sh** — AI git commit assistant (`/home/max/bin/`)
- **hdmi-audio-fix.sh** — Audio system automation (`~/.local/bin/`)

### Documentation Files
- **COPILOT.md** — This file (Copilot CLI global context)
- **CLAUDE.md** — Claude Code setup (MCP servers, security)
- **GEMINI.md** — Gemini CLI setup (git-helper, system tracking)

---

## Version Info

- **Copilot CLI:** 0.0.410+
- **Last Updated:** 2026-02-16
- **OS:** Pop!_OS 24.04 LTS
- **Node.js:** v24.13.0
