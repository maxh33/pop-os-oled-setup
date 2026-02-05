# Development Tools & Shell Configuration

## Shell Completion (Case-Insensitive)

By default, bash tab completion is case-sensitive. This config makes it case-insensitive.

**File**: `~/.inputrc`

```bash
# Include system-wide inputrc
$include /etc/inputrc

# Case-insensitive tab completion
set completion-ignore-case on
```

### Installation
```bash
cp configs/shell/inputrc ~/.inputrc
```

## Node.js (via nvm)

### Installation
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install --lts
```

### Current Setup
- Node.js: v24.13.0
- npm: 11.6.2

### Global Packages
See `packages/npm-global.txt` for the list. Key ones:
- `@google/gemini-cli` - Gemini AI assistant
- `@github/copilot` - GitHub Copilot CLI

## Python

### System Python
- Python 3.12.3 (system)
- pip with user packages

### uv (Fast Python Package Manager)
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Docker

### Installation
```bash
# Add Docker's official GPG key and repository
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
```

### Current Setup
- Docker: 28.2.2
- Includes: buildx, compose plugins

## Git Configuration

### Aliases (from ~/.gitconfig or global config)
```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.cm "commit -m"
git config --global alias.lg "log --oneline --graph --decorate --all"
```

See CLAUDE.md for full alias list.

## Claude Code CLI

### Installation
```bash
npm install -g @anthropic-ai/claude-code
```

### Configuration Location
- Settings: `~/.claude/settings.json`
- MCP Servers: `~/.claude/settings.json` (mcpServers section)
- Global instructions: `~/.claude/CLAUDE.md`

### MCP Servers Configured
| Server | Purpose |
|--------|---------|
| context7 | Library documentation lookup |
| server-configs-docs | Claude Code config docs |
| desktop-commander | File/process automation |
| playwright | Browser automation |
| linear | Issue tracking |
| gemini | AI analysis assistant |

See `configs/claude/CLAUDE.md` for comprehensive MCP usage documentation including:
- Strategy guide for choosing which MCP to use
- Tool capabilities for each server
- Usage examples and best practices

## VSCodium

### Installation
```bash
# Via apt (Pop!_OS repo)
sudo apt install codium
```

### Key Extensions
- AMOLED theme (for OLED displays)
- GitLens
- Prettier
- ESLint

## Useful CLI Tools

| Tool | Purpose | Install |
|------|---------|---------|
| `htop` | System monitor | `apt install htop` |
| `bat` | Better cat | `apt install bat` |
| `fd` | Better find | `apt install fd-find` |
| `ripgrep` | Better grep | `apt install ripgrep` |
| `jq` | JSON processor | `apt install jq` |
| `tldr` | Simplified man pages | `npm install -g tldr` |

## Environment Variables

Key environment setup in `~/.profile` or `~/.bashrc`:

```bash
# Add local bin to PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Node.js via nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Gemini API (if using gemini-cli)
export GEMINI_API_KEY="your-api-key"
```
