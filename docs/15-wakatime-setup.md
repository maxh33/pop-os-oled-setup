# WakaTime Terminal & REPL Tracking

Extends WakaTime beyond VSCodium to cover bash terminal sessions (git, npm, python, docker, etc.) and interactive Python REPL (IPython).

## What Gets Tracked

| Activity | Editor label in dashboard | Project detection |
|----------|--------------------------|-------------------|
| VSCodium file editing | `VSCodium` | Open folder |
| `git`, `npm`, `node`, `npx` in terminal | `Terminal` | `.git` root |
| `python`, `docker`, `vim`, `nano` in terminal | `Terminal` | `pyproject.toml`, `package.json`, etc. |
| `ipython` interactive session | `repl-ipython-wakatime` | `.git` root or CWD |

## Prerequisites

- WakaTime account at wakatime.com
- `~/.wakatime.cfg` with `api_key` set (VSCodium writes this automatically on first login)
- WakaTime CLI at `~/.wakatime/wakatime-cli` (VSCodium installs this too)

Verify:
```bash
cat ~/.wakatime.cfg | grep api_key   # should show your key
ls ~/.wakatime/wakatime-cli          # should exist
```

## Layer 1 — Bash Terminal (terminal-wakatime)

### Install

```bash
curl -fsSL http://hack.club/terminal-wakatime.sh | bash
```

Downloads `~/.wakatime/terminal-wakatime` (v1.1.5) and appends to `~/.bashrc`.

Reference snippet: `configs/shell/bashrc-wakatime`

### What it adds to ~/.bashrc

```bash
# terminal-wakatime setup
export PATH="$HOME/.wakatime:$PATH"
eval "$(terminal-wakatime init)"
```

Place this **after** all other configs but **before** `ble-attach` if using ble.sh.

### Commands tracked

`git`, `npm`, `node`, `npx`, `python`, `python3`, `docker`, `docker-compose`,
`vim`, `nvim`, `nano`, `make`, `cargo`, `go`, `ruby`, `php`, and more.

### Project auto-detection

Checks (in order): `.git/` root → `package.json` → `pyproject.toml` → `Cargo.toml`
→ `go.mod` → `Gemfile` → `composer.json` → current directory name.

### Verify connection

```bash
terminal-wakatime test
# ✓ Configuration is valid
# ✓ WakaTime CLI is installed
# ✓ API connection successful
```

## Layer 2 — Python REPL (repl-python-wakatime + IPython)

### Install

```bash
# Both needed — repl-python-wakatime requires IPython
pip install --break-system-packages repl-python-wakatime ipython
# Note: automatically defaults to user install at ~/.local/lib/python3.x/site-packages/
```

Installed versions:
- `repl-python-wakatime` 0.1.6
- `ipython` 9.10.0

### Configure IPython startup hook

```bash
mkdir -p ~/.ipython/profile_default/startup
cp configs/wakatime/ipython_wakatime_startup.py \
   ~/.ipython/profile_default/startup/wakatime_startup.py
```

Reference file: `configs/wakatime/ipython_wakatime_startup.py`

This runs automatically every time `ipython` starts. It hooks into IPython's
prompt system — every time a new prompt is displayed, a heartbeat is sent to WakaTime.

### How the hook works

The package wraps IPython's `prompts_class` with a WakaTime-aware version.
On every `Out[N]:` prompt render, it fires a heartbeat using the WakaTime CLI.
This means: the longer you work in a REPL session, the more heartbeats are recorded.

## Activating in existing terminals

No reboot or logout needed. In any terminal that was already open before install:

```bash
source ~/.bashrc
```

New terminals (opened after install) pick it up automatically.

## Dashboard

URL: **https://wakatime.com/dashboard**

- **Projects** tab: shows time per git project
- **Editors** tab: shows `VSCodium`, `Terminal`, `repl-ipython-wakatime` breakdown
- **Languages** tab: auto-detected from file extensions and commands
- Data appears within ~2 minutes of activity
- Dashboard timezone: configured in wakatime.com → Settings → Time Zone

### What a typical day looks like

```
VSCodium          3h 12m  ████████████░░░
Terminal          1h 45m  ███████░░░░░░░░
repl-ipython      0h 28m  ██░░░░░░░░░░░░░
```

## Troubleshooting

### terminal-wakatime not found in existing terminal

```bash
source ~/.bashrc
# or open a new terminal tab
```

### No data appearing in dashboard after 10 minutes

```bash
# Check the wakatime log for errors
cat ~/.wakatime/wakatime.log | tail -20

# Test API key manually
~/.wakatime/wakatime-cli --today
```

### IPython startup error: ModuleNotFoundError

```bash
# Verify the package is installed
python3 -c "import repl_python_wakatime; print('OK')"

# If missing, reinstall
pip install --break-system-packages repl-python-wakatime
```

### IPython startup error: cannot import name 'Wakatime'

Means an old/different version is installed. Reinstall:
```bash
pip install --break-system-packages --upgrade repl-python-wakatime
```

### WakaTime shows wrong project name

terminal-wakatime detects project from the directory you're in when you run a command.
Always `cd` into your project root first, then run commands.

## Key files

| File | Purpose |
|------|---------|
| `~/.wakatime.cfg` | API key + settings (managed by VSCodium) |
| `~/.wakatime/terminal-wakatime` | terminal-wakatime binary (v1.1.5) |
| `~/.wakatime/wakatime-cli` | WakaTime CLI (shared by all editors) |
| `~/.wakatime/wakatime.log` | Activity log and error output |
| `~/.ipython/profile_default/startup/wakatime_startup.py` | IPython hook |
| `~/.local/lib/python3.12/site-packages/repl_python_wakatime/` | Python package |

## Config file reference

`~/.wakatime.cfg` minimal working config (written by VSCodium):
```ini
[settings]
api_key = your-api-key-here
api_url = https://wakatime.com/api/v1
```

Do not hardcode the API key here manually — let VSCodium manage it or use
the WakaTime CLI wizard: `~/.wakatime/wakatime-cli --config-write`.

---

## Windows 11 (Dual-Boot)

The setup on Windows is different — terminal-wakatime has no Windows binary.
Use these equivalents instead:

| Shell | Tool | Method |
|-------|------|--------|
| PowerShell | posh-wakatime | `Install-Module` from PowerShell Gallery |
| Git Bash | bash-wakatime | Clone repo + source in `~/.bashrc` |
| Cmd.exe | ❌ None | Use PowerShell instead |

**Full setup guide and automated install script:**
`D:\Programacao\Repositorios\WakaTime-Windows\README.md`

**One-shot installer (run in PowerShell on Windows):**
```powershell
& "D:\Programacao\Repositorios\WakaTime-Windows\scripts\install.ps1"
```

Both OSes use the same WakaTime account — all activity merges in one dashboard.
