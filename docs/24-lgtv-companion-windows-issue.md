# LGTV Companion (Windows) — Screen-Wake Failure

Windows-side counterpart to [14-lg-buddy-setup.md](14-lg-buddy-setup.md). Same OLED TV (LG OLED55B3PSA) used as monitor on the dual-boot machine, but the Windows side uses a different program — **LGTV Companion** — instead of LG Buddy.

**App:** https://sourceforge.net/projects/lgtvcompanion/ (installed as a Windows service)

## Install Layout

| Path | Purpose |
|------|---------|
| `C:\Program Files\LGTV Companion\` | Binaries: `LGTV Companion.exe` (GUI), `LGTVsvc.exe` (service), `LGTVdaemon.exe`, `LGTVcli.exe`, `LGTVupdater.exe` |
| `C:\Program Files\LGTV Companion\XML\` | `LGTVCdaemon.xml`, `LGTVCother.xml` — internal state |
| `C:\ProgramData\LGTV Companion\config.json` | User config (device IP/MAC, idle-blank behavior) |
| `C:\ProgramData\LGTV Companion\log.txt` | Service log — **events only** (warnings/errors), no heartbeat |
| Service name | `LGTVsvc` (display name "LGTV Companion Service") |

Same idea as LG Buddy's `IDLE_TIMEOUT` + state-file wake, but implemented as a single Windows service instead of systemd units + swayidle.

## Incident — 2026-09-10

Screen didn't wake around lunchtime; mouse/keyboard, TV power-cycle, and waiting did nothing. Had to hard-reboot the PC.

**Log findings** (`log.txt`):
- Log only records warnings/errors, not routine activity — so absence of entries during the incident is not informative on its own.
- Last entry before the incident: `Tue Sep 08 11:05:41 [---E][PWR] Did not receive the anticipated event subscription callback prior to shutting down.`
- Then **total silence for ~2 days**, including through today's lunchtime failure.
- Next entry: `Thu Sep 10 16:51:57 [---E][PWR] ...` (same error, coinciding with the forced reboot).
- Log history (going back to July) shows a recurring pattern: `Retried twice but failed to perform work of type 2/3. Aborting!` — repeated failures to send the power-on/power-off command to the TV.

**Config** (`config.json`) had:
```json
"BlankWhenIdle": true,
"BlankWhenIdleDelay": 2,
"PowerOnTimeOut": 40
```
i.e. the service blanks the TV after 2 min idle and depends on a network command (WOL/CEC) to bring it back — the same class of mechanism as LG Buddy's idle-blank/resume, and the same class of failure Buddy's HDMI-input-gating / state-file protocol exists to avoid.

**Working theory:** `LGTVsvc` hung or stopped responding sometime after the Sep 08 11:05 error (2-day log silence backs this up) and was unable to send the wake command when idle-blank triggered at lunchtime — leaving the screen off with no way to recover short of a reboot.

## Fix Applied (temporary)

```bash
# edit C:\ProgramData\LGTV Companion\config.json
"BlankWhenIdle": false

# restart service to pick up new config
sc.exe stop LGTVsvc
sc.exe start LGTVsvc
```

This removes the idle-blank trigger entirely (TV won't auto-blank, so there's nothing to fail to un-blank). Trade-off: loses the power-saving behavior LG Buddy also provides on the Linux side.

## Status — Pending Confirmation

Monitoring `log.txt` + `sc.exe query LGTVsvc` for recurrence. **Not yet a permanent decision.** If disabling `BlankWhenIdle` holds up:
- Consider whether LG Buddy on the Linux side needs the same treatment, or whether its HDMI-input-gating + state-file protocol (see [14-lg-buddy-setup.md](14-lg-buddy-setup.md#hdmi-input-gating)) already avoids this failure mode and only the Windows app needs the workaround.
- If it recurs even with `BlankWhenIdle: false`, the service itself (not just the idle-blank feature) is the suspect — check `LGTVsvc` process state next time before rebooting, instead of losing the diagnostic window.

## Troubleshooting

```powershell
sc.exe query LGTVsvc                                    # service state
type "C:\ProgramData\LGTV Companion\log.txt"             # full log
```

From WSL:
```bash
/mnt/c/Windows/System32/sc.exe query LGTVsvc
cat "/mnt/c/ProgramData/LGTV Companion/log.txt"
cat "/mnt/c/ProgramData/LGTV Companion/config.json"
```
