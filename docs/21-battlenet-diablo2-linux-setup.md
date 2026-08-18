# 21 - Battle.net / Diablo II Resurrected on Linux (Lutris)

Getting the Battle.net desktop app running under Lutris, reusing an existing Windows game library from the shared NTFS drive, and notes specific to Diablo II Resurrected (online play, mods).

This doc focuses on **symptoms and root causes**, not pinned version numbers — Wine/Proton builds move fast and a specific version recommendation rots within months. Where a concrete build is mentioned, it's the one validated at time of writing, not a hard requirement.

## Install

```bash
lutris lutris:install/battlenet
```

Click through the community install script (downloads `Battle.net-Setup.exe`, creates a win64 prefix, silently installs the client, launches it once). This part is reliable and rarely the source of problems.

## Known issue: black/grey screen, no keyboard input, or wineserver crash

The Battle.net client's UI is rendered via an embedded CEF (Chromium) browser, not a native Win32 UI. This rendering path is the fragile part on Linux, and symptoms vary by Wine build:

| Symptom | Root cause | Fix |
|---|---|---|
| Main pane renders solid black, sidebar text OK | CEF hardware-accelerated compositing fails under Wine | Already mitigated by the Lutris install script (it disables `HardwareAcceleration` in `Battle.net.config` automatically) — if still black, the Wine build itself is the problem, see below |
| `wineserver: ../server/sock.c:1154: complete_async_poll: Assertion` in the log, install hangs on "Scan For Games" or on any file-browse dialog | Bug in that specific Wine build's async I/O / fsync handling, triggered by a `GetVolumeInformation` call on the `Z:` drive (Wine's mapping of the whole Linux root `/`, including `/proc`, `/sys`, container/VM netns mounts that don't answer normal Win32 volume queries) | Switch Wine build (see below). Also try disabling **Fsync** in the runner's Runner Options as a secondary mitigation. |
| Login screen renders correctly (menus, sidebar, buttons) but you can't type or click into text fields — grey screen, cursor blinks but nothing responds | Running a **Proton** build (Experimental or otherwise) directly through Lutris. Proton expects to run inside Steam's runtime (`STEAM_COMPAT_*` env vars, input hooks) — outside Steam, some Proton builds have broken keyboard focus on embedded CEF dialogs | Don't use Proton for Battle.net through Lutris. Use a plain Wine build instead. |

### The fix that actually worked here

The Lutris-bundled default Wine build (`wine-ge-8-26` at time of writing) hit the wineserver assertion crash reliably, every time, regardless of Fsync settings. Switching to **Proton - Experimental** fixed rendering but broke keyboard input (see table above). Installing a **newer plain Wine build** (validated: `wine-11.14-staging`, installed via Lutris > Preferences > Runners > Wine > Manage Versions) fixed both rendering and input completely.

**General rule going forward:** if the default/bundled Wine build misbehaves with Battle.net, don't reach for Proton — install the newest plain Wine build Lutris offers (Preferences > Runners > Wine > Manage Versions) and point the Battle.net entry's Runner Options at it. Plain upstream/staging Wine tends to have more CEF/browser-embedding fixes than Proton, which is optimized for full 3D games running under Steam, not launcher UIs running standalone.

Also worth turning off (not needed for the launcher itself, pure noise): BattlEye Anti-Cheat, Easy Anti-Cheat, AMD FSR, dgvoodoo2 toggles in Runner Options.

## Reusing an existing Windows game install (shared NTFS drive)

Same constraint as the general [Steam/Proton NTFS reuse](20-steam-gaming-setup.md#reusing-an-existing-windows-steam-library-shared-ntfs-drive): the **Wine prefix itself** (`~/Games/battlenet` or wherever Lutris put it) must live on a native Linux filesystem (ext4) — Wine's `dosdevices` symlinks and the `:` character it uses in paths don't survive on NTFS. The actual **game data** (the multi-GB install) can stay on the NTFS drive without modification.

Don't let Battle.net's "Scan For Games" / "Locate" file-browser navigate through `Z:\` (Wine's mapping of the Linux root `/`) to reach the NTFS mount — this is exactly the codepath that triggers the wineserver assertion crash above, since it walks through `/proc`, `/sys`, and other pseudo-filesystems along the way. Instead, map a **dedicated Wine drive letter directly** to the NTFS games folder:

```bash
ln -s /path/to/existing/Battle.net/Jogos ~/Games/battlenet/dosdevices/d:
```

(Adjust the Lutris prefix path and the NTFS source path for your system — the prefix path is whatever the install step logged as "Creating a winXX prefix in ...".)

Then, when Battle.net asks to locate an existing game install, browse directly to `D:\` (not `Z:\mnt\...`) and select the **specific game's subfolder** (e.g. `D:\Diablo II Resurrected`), not the drive root. It'll detect the existing files and verify/patch instead of redownloading.

This trick generalizes to any Battle.net title (WoW, Diablo II Resurrected, Heroes of the Storm, Warcraft III, etc.) since the drive letter points at the whole games folder — no need to symlink each game individually.

## Anti-cheat / ban risk

Blizzard support confirmed (2025) that players are not banned for using Linux/SteamOS. Warden (Battle.net's anti-cheat) runs at the application level, scanning the game's own process — it doesn't flag the compatibility layer (Wine/Proton) itself.

## Diablo II: Resurrected specifics

- In `winecfg` for the prefix, set the Windows version to **Windows 10** — needed for the Blizzard launcher/game to start correctly.
- Enable **VKD3D** in Runner Options (DirectX 12 compatibility) — the launcher needs it even though D2R itself is DX11.
- Online play via Battle.net works normally once the client itself is working (see above) — same account, same servers as Windows.

### Mods (e.g. "D2R Reimagined")

D2R mods are loose data-file replacements loaded via a `-mod <name> -txt` launch argument — no DLL injection into the game process itself, so once the base game runs under Wine, a mod runs identically (same executable, different data).

The complication is the **mod manager** (commonly [D2RMM](https://github.com/olegbl/d2rmm)), an Electron/Node app that merges multiple mods into one output folder. D2RMM ships an experimental Linux build, and running its Windows build under Wine is reported to work but is explicitly unsupported.

Cleanest path: run D2RMM **once on the Windows side** of the dual-boot to produce the merged mod output onto the shared NTFS drive, then on Linux just add `-mod <MergedModName> -txt` to the game's launch arguments in Lutris, pointing at that already-merged folder. This avoids ever needing D2RMM itself to run under Wine.

## Troubleshooting playbook (things that wasted time getting here)

- **`pkill -f <pattern>` is not reliable in this environment** — it sometimes misses live Wine processes. If `ps aux | grep wine` still shows a PID after a `pkill`, kill it by exact PID (`kill -9 <PID>`) and re-check.
- **Killing Wine processes while a Lutris install script is still running its monitored step wipes the destination prefix.** Lutris treats an interrupted monitored process as a failed install and deletes the target directory as cleanup. If you need to abort, let the script's own "Cancel" button do it, or be prepared to fully recreate the prefix (and re-add the `dosdevices/d:` symlink) afterward.
- **Orphaned "Wine System Tray" windows can outlive their process** and won't close via the window's own X button. Find and kill them directly:
  ```bash
  DISPLAY=:1 xdotool search --onlyvisible --name "" | while read id; do
    echo "$id | $(DISPLAY=:1 xdotool getwindowname "$id")"
  done
  # find the offending window ID, then:
  DISPLAY=:1 xdotool windowkill <ID>
  ```
  (COSMIC/Wayland runs Wine apps through XWayland, typically on display `:1`, not `:0` — check with `ls /tmp/.X11-unix/`.)
- **Lutris is a single-instance GTK app.** Running `lutris lutris:install/<slug>` a second time while one is already open doesn't start a second process — it just re-activates the existing window via D-Bus. Check `pgrep -a lutris` before assuming a launch is stuck; you might be looking at the same process from an earlier command.
- **Force-killing Wine/game processes can desync GameMode's client counter**, leaving `gamemode is active` stuck forever (check with `gamemoded -s`) even though nothing is running — which means the GameMode `end=` hook (see [20-steam-gaming-setup.md](20-steam-gaming-setup.md#gamemode-auto-suspend-background-gpu-load-during-gaming), used here to restart the voxtype transcription daemon) never fires. Quick manual fix: restart the `gamemoded` user service (`systemctl --user status gamemoded.service`, then kill its PID — it respawns on next request) and manually start whatever the `end=` hook was supposed to restart. This is a debugging-session artifact from forced kills, not something normal clean game exits trigger — but see the watchdog below for a permanent safety net.

## Safety net: voxtype watchdog

Rather than relying on GameMode's `end=` hook firing cleanly every time (it won't, if a game/Wine process ever gets force-killed instead of exiting normally), a lightweight systemd timer checks every 30s and self-heals: if `voxtype.service` is stopped **and** GameMode reports no active session, it restarts voxtype. If a game really is running, it does nothing. Same pattern as the existing [`hdmi-audio-watchdog`](02-nvidia-hdmi-audio.md).

Reference files: [`scripts/voxtype-watchdog.sh`](../scripts/voxtype-watchdog.sh), [`configs/systemd/voxtype-watchdog.service`](../configs/systemd/voxtype-watchdog.service), [`configs/systemd/voxtype-watchdog.timer`](../configs/systemd/voxtype-watchdog.timer).

Deploy:

```bash
cp scripts/voxtype-watchdog.sh ~/.local/bin/
chmod +x ~/.local/bin/voxtype-watchdog.sh
cp configs/systemd/voxtype-watchdog.service configs/systemd/voxtype-watchdog.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now voxtype-watchdog.timer
```

Verify:

```bash
systemctl --user status voxtype-watchdog.timer
# force the bad state and confirm it self-heals within 30s:
systemctl --user stop voxtype.service
sleep 35
systemctl --user is-active voxtype.service   # should be back to "active"
cat ~/.local/state/voxtype-watchdog.log      # should show the restart entry
```
