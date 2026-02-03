# Epson L3150 Printer/Scanner Setup

Epson EcoTank L3150 is a wireless all-in-one inkjet printer with integrated scanner. This guide covers driver installation on Pop!_OS/Ubuntu.

## Prerequisites

```bash
# Install dependencies
sudo apt update
sudo apt install -y lsb cups cups-client simple-scan
```

## Printer Driver Installation

### 1. Download ESC/P-R Driver

Download from [Epson Support](https://support.epson.net/linux/en/esc_p_r.php) or use direct link:

```bash
# ESC/P-R Driver (required for printing)
wget -O ~/Downloads/epson-inkjet-printer-escpr_1.8.6-1_amd64.deb \
  "https://download.ebz.epson.net/dsc/du/02/DriverDownloadInfo.do?LG2=EN&CN2=&DESSION2=&PRODUCT=&OSC=LX&DLID=131714"
```

### 2. Download Printer Utility (Optional)

```bash
# Epson Printer Utility (ink levels, nozzle check, head cleaning)
wget -O ~/Downloads/epson-printer-utility_1.2.2-1_amd64.deb \
  "https://download.ebz.epson.net/dsc/du/02/DriverDownloadInfo.do?LG2=EN&CN2=&DESSION2=&PRODUCT=&OSC=LX&DLID=128379"
```

### 3. Install Printer Packages

```bash
cd ~/Downloads
sudo dpkg -i epson-inkjet-printer-escpr_1.8.6-1_amd64.deb
sudo dpkg -i epson-printer-utility_1.2.2-1_amd64.deb

# Fix any dependency issues
sudo apt --fix-broken install
```

### 4. Add Printer via CUPS

1. Open `http://localhost:631` in browser, or use Settings > Printers
2. Click "Add Printer"
3. Select the Epson L3150 (should appear via USB or network discovery)
4. Choose driver: `Epson L3150 Series, EPSON ESC/P-R`

Or via command line:
```bash
# Find printer URI (USB or network)
lpinfo -v | grep -i epson

# Add printer (adjust URI as needed)
sudo lpadmin -p EpsonL3150 -E -v "usb://EPSON/L3150%20Series" \
  -m "epson-inkjet-printer-escpr/Epson-L3150_Series-epson-escpr-en.ppd"

# Set as default
sudo lpoptions -d EpsonL3150
```

## Scanner Driver Installation

### 1. Download Epson Scan 2 Bundle

```bash
cd ~/Downloads
wget -O epsonscan2-bundle-6.7.82.0.x86_64.deb.tar.gz \
  "https://download.ebz.epson.net/dsc/du/02/DriverDownloadInfo.do?LG2=EN&CN2=&DESSION2=&PRODUCT=&OSC=LX&DLID=132878"

# Extract bundle
tar -xzf epsonscan2-bundle-6.7.82.0.x86_64.deb.tar.gz
```

### 2. Install Scanner Packages

```bash
cd ~/Downloads/epsonscan2-bundle-6.7.82.0.x86_64.deb

# Run the installer (installs core + plugins)
sudo ./install.sh

# Or install manually:
# sudo dpkg -i core/epsonscan2_6.7.82.0-1_amd64.deb
# sudo dpkg -i plugins/epsonscan2-non-free-plugin_1.0.0.6-1_amd64.deb
# sudo apt --fix-broken install
```

### 3. Configure Scanner Access

```bash
# Add user to scanner group
sudo usermod -aG scanner $USER

# Restart SANE service
sudo systemctl restart saned.socket

# Log out and back in for group changes to take effect
```

## Usage

### Printing

```bash
# Print a file
lp -d EpsonL3150 document.pdf

# Print with options
lp -d EpsonL3150 -o media=A4 -o fit-to-page document.pdf
```

### Scanning

```bash
# Launch Epson Scan 2 GUI
epsonscan2

# Or use Simple Scan (GNOME app)
simple-scan

# Command-line scanning with scanimage
scanimage -d 'epsonscan2:networkscanner' --format=png > scan.png
```

### Printer Utility

```bash
# Check ink levels, run nozzle check, head cleaning
epson-printer-utility
```

## Wireless Setup

The L3150 supports Wi-Fi Direct and network printing:

1. On printer: Hold Wi-Fi button until light flashes
2. Connect to printer's Wi-Fi network from PC
3. Open browser to `http://192.168.1.1` or printer's IP
4. Configure Wi-Fi settings to join your network

## Troubleshooting

### Printer not detected

```bash
# Restart CUPS
sudo systemctl restart cups

# Check USB connection
lsusb | grep -i epson

# Check network discovery
avahi-browse -a | grep -i epson
```

### Scanner not found

```bash
# List SANE devices
scanimage -L

# Check Epson Scan 2 devices
epsonscan2 --list
```

### Permission issues

```bash
# Ensure user is in required groups
groups $USER  # Should include: lp, scanner

# Add if missing
sudo usermod -aG lp,scanner $USER
```

## Files Reference

| File | Version | Purpose |
|------|---------|---------|
| `epson-inkjet-printer-escpr` | 1.8.6-1 | ESC/P-R printer driver |
| `epson-printer-utility` | 1.2.2-1 | Ink levels, maintenance |
| `epsonscan2` | 6.7.82.0-1 | Scanner driver & GUI |
| `epsonscan2-non-free-plugin` | 1.0.0.6-1 | Proprietary scanner codecs |
