# Global Context for Gemini CLI

## Custom Scripts

### gemini-git-helper.sh (v2.4)

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

**Note:** This is a reference copy for system recovery. The active copy is at `/home/max/bin/gemini-git-helper.sh`.

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
gemini-git-helper.sh -s --since v1.0.0        # Scan since tag
```

#### How Commit Helper Works

1. **Detects git changes**: Staged, unstaged, and untracked files
2. **Scans for secrets**: Checks for AWS keys, Google API keys, GitHub tokens, private keys, passwords, JWT tokens, Stripe/Slack/Twilio/SendGrid keys
3. **Validates ignore files**: Ensures .gitignore and .dockerignore have security patterns
4. **Calls Gemini API**: Sends changes for analysis and commit suggestions
5. **Returns grouped commits**: Suggests `git add` and `git commit` commands grouped by topic

#### How History Scanning Works

1. **Detects scanner**: Uses gitleaks > trufflehog > native grep (in priority order)
2. **Scans git log**: Analyzes commit diffs for secret patterns
3. **Reports findings**: Shows commit, file, line, and secret type
4. **Suggests remediation**: BFG Repo-Cleaner or git filter-repo commands

**Scanner priority:**
- **gitleaks** (recommended) - fast, accurate, install with `sudo apt install gitleaks`
- **trufflehog** - excellent classification, verifies if secrets are live
- **native** - built-in grep fallback using same patterns as commit helper

#### Sensitive Content Patterns Detected

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

#### Required .gitignore Patterns

The script checks for these patterns:
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

#### Required .dockerignore Patterns (if Dockerfile exists)

```
.env
.env.local
*.pem
*.key
.git
node_modules
.env*.local
```

#### Configuration

- **API Keys**: Store `GEMINI_API_KEY` in `~/.secrets` (chmod 600, sourced by `~/.bashrc`). No hardcoded keys.
- **Models**: Tries gemini-2.5-flash, gemini-2.5-pro, gemini-2.0-flash, gemini-2.0-flash-lite in order

#### Setting Up ~/.secrets

All API keys live in a single private file, auto-sourced by the shell:

```bash
# 1. Create the file
touch ~/.secrets && chmod 600 ~/.secrets

# 2. Add your API key
echo "export GEMINI_API_KEY='your-gemini-api-key-here'" >> ~/.secrets

# 3. Add to ~/.bashrc (after the ~/.bash_aliases block):
#   if [ -f ~/.secrets ]; then
#       . ~/.secrets
#   fi

# 4. Reload
source ~/.bashrc
```

**Important:**
- Never commit `~/.secrets` to any repository
- `.gitignore` pattern `*secret*` provides a safety net
- Use `chmod 600` to restrict to your user only

#### Global Pre-Commit Hook

A global pre-commit hook is enabled that runs `gemini-git-helper.sh --pre-commit` before every commit in all git repos.

**Location:** `/home/max/bin/git-hooks/pre-commit`
**Enabled via:** `git config --global core.hooksPath /home/max/bin/git-hooks/`

The hook:
- Blocks commits containing secrets (API keys, tokens, passwords)
- Runs automatically in ALL git repos
- Can be bypassed with `git commit --no-verify` (not recommended)

#### Global Pre-Push Hook

A global pre-push hook is enabled that runs before you push commits to a remote repository.

**Location:** `/home/max/bin/git-hooks/pre-push`

The hook:
- Scans the range of commits you are about to push
- Blocks the push if any secrets are found in those commits
- Provides a final safety net before secrets leave your machine
- Can be bypassed with `git push --no-verify` (EXTREMELY not recommended)

#### Defense-in-Depth Chain

The script creates a layered security approach to prevent secrets from being leaked:

1.  **Self-check:** Script refuses to run if it contains hardcoded secrets.
2.  **Pre-commit hook:** Blocks any new secrets from being committed.
3.  **Pre-push hook:** Blocks any secrets that bypassed the pre-commit hook from being pushed.
4.  **--scan-history:** Allows you to audit the entire repository for any secrets that were missed.

#### Example Output

```bash
# Group 1: Documentation
git add README.md docs/setup.md
git commit -m "docs: add setup instructions"

# Group 2: Feature Implementation
git add src/auth.ts src/middleware/auth.ts
git commit -m "feat(auth): implement JWT authentication"

# Group 3: Configuration
git add .env.example .gitignore
git commit -m "chore: add environment template and update gitignore"
```

#### If Secrets Found in History

```bash
# 1. Rotate/revoke exposed credentials IMMEDIATELY

# 2. Clean history with BFG Repo-Cleaner (fast, recommended)
# https://rtyley.github.io/bfg-repo-cleaner/
bfg --replace-text passwords.txt repo.git
git reflog expire --expire=now --all && git gc --prune=now --aggressive

# 3. Or use git filter-repo (more flexible)
# https://github.com/newren/git-filter-repo
git filter-repo --replace-text expressions.txt

# 4. Force push (coordinate with team first!)
git push --force --all
```

#### Full Script Reference

When user asks about this script, you have full context above. The script:
1. Runs `git diff --cached`, `git diff`, and `git ls-files --others` to collect changes
2. Uses regex patterns to scan for secrets in changed files
3. Checks .gitignore/.dockerignore for required security patterns
4. Sends all context to Gemini API with a structured prompt
5. Returns formatted git commands grouped by topic
6. **NEW:** Can scan commit history using gitleaks/trufflehog/native patterns

---

## Development Directories

```
/mnt/onedrive_storage/Programacao/Repositorios/   # Main repos
/mnt/onedrive_storage/Programacao/Repo KodaLabs/  # KodaLabs projects
/home/max/projects/                                # Local projects
```

## Git Commit Convention

Use conventional commits format:
- `feat(scope): description` - New features
- `fix(scope): description` - Bug fixes
- `docs: description` - Documentation
- `refactor(scope): description` - Code refactoring
- `chore: description` - Maintenance tasks
- `test(scope): description` - Tests
