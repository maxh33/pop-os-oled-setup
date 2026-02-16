# AI Tool Comparison: When to Use Copilot vs Claude vs Gemini

## Quick Decision Matrix

| Task | Copilot | Claude | Gemini | Why? |
|------|---------|--------|--------|------|
| **Code Exploration** | ⭐⭐⭐ | ⭐ | ⭐⭐ | explore agent is fast & parallel-safe |
| **Code Writing** | ⭐ | ⭐⭐⭐ | ⭐ | Claude's reasoning is best for coding |
| **Git Commits** | ⭐ | ⭐⭐ | ⭐⭐⭐ | gemini-git-helper.sh is specialized |
| **Bug Finding** | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | Both code-review & Claude are good |
| **Large Analysis** | ⭐ | ⭐⭐ | ⭐⭐⭐ | Gemini saves Claude's context |
| **Architecture** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ | Claude's Sonnet is best |
| **GitHub Tasks** | ⭐⭐⭐ | ⭐⭐ | ⭐ | Copilot has native github-mcp-server |
| **Browser Testing** | ⭐⭐⭐ | ⭐⭐ | ⭐ | Copilot has playwright MCP |
| **System Automation** | ⭐⭐⭐ | ⭐ | ⭐ | Copilot has desktop-commander MCP |
| **Issue Tracking** | ⭐⭐⭐ | ⭐⭐ | ⭐ | Copilot has linear MCP |

---

## Detailed Comparison

### COPILOT CLI (This Window)

**Strengths:**
- ⚡ Very fast (Haiku model)
- 🔗 Native GitHub integration (github-mcp-server)
- 🌐 Browser automation (playwright)
- 📊 Issue tracking (linear)
- 💻 System operations (desktop-commander)
- 📚 Real-time docs (context7)
- 🔍 Parallel-safe exploration (explore agent)
- 🎯 Focused agents (task, code-review)

**Limitations:**
- Limited reasoning capability (Haiku model)
- Smaller context window
- Not ideal for complex architecture
- Not good for large file analysis

**Best For:**
- Quick code discovery
- Running tests/builds
- Finding specific bugs
- GitHub workflows
- System file operations
- Browser testing

**Cost:** Included in GitHub Copilot subscription

---

### CLAUDE CODE (Separate Application)

**Strengths:**
- 🧠 Excellent reasoning (Sonnet model)
- 📝 Great for writing code
- 🏗️ Excellent architecture discussions
- 🔧 MCP servers available (context7, desktop-commander, linear)
- 💾 Large context window
- 🎨 Code generation & refactoring
- 🔐 Security-focused

**Limitations:**
- 🐢 Slower than Copilot
- 🔗 No native GitHub integration in all versions
- 📚 Training data can be outdated
- 💰 May have usage limits

**Best For:**
- Writing/modifying code
- Complex problem solving
- Architecture reviews
- Code refactoring
- MCP configuration
- Learning & explanation

**Cost:** Separate subscription (if not included in bundle)

---

### GEMINI CLI (Terminal Command)

**Strengths:**
- 🚀 Fast analysis (Flash models)
- 🎯 Specialized scripts (gemini-git-helper.sh)
- 📊 Excellent for large files
- 🔍 Project-wide analysis
- 🔐 Secret scanning built-in
- 💡 Good at research
- 🌍 Web search capable

**Limitations:**
- 📦 Requires manual setup/scripting
- 🔗 No native GitHub integration
- 💭 Less nuanced reasoning than Claude
- 🎮 Not interactive like Claude/Copilot

**Best For:**
- Git commits (gemini-git-helper.sh)
- Large codebase analysis
- Project-wide reviews
- Security audits (secret scanning)
- Web research
- Saving Claude's context

**Cost:** Free tier available, paid tiers for heavy use

---

## Workflow Patterns

### Pattern 1: Quick Feature Check
```
User: "Do we have authentication implemented?"
  ↓
Copilot (explore): Fast code search
  ↓
Result: Yes, in src/auth/
```

### Pattern 2: Code Implementation
```
User: "Implement JWT authentication"
  ↓
Copilot (explore): Find existing auth patterns
  ↓
Claude Code: Write the implementation
  ↓
Copilot (code-review): Find bugs
  ↓
Gemini: Run gemini-git-helper.sh to commit
```

### Pattern 3: Large Analysis
```
User: "Analyze entire codebase architecture"
  ↓
Copilot (explore): Quick scan to understand scope
  ↓
Gemini CLI: Heavy lifting analysis (saves Claude's context)
  ↓
Result: Comprehensive report
```

### Pattern 4: Security Audit
```
User: "Check for security issues"
  ↓
Copilot (code-review): Find logic bugs
  ↓
Gemini: Run gemini-git-helper.sh --scan-history
  ↓
Result: Security + Git history audit
```

### Pattern 5: GitHub Workflow
```
User: "Show me failing tests in GitHub Actions"
  ↓
Copilot (github-mcp): List workflow runs
  ↓
Copilot: Show logs and errors
  ↓
Claude Code: Fix the issue
  ↓
Copilot (code-review): Verify fix
```

---

## Speed Comparison

| Task | Copilot | Claude | Gemini | Notes |
|------|---------|--------|--------|-------|
| List repositories | ⚡ <1s | 🐢 2-5s | 🌐 2-3s | Copilot is instant |
| Analyze 5 files | ⚡ 1-2s | 🐢 3-5s | ⏱️ 2-3s | Copilot fastest |
| Generate code | ⏱️ 2-3s | 🐢 5-10s | ⏱️ 3-5s | Claude takes time but better |
| Git commit suggest | ⏱️ 2-3s | ⏱️ 3-5s | ⚡ 1-2s | Gemini-helper is fast |
| Architecture review | 🌐 varies | 🐢 5-10s | 🌐 10-30s | Claude best, Gemini detailed |

---

## Feature Availability

| Feature | Copilot | Claude | Gemini |
|---------|---------|--------|--------|
| GitHub Integration | ✅ Native | ⚠️ Via API | ❌ Manual |
| MCP Servers | ✅ 6 servers | ✅ 6+ servers | ⚠️ Via scripts |
| Browser Testing | ✅ Playwright | ✅ Playwright | ❌ CLI only |
| Code Review | ✅ Agent | ✅ Good | ⚠️ Via CLI |
| Commit Helper | ⚠️ Manual | ⚠️ Manual | ✅ gemini-git-helper.sh |
| Secret Scanning | ⚠️ Via script | ⚠️ Via script | ✅ Built-in |
| Real-time Docs | ✅ context7 | ✅ context7 | ❌ Not available |
| Issue Tracking | ✅ Linear | ⚠️ Via Linear | ⚠️ Via CLI |

---

## Configuration Status

### COPILOT.md
- ✅ Global guide created
- ✅ 9 sections documented
- ✅ 744 lines, 21 KB
- ✅ MCP configuration: ~/.copilot/settings.json
- ✅ 6 MCPs registered

### CLAUDE.md
- ✅ Existing guide
- ✅ v3.0 with security patterns
- ✅ Located at ~/.claude/CLAUDE.md
- ✅ MCP servers pre-configured

### GEMINI.md
- ✅ Existing guide
- ✅ Located at ~/.gemini/GEMINI.md
- ✅ Custom scripts documented
- ✅ Git integration focused

---

## Recommended Workflow

```
Daily Development:
  1. Copilot: Code exploration & discovery (explore agent)
  2. Claude: Writing & modifying code
  3. Gemini: Git commits & large analysis

Code Review:
  1. Copilot: Quick bug scan (code-review agent)
  2. Claude: Deep architectural review
  3. Gemini: Security audit (gemini-git-helper.sh --scan-history)

Problem Solving:
  1. Copilot: Narrow scope & find examples
  2. Claude: Deep reasoning & implementation
  3. Gemini: Verify & commit

Research:
  1. Claude: Initial research
  2. Gemini: Deep web search
  3. Copilot: Quick facts from context7
```

---

## Summary

**Use Copilot for:** Quick tasks, MCPs, speed
**Use Claude for:** Complex reasoning, code writing, architecture
**Use Gemini for:** Large analysis, git commits, security

All three work together. Pick the right tool for each job.

---

**Reference:** See individual guides:
- `/home/max/COPILOT.md` - Copilot CLI
- `~/.claude/CLAUDE.md` - Claude Code
- `~/.gemini/GEMINI.md` - Gemini CLI
