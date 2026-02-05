# fzf - Fuzzy Command History Search

Fast fuzzy finder for command history, files, and directories. Replaces basic `Ctrl+R` with interactive search.

## Installation

```bash
sudo apt install fzf
```

## Features

| Shortcut | Function | Description |
|----------|----------|-------------|
| `Ctrl+R` | History search | Fuzzy search through command history |
| `Ctrl+T` | File search | Find files and insert path at cursor |
| `Alt+C` | Directory jump | Fuzzy cd into subdirectories |
| `**<Tab>` | Path completion | Fuzzy complete paths (e.g., `vim **<Tab>`) |

## Usage Examples

### History Search (Ctrl+R)

Press `Ctrl+R` then type partial matches:

```
ssh        → matches all ssh commands
git com    → matches "git commit", "git config", etc.
sudo apt   → matches all sudo apt commands
docker run → matches all docker run commands
```

Navigation:
- `Ctrl+J` / `Ctrl+N` - move down
- `Ctrl+K` / `Ctrl+P` - move up
- `Enter` - select
- `Esc` / `Ctrl+C` - cancel

### File Search (Ctrl+T)

Insert file path at cursor position:

```bash
vim <Ctrl+T>        # Opens fzf, select file, path inserted
cat <Ctrl+T>        # Same for any command
```

### Directory Jump (Alt+C)

Fuzzy cd into any subdirectory:

```bash
<Alt+C>             # Opens fzf showing directories
                    # Select to cd into it
```

### Path Completion (**)

Type `**` then `Tab` for fuzzy completion:

```bash
vim **<Tab>         # Fuzzy find any file
cd **<Tab>          # Fuzzy find any directory
ssh **<Tab>         # Fuzzy complete ssh hosts
kill -9 **<Tab>     # Fuzzy find process IDs
```

## Configuration

Configuration is added to `~/.bashrc` and `~/.zshrc`.

### Key Bindings Source

```bash
# Bash
source /usr/share/doc/fzf/examples/key-bindings.bash

# Zsh
source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh
```

### Appearance (Gruvbox Dark Theme)

```bash
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --info=inline
  --color=bg+:#3c3836,bg:#000000,spinner:#fb4934,hl:#928374
  --color=fg:#ebdbb2,header:#928374,info:#83a598,pointer:#fb4934
  --color=marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934
'
```

### History Size

Increased for better fzf experience:

```bash
# Bash
HISTSIZE=50000
HISTFILESIZE=100000

# Zsh
HISTSIZE=50000
SAVEHIST=100000
```

## Verification

After installation, open a new terminal:

```bash
# Check version
fzf --version

# Test history search
# Press Ctrl+R and type partial command

# Test file search
# Press Ctrl+T

# Test directory jump
# Press Alt+C
```

## Troubleshooting

### Keybindings not working

1. Ensure key-bindings are sourced in shell config
2. Open a new terminal (or `source ~/.bashrc`)
3. Check if files exist: `ls /usr/share/doc/fzf/examples/`

### Alt+C not working

Some terminals capture `Alt` key. Try:
- Use `Esc` then `c` (two keystrokes)
- Configure terminal to pass Alt key through

### History too small

Increase `HISTSIZE` and `HISTFILESIZE` in shell config.

## References

- [fzf GitHub](https://github.com/junegunn/fzf)
- [fzf Wiki](https://github.com/junegunn/fzf/wiki)
