#!/bin/bash
# Install dotool - keyboard/mouse automation tool with XKB layout support
# Required for VoxType to work correctly with non-US keyboard layouts

set -e  # Exit on error

echo "Installing dotool dependencies..."
sudo apt install -y gcc golang libxkbcommon-dev scdoc git

echo "Cloning dotool from source..."
cd /tmp
rm -rf dotool  # Clean up any previous attempts
git clone https://git.sr.ht/~geb/dotool
cd dotool

echo "Building dotool..."
./build.sh

echo "Installing dotool (requires sudo)..."
sudo ./build.sh install

echo "Configuring udev rules..."
sudo udevadm control --reload
sudo udevadm trigger

echo "Adding user to 'input' group..."
sudo usermod -aG input $USER

echo ""
echo "✅ dotool installed successfully!"
echo ""
echo "⚠️  IMPORTANT: You MUST reboot for group membership to take effect."
echo ""
echo "After reboot, test dotool with:"
echo "  echo 'type hello' | dotool"
echo ""
echo "VoxType is already configured to use dotool in ~/.config/voxtype/config.toml"
echo ""
