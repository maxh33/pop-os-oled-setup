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
cp "$REPO_DIR/scripts/display-verify.sh" ~/.local/bin/
chmod +x ~/.local/bin/hdmi-audio-*.sh
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

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "1. Test audio: paplay /usr/share/sounds/freedesktop/stereo/complete.oga"
echo "2. If no sound, toggle HDMI Deep Color in TV settings"
echo "3. Check docs/02-nvidia-hdmi-audio.md for troubleshooting"
echo ""
echo "Enjoy your distortion-free HDMI audio!"
