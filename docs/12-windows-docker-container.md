# Windows Docker Container (dockurr/windows)

Run Windows 11 inside Docker using QEMU/KVM. Useful for accessing Windows apps and shared files from the dual-boot setup.

## Prerequisites

- Docker and Docker Compose
- KVM support (`/dev/kvm` must exist)
- `freerdp3-x11` for RDP clipboard support

```bash
sudo apt install freerdp3-x11
```

## Project Location

```
/mnt/storage/Programacao/Repositorios/windows/
├── compose.yml      # Docker Compose configuration
├── data/            # VM disk and config (persistent)
└── windows/         # Shared storage (accessible inside VM as D: drive)
```

The `data/` and `windows/` directories are shared with the Windows dual-boot — both OS instances access the same VM.

## Starting the Container

```bash
cd /mnt/storage/Programacao/Repositorios/windows
docker compose up -d
```

### Symlink Warning

If `/home/max/Repositorios` is a symlink, Docker will fail with:

```
error while creating mount source path: mkdir /home/max/Repositorios: file exists
```

Always start from the real path (`/mnt/storage/Programacao/Repositorios/windows/`) or use `docker compose` which resolves relative paths from the compose.yml directory.

## Compose Configuration

```yaml
services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "11"
      RAM_SIZE: "8G"
      CPU_CORES: "4"
      SPICE_CLIPBOARD: "Y"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - 8006:8006          # noVNC web interface
      - 3389:3389/tcp      # RDP
      - 3389:3389/udp      # RDP (UDP)
    volumes:
      - ./windows:/storage
      - ./data:/data
    restart: always
    stop_grace_period: 2m
```

## Accessing the VM

### noVNC (Quick Visual Access)

Open http://localhost:8006 in a browser. No clipboard sharing — use for quick checks and initial setup only.

### RDP via xfreerdp3 (Recommended)

RDP provides full clipboard support (copy/paste between Linux and Windows).

**Get the container IP** (changes on each restart):

```bash
docker inspect windows --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

**Connect:**

```bash
xfreerdp3 /v:172.18.0.2:3389 /u:Docker /p:<YOUR_PASSWORD> /sec:tls /clipboard /cert:ignore
```

Replace `172.18.0.2` with the actual container IP from the inspect command.

> **Why not localhost?** Docker's NAT forwarding for port 3389 has a routing issue with this container. Connecting directly to the container IP (`172.18.0.2`) works reliably.

> **Why `/sec:tls`?** NLA (default security) fails with this VM setup. Forcing TLS resolves the connection.

### RDP Setup (One-Time)

RDP must be enabled inside Windows before the first RDP connection:

1. Open noVNC at http://localhost:8006
2. Go to **Settings > System > Remote Desktop**
3. Toggle **Enable Remote Desktop** to **On**

## Credentials

Default user: `Docker` (set via `net user` inside the VM).

### Reset Password

If you forget the credentials, use noVNC to access the Windows desktop and open Command Prompt:

```cmd
net user
net user Docker <YOUR_PASSWORD_HERE>
```

### Set Credentials for New Installations

For fresh VMs, add to `compose.yml` environment:

```yaml
environment:
  USERNAME: "Docker"
  PASSWORD: "<YOUR_PASSWORD_HERE>"
```

## Stopping the Container

Always stop gracefully to prevent VM disk corruption:

```bash
cd /mnt/storage/Programacao/Repositorios/windows
docker compose down
```

The `stop_grace_period: 2m` gives Windows time to shut down cleanly.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Container fails to start (symlink error) | Use real path, not symlink. Start with `docker compose` from project dir |
| RDP connection refused | Check if Windows has booted: `docker logs windows`. Enable RDP via noVNC |
| xfreerdp3 `LOGON_FAILURE` | Wrong credentials. Reset via `net user` in noVNC |
| xfreerdp3 `TRANSPORT_FAILED` on localhost | Use container IP instead: `docker inspect windows ...` |
| noVNC clipboard not working | Use RDP instead — noVNC clipboard is unreliable with Windows VMs |
| VM disk corruption | Always use `docker compose down`, never `docker kill` |
