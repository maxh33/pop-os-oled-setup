# Kitty Terminal Shortcuts

## Copy & Paste

| Action | Shortcut |
|--------|----------|
| **Copy** | `Ctrl+Shift+C` |
| **Paste** | `Ctrl+Shift+V` |
| **Copy on select** | Just select text with mouse (auto-copies) |
| **Paste from selection** | `Shift+Insert` or middle-click |

## Window Management (splits)

| Action | Shortcut |
|--------|----------|
| New window (split) | `Ctrl+Shift+Enter` |
| Close window | `Ctrl+Shift+W` |
| Next window | `Ctrl+Shift+]` |
| Previous window | `Ctrl+Shift+[` |
| Move window forward | `Ctrl+Shift+F` |
| Cycle layouts | `Ctrl+Shift+L` |
| Resize mode | `Ctrl+Shift+R` (then use arrows, Esc to exit) |

## Tabs

| Action | Shortcut |
|--------|----------|
| New tab | `Ctrl+Shift+T` |
| Close tab | `Ctrl+Shift+Q` |
| Next tab | `Ctrl+Shift+Right` or `Ctrl+Shift+.` |
| Previous tab | `Ctrl+Shift+Left` or `Ctrl+Shift+,` |
| Go to tab N | `Ctrl+Shift+1` through `9` |
| Move tab forward | `Ctrl+Shift+.` |

## Scrolling

| Action | Shortcut |
|--------|----------|
| Scroll up | `Ctrl+Shift+Up` or `Ctrl+Shift+Page_Up` |
| Scroll down | `Ctrl+Shift+Down` or `Ctrl+Shift+Page_Down` |
| Scroll to top | `Ctrl+Shift+Home` |
| Scroll to bottom | `Ctrl+Shift+End` |
| Browse scrollback in pager | `Ctrl+Shift+H` |

## Useful Features

| Action | Shortcut |
|--------|----------|
| **Open URL hints** | `Ctrl+Shift+E` (click numbers to open URLs) |
| Increase font size | `Ctrl+Shift+Equal` |
| Decrease font size | `Ctrl+Shift+Minus` |
| Reset font size | `Ctrl+Shift+Backspace` |
| Reload config | `Ctrl+Shift+F5` |
| Full screen | `Ctrl+Shift+F11` |
| Unicode input | `Ctrl+Shift+U` |
| Edit config | `Ctrl+Shift+F2` |

## Kittens (built-in tools)

```bash
# Browse/select themes
kitten themes

# Show keyboard shortcuts (press keys to see names)
kitty --debug-keyboard

# SSH with automatic terminfo
kitten ssh user@host

# Transfer files over SSH
kitten transfer file.txt remote:~/

# Show images in terminal
kitten icat image.png

# Diff files with syntax highlighting
kitten diff file1 file2
```

## Quick Reference

The pattern is mostly `Ctrl+Shift+<key>`:

- **C/V** = copy/paste
- **T** = new tab
- **Enter** = new window
- **Arrows** = navigate tabs
- **]** / **[** = navigate windows
- **E** = URL hints (very useful)
- **H** = scrollback in pager

---

## ble.sh (Bash Line Editor)

Enhanced line editing for Bash — syntax highlighting, autosuggestions, and vim-like modes.

### Editing

| Action | Shortcut |
|--------|----------|
| Accept autosuggestion | `Right Arrow` or `End` |
| Accept first word of suggestion | `Alt+F` |
| Complete (tab menu) | `Tab` |
| Cycle completions forward | `Tab` (repeatedly) |
| Cycle completions backward | `Shift+Tab` |
| Clear screen | `Ctrl+L` |
| Undo | `Ctrl+/` or `Ctrl+Z` |
| Redo | `Ctrl+Shift+/` |

### Navigation

| Action | Shortcut |
|--------|----------|
| Move word left | `Alt+B` or `Ctrl+Left` |
| Move word right | `Alt+F` or `Ctrl+Right` |
| Beginning of line | `Home` or `Ctrl+A` |
| End of line | `End` or `Ctrl+E` |

### History

| Action | Shortcut |
|--------|----------|
| Previous command | `Up Arrow` |
| Next command | `Down Arrow` |
| Search history backward | `Ctrl+R` |
| Search history forward | `Ctrl+S` |

### Deletion

| Action | Shortcut |
|--------|----------|
| Delete word backward | `Ctrl+W` or `Alt+Backspace` |
| Delete word forward | `Alt+D` |
| Delete to end of line | `Ctrl+K` |
| Delete to start of line | `Ctrl+U` |

---

## fzf (Fuzzy Finder)

Interactive fuzzy search for files, history, and more.

### Shell Keybindings

| Action | Shortcut |
|--------|----------|
| **Search command history** | `Ctrl+R` (overrides default) |
| **Find files** | `Ctrl+T` (inserts path at cursor) |
| **Change directory** | `Alt+C` (cd into selected dir) |

### Inside fzf (when the finder is open)

| Action | Shortcut |
|--------|----------|
| Move up/down | `Ctrl+K` / `Ctrl+J` or arrow keys |
| Select item | `Enter` |
| Cancel | `Esc` or `Ctrl+C` |
| Toggle selection (multi) | `Tab` |
| Select all | `Ctrl+A` |
| Scroll preview up/down | `Shift+Up` / `Shift+Down` |

### Inline Usage

```bash
# Fuzzy-find a file and open it
vim $(fzf)

# Pipe anything into fzf
git log --oneline | fzf

# Preview files while searching
fzf --preview 'cat {}'

# Kill a process interactively
kill -9 $(ps aux | fzf | awk '{print $2}')
```

### Tab Completion (with fzf-tab or **-triggers)

```bash
cd **<Tab>       # Fuzzy directory picker
vim **<Tab>      # Fuzzy file picker
ssh **<Tab>      # Fuzzy host picker
export **<Tab>   # Fuzzy env variable picker
```

---

## Config Location

`~/.config/kitty/kitty.conf`

## Useful Links

- [Official Documentation](https://sw.kovidgoyal.net/kitty/)
- [Keyboard Shortcuts Reference](https://sw.kovidgoyal.net/kitty/conf/#keyboard-shortcuts)
- [Kittens (Extensions)](https://sw.kovidgoyal.net/kitty/kittens_intro/)
- [ble.sh GitHub](https://github.com/akinomyoga/ble.sh)
- [fzf GitHub](https://github.com/junegunn/fzf)
