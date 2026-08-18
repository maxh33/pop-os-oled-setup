# 20 - Steam / Proton Gaming Setup

Steam, Proton compatibility, GameMode integration, and reusing an existing Windows game library across the dual-boot NTFS drive.

## Steam Install

```bash
sudo apt update && sudo apt install steam
```

### Known gotcha: `anbox-binder` dkms conflict

If you have a leftover `anbox-binder` dkms module (old Anbox Android-emulation leftover, superseded by Waydroid), installing Steam pulls in `linux-headers`/`linux-image` updates that trigger a dkms autoinstall — and `anbox-binder` fails to build against newer kernels (`kill_litter_super` removed from the kernel API), which blocks `linux-generic`, `linux-system76`, `pop-desktop`, etc. from configuring.

Symptom: `apt install steam` ends in `dpkg: error processing package linux-headers-... instantiated`, `E: Sub-process /usr/bin/dpkg returned an error code (1)`.

Fix — the module isn't tracked by dpkg (orphan dkms tree), so remove it directly:

```bash
sudo dkms remove anbox-binder/1 --all
sudo rm -rf /usr/src/anbox-binder-1
sudo dpkg --configure -a
```

Then re-run `sudo apt install steam` if it didn't finish.

## Proton (Windows game compatibility)

1. Steam > Settings > Compatibility > enable **"Enable Steam Play for all other titles"**, pick a Proton version (Experimental or latest numbered).
2. Steam does **not** filter your library by Linux compatibility — check per game before installing:
   - [ProtonDB](https://www.protondb.com/) — Platinum/Gold = runs well, Bronze/Borked = expect trouble or skip
   - Games with kernel-level anti-cheat (Easy Anti-Cheat, BattlEye) mostly fail unless the developer explicitly opted in to Linux support — check [Are We Anti-Cheat Yet](https://areweanticheatyet.com/)

## Reusing an existing Windows Steam library (shared NTFS drive)

If a Steam library already lives on a shared NTFS drive (e.g. `/mnt/storage/`) from the Windows install, Linux Steam can reuse it instead of re-downloading:

1. Steam > Settings > Storage > add the folder that contains the Windows install's `steamapps` directory (the library root, not the individual game folder).
2. Steam reads the existing `.acf` manifests and installed files, then does an integrity check — only patch deltas are re-downloaded, not the full game.
3. The executable still needs Proton on top regardless of where the files come from — configure Proton per game under Properties > Compatibility.

Requirements / gotchas:
- The NTFS mount must be **writable** (Steam writes manifest/cache files there). Check with `mount | grep storage`.
- Disable Windows **Fast Startup** (Control Panel > Power Options) — it leaves NTFS in a "dirty" state that Linux won't mount with write access.
- Save games usually do **not** carry over (they live in Windows `Documents`/`AppData`, outside `steamapps`) unless the game uses Steam Cloud.
- Never have Windows and Linux mount/write the same NTFS volume at once — not an issue in a normal dual-boot (only one OS runs at a time), but don't hibernate Windows and boot straight into Linux expecting to resume later.

Battle.net / Epic / other launchers don't use Steam's manifest format, so this reuse trick doesn't apply directly — use Lutris instead (per-game script, can point at an existing install directory manually).

## GameMode (auto-suspend background GPU load during gaming)

[Feral GameMode](https://github.com/FeralInteractive/gamemode) runs custom hook scripts when any game starts/stops — used here to free GPU VRAM held by a local transcription daemon (see [08-voxtype-setup.md](08-voxtype-setup.md)) while gaming.

```bash
sudo apt install gamemode
```

Reference config: [`configs/gamemode/gamemode.ini`](../configs/gamemode/gamemode.ini) → deploy to `~/.config/gamemode.ini`:

```ini
[custom]
start=systemctl --user stop voxtype.service
end=systemctl --user start voxtype.service
```

Integration is automatic, no per-game setup required:
- **Steam + Proton**: Proton auto-detects GameMode if installed system-wide and requests it — no launch option needed. If it doesn't trigger for a specific game, force it with launch option `gamemoderun %command%`.
- **Lutris**: Preferences > System options > enable **"Feral GameMode"** — applies to every Lutris-managed game at once.
- **Native Linux games outside Steam/Lutris**: `gamemoderun ./game-binary`.

Verify the hook fires:

```bash
gamemoded -t   # look for "Running start/end script" ... "Passed" under Verifying Scripts
systemctl --user is-active voxtype.service   # should flip to "inactive" while gamemode test/game runs
```

(The `gamemoded -t` self-test may report an unrelated `ioprio` failure — that's a sandboxed/restricted-permission false positive in the test harness itself, not a sign the hook is broken.)

## Known limitation: 4K @ 120Hz capped at 4K60 / 1440p120 on NVIDIA + Linux

If a DisplayPort-to-HDMI 2.1 adapter/cable delivers 4K@120Hz on Windows but Linux only exposes up to 4K@60Hz (with 120Hz available only at 1440p and below), this is **not** a cable, adapter, or COSMIC compositor problem — it's an NVIDIA proprietary Linux driver gap in DSC (Display Stream Compression) support for high-bandwidth modes. 4K120 requires DSC to fit the DisplayPort/HDMI bandwidth budget; the Windows driver negotiates it fully, the Linux driver currently doesn't for these extreme cases.

Confirm the connector/mode list with:

```bash
cosmic-randr list
```

If 4K@120Hz never appears in the list (vs. appearing but failing to apply), it's this driver gap, not a COSMIC UI bug. Tracked upstream, no local fix available yet:
- [NVIDIA/open-gpu-kernel-modules#179](https://github.com/NVIDIA/open-gpu-kernel-modules/issues/179) — DSC support request
- [pop-os/cosmic-comp#1334](https://github.com/pop-os/cosmic-comp/issues/1334) — separate, unrelated COSMIC bug where the refresh-rate *picker* itself caps at 120Hz even when a display supports more (only relevant if your mode list already shows the higher rate but the UI won't apply it)

Workaround until NVIDIA closes the gap: use 1440p@120Hz for high refresh rate gaming, or 4K@60Hz for desktop work; dual-boot to Windows when 4K120 specifically matters.
