# LG Buddy Setup

LG Buddy automatically controls an LG WebOS TV used as a computer monitor. It turns the TV on/off in response to system events (startup, shutdown, sleep, wake, screen idle/resume).

**Repository:** https://github.com/maxh33/LG_Buddy

## Features

- **Screen idle/resume:** Turns TV off after idle timeout, turns back on when user returns
- **Sleep/wake:** Turns TV off on suspend, restores on wake
- **Startup/shutdown:** Turns TV on at boot, off at shutdown
- **HDMI input gating:** Only acts when TV is on the configured HDMI input (e.g., HDMI_4). Leaves TV alone when watching other sources (console, streaming stick, etc.)

## Prerequisites

```bash
sudo apt-get install -y python3-venv python3-pip wakeonlan swayidle
```

## Installation

```bash
cd ~/LG_Buddy
./install.sh    # Interactive - prompts for TV IP, MAC, HDMI input
```

Or manual setup:

```bash
# 1. Create Python venv and install bscpylgtv
sudo python3 -m venv /usr/bin/LG_Buddy_PIP
sudo /usr/bin/LG_Buddy_PIP/bin/pip install bscpylgtv

# 2. Copy scripts
sudo cp bin/LG_Buddy_* /usr/bin/
sudo chmod +x /usr/bin/LG_Buddy_*
sudo cp bin/LG_Buddy_sleep /etc/NetworkManager/dispatcher.d/pre-down.d/
sudo chmod +x /etc/NetworkManager/dispatcher.d/pre-down.d/LG_Buddy_sleep

# 3. Enable systemd services
sudo cp systemd/LG_Buddy.service systemd/LG_Buddy_wake.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable LG_Buddy.service LG_Buddy_wake.service

# 4. Enable user screen monitor service
mkdir -p ~/.config/systemd/user/
cp systemd/LG_Buddy_screen.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now LG_Buddy_screen.service
```

## Configuration

Edit the variables at the top of each script in `bin/` (or use `configure.sh`):

| Variable | Example | Used In |
|----------|---------|---------|
| `tv_ip` | `192.168.0.155` | All scripts |
| `tv_mac` | `84:90:0A:64:10:68` | Screen_On, Startup |
| `input` | `HDMI_4` | All scripts |

Set `IDLE_TIMEOUT` in `LG_Buddy_Screen_Monitor` to match your desktop screen blank timeout.

## TV Requirements

- **TV Settings > General > Devices > External Devices > Turn on via Wi-Fi** must be **ON**
- **Quick Start+** recommended for faster wake times
- Static IP or DHCP reservation recommended

## HDMI Input Gating

Scripts only act when the TV is on the configured HDMI input. This prevents disrupting content on other inputs.

### How it works

1. **Screen_Off / sleep / Shutdown** call `bscpylgtvcommand get_input` before acting
   - Returns `com.webos.app.hdmi4` when on HDMI 4
   - If TV is on a different input → skip
   - If `get_input` fails (TV off/unreachable) → proceed anyway (safe default, `power_off` is idempotent)

2. **Screen_On / Startup** use a state file instead of querying (TV may be off):
   - State file: `/run/user/1000/lg_buddy/screen_off_by_us` (tmpfs, auto-cleaned on reboot)
   - Screen_Off/sleep create the file when they turn TV off
   - Screen_On/Startup check for the file — only act if it exists, then remove it

### State file protocol

```
Writers:    Screen_Off, sleep (create when they turn TV off)
Readers:    Screen_On, Startup (consume and remove)
Cleanup:    Automatic on reboot (tmpfs), Screen_Off "other input" branch
```

## Updating Scripts

After editing scripts in the repo:

```bash
sudo cp bin/LG_Buddy_Screen_Off bin/LG_Buddy_Screen_On bin/LG_Buddy_Startup bin/LG_Buddy_Shutdown /usr/bin/
sudo cp bin/LG_Buddy_sleep /etc/NetworkManager/dispatcher.d/pre-down.d/
sudo chmod +x /usr/bin/LG_Buddy_Screen_Off /usr/bin/LG_Buddy_Screen_On /usr/bin/LG_Buddy_Startup /usr/bin/LG_Buddy_Shutdown /etc/NetworkManager/dispatcher.d/pre-down.d/LG_Buddy_sleep
systemctl --user restart LG_Buddy_screen.service
```

## Troubleshooting

```bash
# Check current TV input
/usr/bin/LG_Buddy_PIP/bin/bscpylgtvcommand <tv_ip> get_input

# Check state file
ls -la /run/user/1000/lg_buddy/

# View screen monitor logs
journalctl --user -u LG_Buddy_screen.service -f

# Test idle detection
swayidle -w timeout 10 'echo IDLE' resume 'echo RESUMED'
```

## Reference Configs

Configs saved in `configs/lg-buddy/` use placeholder values (`192.168.X.X`, `XX:XX:XX:XX:XX:XX`). Run `configure.sh` or manually edit after copying.
