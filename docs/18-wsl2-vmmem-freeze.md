# WSL2 Full Freeze from Uncapped vmmem (Docker pulls / heavy scans)

## The Problem

WSL2 becomes completely unresponsive — new terminals hang on any command, not just the one running the heavy job. Only fix at that point is a full Windows reboot (`wsl --shutdown` doesn't even respond).

Trigger observed: running a `docker image pull` loop (~5GB across several images) back-to-back with a heavy static-analysis scan (Semgrep) in the same WSL instance, on a machine with no `.wslconfig`.

## Root Cause

WSL2 has no memory cap by default — it can grow the `vmmem` process up to ~50% of host RAM, and **does not release it until `wsl --shutdown`**. A large Docker image pull (layer extraction is memory-heavy) or a multicore static-analysis scan can spike `vmmem` fast enough to starve the whole VM, freezing every WSL terminal at once — not just the process that triggered it. This is a well-documented WSL2 + Docker failure class, not a bug in the specific tool being run.

## THE FIX

Cap `vmmem` memory/CPU/swap so a runaway process degrades instead of freezing the host. File goes on the **Windows** side (not inside WSL):

`C:\Users\<user>\.wslconfig`:

```ini
[wsl2]
memory=8GB
processors=4
swap=4GB
```

Adjust `memory=` to roughly half the host's RAM. Apply from PowerShell (outside WSL — a WSL instance can't shut itself down):

```powershell
wsl --shutdown
```

Then reopen a WSL terminal. No full Windows reboot needed — `wsl --shutdown` alone is the recovery step once the cap exists; a full reboot is only what you need the first time, before the cap is in place.

## Prevention for Heavy Docker/Scan Workloads

- Run `docker pull` / `trivy image` loops one image at a time, checking `free -h` / `docker system df` between each — not chained in one command.
- Run SAST scans (Semgrep, etc.) as a separate step from Docker pulls, not back-to-back.
- First pass of a memory-heavy scanner: cap concurrency explicitly (e.g. Semgrep `-j 1`) rather than trusting the default multicore behavior on an uncapped VM.

## Reference

Config backed up at `configs/wsl/.wslconfig` — copy to `C:\Users\<user>\.wslconfig` on any new WSL machine.
