# 🔄 Global Change Workflow - Copilot CLI Setup

**Complete workflow for making global changes including version control and system restoration.**

---

## Overview: The 3-Tier Change System

When you make a **global change** to your Copilot setup, it flows through three tiers:

```
1. MAKE THE CHANGE
   ↓
2. VERSION CONTROL (Git)
   ↓
3. SYSTEM RESTORATION (pop-os-oled-setup repo)
```

---

## Tier 1: Make the Change (Local)

### Type A: Documentation Changes
**Files**: `COPILOT.md`, `TOOL_COMPARISON.md`, `SETUP_CHECKLIST.md`

```bash
# 1. Edit the file
nano /home/max/COPILOT.md

# 2. Make changes
# ... edit content ...

# 3. Save (Ctrl+O, Enter, Ctrl+X)

# 4. Verify
grep "your new text" /home/max/COPILOT.md
```

- **Restart Needed**: ❌ NO
- **Time to Effect**: Immediate ⚡

### Type B: Configuration Changes
**Files**: `~/.copilot/settings.json`

```bash
# 1. Backup
cp ~/.copilot/settings.json ~/.copilot/settings.json.bak

# 2. Edit
nano ~/.copilot/settings.json

# 3. Validate JSON
jq . ~/.copilot/settings.json

# 4. Restart Copilot
exit
copilot

# 5. Test
copilot mcp list
```

- **Restart Needed**: ✅ YES
- **Time to Effect**: ~5 seconds

### Type C: API Key Changes
**Files**: `~/.secrets`

```bash
# 1. Edit
nano ~/.secrets

# 2. Add/update key
export NEW_API_KEY='your-key-here'

# 3. Save and secure
chmod 600 ~/.secrets

# 4. Reload
source ~/.secrets

# 5. Verify
echo $NEW_API_KEY

# 6. Restart Copilot
exit
copilot

# 7. Test
copilot -p "test command"
```

- **Restart Needed**: ✅ YES
- **Time to Effect**: ~5 seconds
- **Security**: ⚠️ NEVER commit ~/.secrets to git

---

## Tier 2: Version Control (Git)

### When to Commit Changes

| File | Commit to Git? | Notes |
|------|---|---|
| COPILOT.md | ✅ YES | Main documentation |
| TOOL_COMPARISON.md | ✅ YES | Part of workflow docs |
| SETUP_CHECKLIST.md | ✅ YES | Quick reference |
| settings.json | ⚠️ TEMPLATE ONLY | Keep actual config private |
| ~/.secrets | ❌ NEVER | API keys - never commit |

### Commit Workflow (Local Git)

If you have Copilot setup in a git repo (optional):

```bash
# 1. Check what changed
git status

# 2. Stage changes (documentation only)
git add /home/max/COPILOT.md
git add /home/max/TOOL_COMPARISON.md
git add ~/.copilot/SETUP_CHECKLIST.md

# 3. Scan for secrets before committing
gemini-git-helper.sh

# 4. Commit
git commit -m "docs(copilot): update examples and add new MCP documentation"

# 5. Push to remote (optional)
git push
```

### Commit Message Format (Conventional Commits)

```
docs(copilot): brief description of change

# Examples:
docs(copilot): add new GitHub MCP examples
docs(copilot): fix typos in Quick Start section
docs(copilot): update TOOL_COMPARISON with new workflow
feat(copilot): add support for new MCP server
chore(copilot): update API key rotation procedure
```

### Template: settings.json for Version Control

Create a **template** with placeholder values (no secrets):

```bash
# Create template for version control
cp ~/.copilot/settings.json ~/.copilot/settings.json.template

# Edit template to use placeholders
nano ~/.copilot/settings.json.template

# Example content:
{
  "mcpServers": {
    "github-mcp-server": {
      "command": "npx",
      "args": ["@githubcopilot/github-mcp-server"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    },
    ...
  }
}

# Add to git (template, not actual config)
git add ~/.copilot/settings.json.template
git commit -m "docs(copilot): add MCP configuration template"
```

### .gitignore Rules (Protect Secrets)

Make sure your `.gitignore` has these patterns:

```bash
# Copilot secrets - never commit
~/.secrets
~/.copilot/settings.json
~/.copilot/settings.json.bak
.env*
*.key
*.pem
credentials.json
```

---

## Tier 3: System Restoration (pop-os-oled-setup)

**Repository**: `/mnt/storage/Programacao/Repositorios/pop-os-oled-setup/`

When you make significant global changes, **save them to pop-os-oled-setup** for system restoration.

### Step 1: Update Pop!_OS Setup Repo

```bash
# Navigate to the repo
cd /mnt/storage/Programacao/Repositorios/pop-os-oled-setup/

# Create Copilot config directory if needed
mkdir -p configs/copilot
mkdir -p docs
```

### Step 2: Copy Files to Repo

**For Documentation** (safe to version control):

```bash
# Copy main guide
cp /home/max/COPILOT.md configs/copilot/COPILOT.md

# Copy tool comparison
cp /home/max/TOOL_COMPARISON.md configs/copilot/TOOL_COMPARISON.md

# Copy setup checklist
cp ~/.copilot/SETUP_CHECKLIST.md configs/copilot/SETUP_CHECKLIST.md
```

**For Configuration** (template only, no secrets):

```bash
# Copy settings.json TEMPLATE (not actual config)
cp ~/.copilot/settings.json.template configs/copilot/settings.json.template
```

**For Documentation** (new setup guide):

```bash
# Create install guide
cat > docs/copilot-cli-setup.md << 'EOF'
# Copilot CLI Setup Guide

## Installation

1. Install Copilot CLI: [official docs]
2. Create config: ~/.copilot/settings.json
3. Add API keys: ~/.secrets

## Configuration

See configs/copilot/ for:
- COPILOT.md - Main guide
- settings.json.template - MCP configuration
- SETUP_CHECKLIST.md - Quick reference

## First Time Setup

1. Copy COPILOT.md to /home/max/
2. Copy settings.json.template to ~/.copilot/settings.json
3. Add API keys to ~/.secrets
4. Restart Copilot

EOF
```

### Step 3: Document Changes

```bash
# Create/update CHANGES.md in pop-os-oled-setup
cat >> /mnt/storage/Programacao/Repositorios/pop-os-oled-setup/CHANGES.md << 'EOF'

## 2026-02-16 - Copilot CLI Setup

### Added
- COPILOT.md (744 lines) - Global guide for Copilot CLI
- TOOL_COMPARISON.md (260 lines) - When to use Copilot vs Claude vs Gemini
- SETUP_CHECKLIST.md (214 lines) - Quick reference and troubleshooting
- settings.json.template - MCP configuration template
- copilot-cli-setup.md - Installation and setup guide

### Configuration
- 6 MCPs registered (github-mcp-server, context7, desktop-commander, etc)
- Security-first: API keys in ~/.secrets, no hardcoded secrets
- Environment variables templated with ${VARIABLE_NAME}

EOF
```

### Step 4: Commit to System Repo

```bash
# Navigate to pop-os-oled-setup
cd /mnt/storage/Programacao/Repositorios/pop-os-oled-setup/

# Check what's changed
git status

# Stage changes
git add configs/copilot/
git add docs/copilot-cli-setup.md

# Commit
git commit -m "chore(copilot): add Copilot CLI global setup documentation

- Add COPILOT.md global guide (744 lines)
- Add TOOL_COMPARISON.md decision matrix
- Add SETUP_CHECKLIST.md quick reference
- Add settings.json.template for MCP configuration
- Add installation and setup documentation

This enables system restoration of Copilot CLI configuration
on a clean install of Pop!_OS."

# Push to remote (optional)
git push
```

---

## Complete Workflow Summary

### When You Make a Global Change: Follow This Flow

```
1. MAKE THE CHANGE
   ├─ Edit file locally
   ├─ Validate syntax
   ├─ Restart (if config change)
   └─ Test functionality

2. COMMIT TO VERSION CONTROL
   ├─ Check: git status
   ├─ Stage: git add files
   ├─ Scan: gemini-git-helper.sh (before commit!)
   └─ Commit: git commit -m "conventional format"

3. UPDATE SYSTEM RESTORATION
   ├─ Copy files to pop-os-oled-setup/configs/copilot/
   ├─ Update documentation
   ├─ Add to CHANGES.md
   └─ Commit: git commit (system repo)
```

---

## Common Change Scenarios

### Scenario 1: Add New Example to COPILOT.md

```bash
# 1. Edit locally
nano /home/max/COPILOT.md
# Add example...
# Save

# 2. Test the example
copilot -p "your new example"

# 3. Commit to version control
cd /path/to/local/copilot-repo/
git add COPILOT.md
gemini-git-helper.sh
git commit -m "docs(copilot): add new GitHub MCP example"

# 4. Update system repo
cp /home/max/COPILOT.md /mnt/storage/Programacao/Repositorios/pop-os-oled-setup/configs/copilot/COPILOT.md
cd /mnt/storage/Programacao/Repositorios/pop-os-oled-setup/
git add configs/copilot/COPILOT.md
git commit -m "docs(copilot): sync new example from local setup"
git push
```

### Scenario 2: Rotate API Key

```bash
# 1. Get new key from provider

# 2. Update locally
nano ~/.secrets
# Update: export GEMINI_API_KEY='new-key'
# Save

# 3. Reload and test
source ~/.secrets
exit
copilot
copilot -p "test"

# 4. Update documentation if needed
nano /home/max/COPILOT.md
# Add note about key rotation date

# 5. Commit documentation change
cd /path/to/local/copilot-repo/
git add COPILOT.md
gemini-git-helper.sh
git commit -m "docs(copilot): note API key rotation on 2026-02-16"

# 6. Update system repo
cp /home/max/COPILOT.md /mnt/storage/Programacao/Repositorios/pop-os-oled-setup/configs/copilot/COPILOT.md
cd /mnt/storage/Programacao/Repositorios/pop-os-oled-setup/
git add configs/copilot/COPILOT.md
git commit -m "docs(copilot): update after API key rotation"
git push
```

### Scenario 3: Add New MCP Server

```bash
# 1. Edit settings.json locally
cp ~/.copilot/settings.json ~/.copilot/settings.json.bak
nano ~/.copilot/settings.json
# Add new MCP...

# 2. Validate and test
jq . ~/.copilot/settings.json
exit
copilot
copilot mcp list

# 3. Update documentation
nano /home/max/COPILOT.md
# Add new MCP to section 6
nano /home/max/TOOL_COMPARISON.md
# Add new MCP to feature table

# 4. Commit to version control
cd /path/to/local/copilot-repo/
git add COPILOT.md TOOL_COMPARISON.md
gemini-git-helper.sh
git commit -m "feat(copilot): add new MCP server documentation"

# 5. Update system repo
# Copy ONLY template (no actual config with secrets)
cp ~/.copilot/settings.json ~/.copilot/settings.json.template
cp ~/.copilot/settings.json.template /mnt/storage/Programacao/Repositorios/pop-os-oled-setup/configs/copilot/settings.json.template
cp /home/max/COPILOT.md /mnt/storage/Programacao/Repositorios/pop-os-oled-setup/configs/copilot/COPILOT.md

# 6. Commit to system repo
cd /mnt/storage/Programacao/Repositorios/pop-os-oled-setup/
git add configs/copilot/
git commit -m "feat(copilot): add new MCP configuration template

Added [MCP Name] to configuration with documentation updates."
git push
```

---

## Change Tracking Template

Create a log in pop-os-oled-setup for tracking changes:

```bash
cat > /mnt/storage/Programacao/Repositorios/pop-os-oled-setup/COPILOT_CHANGES.md << 'EOF'
# Copilot CLI Setup - Change Log

## Guidelines
- Update this file when making significant global changes
- Tracks changes for system restoration purposes
- Includes date, change type, and brief description

## Changes

### 2026-02-16 - Initial Setup
- **Type**: New
- **Scope**: Complete Copilot CLI setup with MCP configuration
- **Files**:
  - configs/copilot/COPILOT.md (744 lines)
  - configs/copilot/TOOL_COMPARISON.md (260 lines)
  - configs/copilot/SETUP_CHECKLIST.md (214 lines)
  - configs/copilot/settings.json.template
- **Notes**: GitHub MCP tested and working

### YYYY-MM-DD - [Your Change]
- **Type**: [New/Update/Fix]
- **Scope**: [What changed]
- **Files**: [List files]
- **Notes**: [Any important details]

EOF
```

---

## Validation Checklist

Before committing any global change:

### For Local Changes
- [ ] Syntax validated (JSON with `jq`, Markdown by reading)
- [ ] Functionality tested
- [ ] No hardcoded secrets introduced
- [ ] Related documentation updated

### For Version Control
- [ ] Files staged appropriately (no ~/.secrets!)
- [ ] Commit message follows conventional format
- [ ] `gemini-git-helper.sh` passed (no secrets detected)
- [ ] Commit message documents the change

### For System Restoration
- [ ] Files copied to pop-os-oled-setup/configs/copilot/
- [ ] settings.json.template has placeholders (no real API keys)
- [ ] Documentation updated in pop-os-oled-setup/
- [ ] CHANGES.md updated with details
- [ ] System repo commit ready to push

---

## Security Reminders

### ✅ DO:
- Store API keys in ~/.secrets (chmod 600)
- Use template files with ${VARIABLE_NAME} placeholders
- Commit only documentation to public repos
- Backup configuration before editing
- Validate JSON after changes

### ❌ DON'T:
- Commit ~/.secrets to git
- Hardcode API keys in COPILOT.md
- Commit actual settings.json with real keys
- Edit files while Copilot is running
- Skip validation steps

---

## System Restoration: Using Saved Config

When you need to restore Copilot CLI on a fresh Pop!_OS install:

```bash
# 1. Install Copilot CLI
# [Follow official installation]

# 2. Get files from pop-os-oled-setup
cd /mnt/storage/Programacao/Repositorios/pop-os-oled-setup/

# 3. Copy documentation
cp configs/copilot/COPILOT.md /home/max/COPILOT.md
cp configs/copilot/TOOL_COMPARISON.md /home/max/TOOL_COMPARISON.md
cp configs/copilot/SETUP_CHECKLIST.md ~/.copilot/SETUP_CHECKLIST.md

# 4. Copy configuration template
cp configs/copilot/settings.json.template ~/.copilot/settings.json

# 5. Add API keys
nano ~/.secrets
# Add: export GEMINI_API_KEY='your-key'
# Add: export GITHUB_PERSONAL_ACCESS_TOKEN='your-token'
chmod 600 ~/.secrets

# 6. Restart Copilot
exit
copilot

# 7. Verify
copilot mcp list
```

---

## Summary

**3-Tier Change System**:
1. **Tier 1 (Local)**: Make change, validate, test
2. **Tier 2 (Version Control)**: Commit with conventional format
3. **Tier 3 (System Restoration)**: Copy to pop-os-oled-setup, commit, push

**Key Points**:
- Documentation changes don't need restart ✅
- Config changes require restart and validation ✅
- API keys go in ~/.secrets, never committed ✅
- All significant changes tracked in pop-os-oled-setup ✅
- Templates use placeholders, not real secrets ✅

**For Help**:
- See COPILOT.md for feature documentation
- See SETUP_CHECKLIST.md for troubleshooting
- See TOOL_COMPARISON.md for workflow guidance
- Check pop-os-oled-setup/COPILOT_CHANGES.md for history
