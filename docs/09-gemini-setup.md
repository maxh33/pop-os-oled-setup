# Global Context for Gemini CLI

## Custom Scripts

### gemini-git-helper.sh (v2.2)

**Location:** `/home/max/bin/gemini-git-helper.sh`
**Usage:** Run `gemini-git-helper.sh` in any git repository

AI-powered git commit assistant that:
- Scans for sensitive content (API keys, passwords, tokens)
- **NEW:** Scans commit history for leaked secrets (uses gitleaks/trufflehog)
- Validates .gitignore/.dockerignore patterns
- Groups changes by topic
- Suggests conventional commit messages using Gemini API
- Multi-API-key and multi-model fallback support

#### Command-Line Options

| Flag | Description |
|------|-------------|
| `--local, -l` | Use local analysis only (no API call) |
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

- **API Keys**: Set `GEMINI_API_KEY` env var or edit hardcoded keys in script
- **Models**: Tries gemini-2.5-flash, gemini-2.5-pro, gemini-2.0-flash, gemini-2.0-flash-lite in order
- **OAuth**: Uses `/home/max/.gemini/oauth_creds.json` if available

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
