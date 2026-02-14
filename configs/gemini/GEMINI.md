# Gemini CLI Global Instructions

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
   - `~/.gemini/.env` — Gemini CLI-specific keys (auto-loaded)
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

4. **Gemini CLI Integration:**
   - Gemini CLI automatically loads `~/.gemini/.env`
   - Settings.json supports `${VAR_NAME}` expansion
   - Built-in secret redaction for TOKEN, KEY, PASSWORD, SECRET, etc.
   - Use `$GEMINI_API_KEY` from environment (never hardcode)

5. **Defense mechanisms (already active):**
   - gemini-git-helper.sh scans for hardcoded secrets
   - Pre-commit hook blocks commits with secrets
   - Pre-push hook blocks pushes with secrets
   - gitleaks scans commit history

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

### Environment Variable Documentation

**In project README files, document like this:**
```markdown
## Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `GEMINI_API_KEY` | Gemini API key from Google AI Studio | `AIza...` |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://[credentials]@localhost/db` |

### Setup

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your credentials:
   ```bash
   GEMINI_API_KEY=your-key-here
   DATABASE_URL=postgresql://[credentials]@localhost/db
   ```

3. Ensure `.env` is in `.gitignore` (already included)
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
