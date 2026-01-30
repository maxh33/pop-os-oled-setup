# Kitty Terminal Configuration

Kitty is a fast, GPU-accelerated terminal emulator perfect for OLED displays.

## Why Kitty for OLED

- True black background (#000000) for perfect OLED blacks
- GPU rendering reduces CPU usage
- Highly customizable
- Excellent font rendering

## Installation

```bash
# Download and install
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# Create symlinks
ln -sf ~/.local/kitty.app/bin/kitty ~/.local/bin/
ln -sf ~/.local/kitty.app/bin/kitten ~/.local/bin/
```

## Configuration

**File**: `~/.config/kitty/kitty.conf`

See `configs/kitty/kitty.conf` for the full configuration.

### Key Settings for OLED

```conf
# True black background
background #000000
foreground #ffffff

# Font settings
font_family Fira Mono
font_size 12.0

# Large scrollback for development
scrollback_lines 10000

# Tab bar style
tab_bar_style powerline

# Window padding
window_padding_width 4
```

## OLED-Optimized Theme

The included config uses:
- Pure black background (#000000)
- High contrast text
- Subtle window decorations
- Powerline-style tabs

## Tips

### Prevent OLED Burn-in
- Use a screensaver/screen blank after idle
- Don't leave static content on screen for hours
- The pure black background helps (pixels are off)

### Performance
- Kitty uses GPU acceleration automatically
- On NVIDIA, ensure you have the proprietary driver installed
