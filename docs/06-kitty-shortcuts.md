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

## Config Location

`~/.config/kitty/kitty.conf`

## Useful Links

- [Official Documentation](https://sw.kovidgoyal.net/kitty/)
- [Keyboard Shortcuts Reference](https://sw.kovidgoyal.net/kitty/conf/#keyboard-shortcuts)
- [Kittens (Extensions)](https://sw.kovidgoyal.net/kitty/kittens_intro/)
