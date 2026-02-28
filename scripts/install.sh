#!/bin/bash
# Pop!_OS OLED Setup Installer
# Installs HDMI audio fix and related configurations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Pop!_OS OLED Setup Installer ==="
echo ""

# Check if running as root (shouldn't be)
if [ "$EUID" -eq 0 ]; then
    echo "Error: Don't run this script as root. Run as your normal user."
    exit 1
fi

# Create directories
echo "Creating directories..."
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
mkdir -p ~/.config/pipewire/pipewire.conf.d
mkdir -p ~/.config/systemd/user
mkdir -p ~/.local/bin
mkdir -p ~/.local/state
mkdir -p ~/.ipython/profile_default/startup

# Create ~/.secrets from template if it doesn't exist
if [ ! -f ~/.secrets ]; then
    echo "Creating ~/.secrets template..."
    cp "$REPO_DIR/configs/shell/api-keys.template" ~/.secrets
    chmod 600 ~/.secrets
    echo "IMPORTANT: Edit ~/.secrets and add your actual API keys"
fi

# Copy WirePlumber config
echo "Installing WirePlumber config..."
cp "$REPO_DIR/configs/wireplumber/"*.conf ~/.config/wireplumber/wireplumber.conf.d/

# Copy PipeWire config
echo "Installing PipeWire config..."
cp "$REPO_DIR/configs/pipewire/"*.conf ~/.config/pipewire/pipewire.conf.d/

# Copy ALSA config
echo "Installing ALSA config..."
cp "$REPO_DIR/configs/asoundrc" ~/.asoundrc

# Copy systemd services
echo "Installing systemd services..."
cp "$REPO_DIR/configs/systemd/"*.service ~/.config/systemd/user/
cp "$REPO_DIR/configs/systemd/"*.timer ~/.config/systemd/user/

# Copy scripts
echo "Installing scripts..."
cp "$REPO_DIR/scripts/hdmi-audio-fix.sh" ~/.local/bin/
cp "$REPO_DIR/scripts/hdmi-audio-watchdog.sh" ~/.local/bin/
cp "$REPO_DIR/scripts/hdmi-audio-hotplug.sh" ~/.local/bin/
cp "$REPO_DIR/scripts/audio-switch.sh" ~/.local/bin/
cp "$REPO_DIR/scripts/display-verify.sh" ~/.local/bin/
chmod +x ~/.local/bin/hdmi-audio-*.sh
chmod +x ~/.local/bin/audio-switch.sh
chmod +x ~/.local/bin/display-verify.sh

# Ensure ~/.bashrc sources ~/.secrets
if ! grep -q '\.secrets' ~/.bashrc; then
    echo ""
    echo "NOTE: Add to your ~/.bashrc (after ~/.bash_aliases block):"
    echo '  if [ -f ~/.secrets ]; then'
    echo '      . ~/.secrets'
    echo '  fi'
fi

# Install udev rule (requires sudo)
echo ""
echo "Installing udev rule (requires sudo)..."
sudo cp "$REPO_DIR/configs/udev/99-hdmi-audio-fix.rules" /etc/udev/rules.d/
sudo udevadm control --reload-rules

# Install sudoers rule (requires sudo)
echo "Installing sudoers rule for hda-verb..."
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/hda-verb" | sudo tee /etc/sudoers.d/hdmi-audio > /dev/null
sudo chmod 440 /etc/sudoers.d/hdmi-audio

# Reload systemd
echo "Reloading systemd..."
systemctl --user daemon-reload

# Enable services
echo "Enabling services..."
systemctl --user enable hdmi-audio-fix.service
systemctl --user enable hdmi-audio-watchdog.timer

# Start watchdog timer
echo "Starting watchdog timer..."
systemctl --user start hdmi-audio-watchdog.timer

# Restart PipeWire
echo "Restarting PipeWire..."
systemctl --user restart pipewire pipewire-pulse wireplumber
sleep 2

# Run the fix script
echo "Running HDMI audio fix..."
~/.local/bin/hdmi-audio-fix.sh > /dev/null 2>&1 || true

# Disable Bluetooth auto-switch to headset profile (keeps dedicated mic)
echo "Configuring Bluetooth audio settings..."
wpctl settings bluetooth.autoswitch-to-headset-profile false 2>/dev/null
wpctl settings -s bluetooth.autoswitch-to-headset-profile 2>/dev/null

# Install WakaTime terminal tracking (if wakatime.cfg exists — i.e. VSCodium already set it up)
if [ -f ~/.wakatime.cfg ]; then
    echo ""
    echo "Setting up WakaTime terminal tracking..."

    # terminal-wakatime
    if [ ! -f ~/.wakatime/terminal-wakatime ]; then
        echo "  Installing terminal-wakatime..."
        curl -fsSL http://hack.club/terminal-wakatime.sh | bash
    else
        echo "  terminal-wakatime already installed, skipping."
    fi

    # IPython startup hook
    if [ ! -f ~/.ipython/profile_default/startup/wakatime_startup.py ]; then
        echo "  Installing IPython WakaTime startup hook..."
        cp "$REPO_DIR/configs/wakatime/ipython_wakatime_startup.py" \
           ~/.ipython/profile_default/startup/wakatime_startup.py
    else
        echo "  IPython WakaTime hook already installed, skipping."
    fi

    # Python packages (ipython + repl-python-wakatime)
    if ! python3 -c "import repl_python_wakatime" 2>/dev/null; then
        echo "  Installing Python WakaTime packages..."
        pip install --break-system-packages repl-python-wakatime ipython
    else
        echo "  repl-python-wakatime already installed, skipping."
    fi

    echo "  WakaTime terminal tracking configured."
    echo "  Run 'source ~/.bashrc' or open a new terminal to activate."
    echo "  See docs/15-wakatime-setup.md for details."
else
    echo ""
    echo "NOTE: ~/.wakatime.cfg not found. Skipping WakaTime terminal setup."
    echo "      Install VSCodium + WakaTime extension first, then re-run this script."
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "1. Test audio: paplay /usr/share/sounds/freedesktop/stereo/complete.oga"
echo "2. If no sound, toggle HDMI Deep Color in TV settings"
echo "3. Switch audio: audio-switch.sh [hdmi|bluetooth|bluetooth <name>]"
echo "4. Check docs/02-nvidia-hdmi-audio.md for troubleshooting"
echo "5. Open a new terminal to activate WakaTime terminal tracking"
echo "6. Dashboard: https://wakatime.com/dashboard"
echo ""
echo "Enjoy your distortion-free HDMI audio!"
