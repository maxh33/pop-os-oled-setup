# Copilot CLI Setup Checklist

## ✅ Completed Setup

### 1. COPILOT.md Created
- **File:** `/home/max/COPILOT.md`
- **Size:** 21 KB (744 lines)
- **Status:** ✅ Ready to use
- **Contains:** Global context guide with all sections documented

### 2. MCP Configuration Created
- **File:** `~/.copilot/settings.json`
- **Status:** ✅ Valid JSON, auto-detected
- **MCPs Configured:** 6 servers
  - ✅ github-mcp-server (GitHub integration)
  - ✅ context7 (Library docs)
  - ✅ desktop-commander (File operations)
  - ✅ playwright (Browser automation)
  - ✅ linear (Issue tracking)
  - ✅ gemini (AI analysis)

### 3. Environment Variables Set
- **Location:** `~/.secrets` (chmod 600)
- **Status:** ✅ GEMINI_API_KEY configured
- **TODO:** Add GITHUB_PERSONAL_ACCESS_TOKEN (optional for GitHub MCP)

---

## 🔧 To Activate (Required Now)

### Step 1: Restart Copilot CLI
```bash
# Exit current session
exit

# Then start a new Copilot session
copilot
```

### Step 2: Verify MCP Loaded
```bash
copilot mcp list
```

Expected output should show all 6 MCPs.

### Step 3: Test MCPs Work
```bash
# Test each MCP
copilot "List my GitHub repositories"           # github-mcp-server
copilot "What's the latest React documentation?" # context7
copilot mcp get desktop-commander               # desktop-commander
```

---

## 📚 Documentation Files

Three global context guides available:

| File | Location | Purpose |
|------|----------|---------|
| **COPILOT.md** | `/home/max/COPILOT.md` | Copilot CLI global context (THIS WINDOW) |
| **CLAUDE.md** | `~/.claude/CLAUDE.md` | Claude Code global context |
| **GEMINI.md** | `~/.gemini/GEMINI.md` | Gemini CLI global context |

Read COPILOT.md with:
```bash
cat /home/max/COPILOT.md | less
```

Or:
```bash
copilot "Show me the MCP configuration section from COPILOT.md"
```

---

## 🎯 When to Use Each Tool

### Copilot CLI (This Window)
✅ **Use for:**
- Quick code exploration (explore agent)
- Running tests/builds (task agent)
- Finding bugs in code (code-review agent)
- GitHub integration (list issues, PRs, workflows)
- Browser testing (playwright MCP)
- System file operations (desktop-commander MCP)

❌ **Don't use for:**
- Complex reasoning (use Claude Code instead)
- Large codebase analysis (use Gemini CLI instead)
- Git commits (use gemini-git-helper.sh instead)

### Claude Code (Separate Application)
✅ **Use for:**
- Writing/modifying code
- Complex reasoning & architecture
- MCP server configuration
- Advanced problem solving

### Gemini CLI (Terminal Command)
✅ **Use for:**
- AI-powered git commits (`gemini-git-helper.sh`)
- Large file analysis
- Project-wide code reviews
- Heavy lifting analysis

---

## 🚀 Quick Start Examples

### Use Copilot to Explore Code
```
copilot "Find all API endpoints in the project"
copilot "Where is authentication implemented?"
copilot "Show me the database schema"
```

### Use Copilot to Review Changes
```
copilot "Review my recent code changes for security issues"
copilot "Check if this implementation has bugs"
```

### Use Copilot for GitHub Tasks
```
copilot "List all open issues in my project"
copilot "Show the latest GitHub Actions workflow results"
copilot "Search for 'authentication' in my repositories"
```

### Use Copilot for Browser Testing
```
copilot "Navigate to example.com and take a screenshot"
copilot "Test the login form on our staging site"
```

### Use Gemini for Git Commits
```bash
cd /path/to/project
gemini-git-helper.sh                    # Suggest commits
gemini-git-helper.sh --local            # Local analysis only
gemini-git-helper.sh --scan-history     # Audit for secrets
```

---

## 🔐 Security Reminders

✅ **Always do:**
- Store API keys in `~/.secrets` (chmod 600)
- Run `gemini-git-helper.sh` before committing
- Use environment variables for secrets
- Add `*secret*`, `.env*` to `.gitignore`

❌ **Never do:**
- Hardcode API keys in code
- Commit secrets to Git
- Use `git commit --no-verify` to skip secret detection
- Share API keys in chat or documentation

---

## 📞 Troubleshooting

### MCP not available?
```bash
# Check if file exists
cat ~/.copilot/settings.json | jq .

# Verify JSON is valid
# If not valid, restore from backup or recreate

# Then restart Copilot
exit
```

### Environment variables not loaded?
```bash
# Check if ~/.secrets exists
ls -la ~/.secrets

# Source it manually
source ~/.secrets

# Verify variables are set
echo $GEMINI_API_KEY
```

### Specific MCP failing?
```bash
# Test connection
copilot mcp get <mcp-name>

# Check the specific MCP in settings.json
# Verify command and args are correct
```

---

## 📖 Next Steps

1. **Read COPILOT.md** → Full documentation
2. **Restart Copilot CLI** → Activate MCPs
3. **Test MCPs** → Verify all working
4. **Start using** → See examples in COPILOT.md
5. **Bookmark this** → Save for reference

---

**Status:** Ready to use after Copilot CLI restart ✅
**Created:** 2026-02-16
**Version:** 1.0
