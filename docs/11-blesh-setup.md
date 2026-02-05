# ble.sh - Bash Line Editor Setup

Modern command-line editing for Bash with syntax highlighting, auto-suggestions, and enhanced completion.

## Features

- **Syntax highlighting** - Commands, arguments, paths colored in real-time
- **Auto-suggestions** - Fish-style ghost text suggestions from history
- **Enhanced completion** - Menu-style with descriptions
- **Vim mode support** - Optional vi editing mode

## Installation

### Install ble.sh

```bash
# Clone and build ble.sh
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
make -C ble.sh install PREFIX=~/.local

# Or using the quick install script
curl -L https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf -
bash ble-nightly/ble.sh --install ~/.local/share
```

### Configure .bashrc

Add these lines to `~/.bashrc`:

```bash
# ble.sh - Bash Line Editor (syntax highlighting, auto-suggestions)
# Load early but don't attach yet (allows other configs to load first)
[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh --noattach

# ... your other bashrc content ...

# ble.sh - Attach at end (after all other configs loaded)
[[ ${BLE_VERSION-} ]] && ble-attach
```

**Important:** ble.sh must load with `--noattach` at the start and `ble-attach` at the end. This ensures proper integration with other tools like fzf.

### Install Configuration

```bash
# Copy the configuration file
cp configs/shell/blerc ~/.blerc
```

## Configuration

The configuration file (`~/.blerc`) sets up:

### Gruvbox Dark Theme

Colors matched to Kitty terminal theme:

| Element | Color | Hex |
|---------|-------|-----|
| Default text | Light cream | `#ebdbb2` |
| Commands | Green bold | `#b8bb26` |
| Variables | Blue | `#83a598` |
| Errors | Red on dark | `#fb4934` |
| Comments | Gray italic | `#928374` |
| Builtins | Orange | `#fe8019` |
| Keywords | Red | `#fb4934` |
| Directories | Blue underline | `#83a598` |

### Behavior Options

```bash
# Fish-style auto-suggestions enabled
bleopt complete_auto_complete=1

# Instant suggestions (no delay)
bleopt complete_auto_delay=0

# Dense completion menu
bleopt complete_menu_style=dense

# Syntax highlighting enabled
bleopt highlight_syntax=1
```

## Keyboard Shortcuts

### Editing

| Key | Action |
|-----|--------|
| `Ctrl+A` | Beginning of line |
| `Ctrl+E` | End of line |
| `Ctrl+W` | Delete word backward |
| `Alt+D` | Delete word forward |
| `Ctrl+U` | Delete to beginning |
| `Ctrl+K` | Delete to end |

### History

| Key | Action |
|-----|--------|
| `Ctrl+R` | Search history (works with fzf) |
| `Ctrl+P` / `Up` | Previous command |
| `Ctrl+N` / `Down` | Next command |
| `Alt+.` | Insert last argument |

### Auto-suggestions

| Key | Action |
|-----|--------|
| `Right` | Accept suggestion |
| `Ctrl+F` | Accept suggestion |
| `Alt+F` | Accept next word |
| `Tab` | Complete/menu |

## Integration with fzf

ble.sh works seamlessly with fzf. Ensure fzf is loaded after ble.sh starts but before `ble-attach`:

```bash
# In ~/.bashrc
[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh --noattach

# fzf integration
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
    source /usr/share/doc/fzf/examples/key-bindings.bash
fi

# Attach ble.sh last
[[ ${BLE_VERSION-} ]] && ble-attach
```

## Troubleshooting

### Slow startup

If bash starts slowly, check:

```bash
# Time ble.sh loading
time source ~/.local/share/blesh/ble.sh --noattach

# Should be under 200ms. If slow, try:
bleopt import_path=  # Disable optional modules
```

### Conflicts with other tools

If you experience issues with tools like tmux or screen:

```bash
# Add to ~/.blerc
bleopt term_modifyOtherKeys=0
```

### Colors not showing

Ensure your terminal supports 256 colors:

```bash
echo $TERM  # Should be xterm-256color or similar
```

## Updating

```bash
# If installed via git
cd ~/.local/share/blesh
git pull
make install PREFIX=~/.local

# Or reinstall from release
curl -L https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf -
bash ble-nightly/ble.sh --install ~/.local/share
```

## Verification

Test the installation:

```bash
# Check version
echo "ble.sh version: $BLE_VERSION"

# Test syntax highlighting (type slowly)
echo "Hello World"  # Should show colors as you type

# Test auto-suggestions (press Up to get history, then type partial match)
```

## Resources

- [ble.sh GitHub](https://github.com/akinomyoga/ble.sh)
- [ble.sh Wiki](https://github.com/akinomyoga/ble.sh/wiki)
- [Configuration Reference](https://github.com/akinomyoga/ble.sh/wiki/Manual-%C2%A72-Configuration)
