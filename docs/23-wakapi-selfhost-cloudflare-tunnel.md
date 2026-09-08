# Wakapi Self-Host + Cloudflare Tunnel (cert-based, no API token)

Self-hosted WakaTime-compatible backend (github.com/muety/wakapi), deployed
on the idle Oracle ARM VPS instead of paying wakatime.com Premium. Client
`wakatime-cli` (see [15-wakatime-setup.md](15-wakatime-setup.md)) points
`api_url` straight at the self-hosted instance — no per-machine dual-send
config needed. Instead, **Wakapi itself relays every heartbeat onward to
wakatime.com server-side** (Settings → Integrations → WakaTime, paste the
real wakatime.com API key, Connect). One-time setup on the server, applies
to every machine automatically; the paid wakatime.com account becomes a
free offsite replica of the self-hosted data. Same screen also has an
**Import Data** button that backfills full wakatime.com history into Wakapi
(runs async, several minutes, check `docker compose logs wakapi` for
`wakatime dump import`/completion lines).

## Why this VPS

Two VPS available, picked by checking actual load first, not by assumption:

| VPS | Role | Why not / why chosen |
|-----|------|----------------------|
| netcup (`152.53.194.138`, amd64) | Busy: my-portfolio, Traefik, Prometheus/Grafana/Loki stack, Postgres, n8n | Skipped — 4.8/7.8GB RAM used, ports 80/443/8080 already owned by Traefik |
| Oracle ARM (`147.15.32.83`, aarch64, ssh alias `OracleArm`) | Nearly idle, only unrelated OpenVPN container | **Chosen** — 11GB RAM free, no port conflict, no reverse proxy yet. `ghcr.io/muety/wakapi` confirmed multi-arch (arm64 manifest present) |

## Why cert-based Tunnel auth, not an API token

Cloudflare Tunnel supports two auth methods: a scoped API token (has to be
generated, transported, and stored somewhere — CLAUDE.md secrets policy
forbids ever pasting one into a chat/session) or `cloudflared tunnel login`,
which does a browser OAuth flow and downloads a certificate **directly onto
the machine that ran the command**. No secret ever transits through a third
party (Claude, chat logs, clipboard). Revocable anytime from the Cloudflare
dashboard. This also means **zero ports 80/443 open** on the VPS and no
origin IP exposed — the tunnel makes an outbound-only connection to
Cloudflare's edge.

## Setup steps (already run for `wakapi.maxhaider.dev`)

```bash
# 1. install cloudflared (arm64 build for Oracle ARM)
ssh OracleArm "curl -sL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o /tmp/cloudflared && sudo install -m 755 /tmp/cloudflared /usr/local/bin/cloudflared"

# 2. cert-based login — prints a URL, open it in ANY browser (doesn't need
#    to be on the VPS), pick the zone, cloudflared on the VPS polls and
#    downloads the cert automatically once authorized
ssh OracleArm "cloudflared tunnel login"
# -> cert lands at ~/.cloudflared/cert.pem on the VPS, scoped to the zone picked

# 3. create the tunnel
ssh OracleArm "cloudflared tunnel create wakapi"
# -> credentials JSON at ~/.cloudflared/<tunnel-id>.json, id: 78b8e934-7eef-4c85-9f23-1c280c239e0b

# 4. route DNS — creates the CNAME to <tunnel-id>.cfargotunnel.com automatically
ssh OracleArm "cloudflared tunnel route dns wakapi wakapi.maxhaider.dev"
```

## Gotcha hit: pre-existing DNS record

Step 4 failed the first time — `wakapi.maxhaider.dev` already had an A
record pointing at the **netcup** IP (added manually beforehand, wrong
target). `cloudflared tunnel route dns` refuses to overwrite an existing
record. Fix: delete the conflicting record in the Cloudflare dashboard (DNS →
Records) first, then re-run step 4. Lesson: create the tunnel *before*
touching DNS manually, or let `route dns` own the record from the start.

## The stack (`~/wakapi/` on Oracle ARM)

Two containers, one user-defined bridge network so `cloudflared` reaches
`wakapi` by service name — no ports published to the host at all in steady
state:

```yaml
services:
  wakapi:
    image: ghcr.io/muety/wakapi@sha256:00662767731a6797d4be02cbc6c3f32b7ff8d0c683ee10ec5612856d4efbb3bf
    restart: unless-stopped
    env_file: .env
    environment:
      WAKAPI_PUBLIC_URL: https://wakapi.maxhaider.dev
    volumes:
      - wakapi-data:/data
    networks: [wakapi-net]

  cloudflared:
    image: cloudflare/cloudflared:2026.8.3   # pinned tag, not :latest — cloudflared deprecates old tunnel clients, so this wants a deliberate bump, not a frozen digest
    restart: unless-stopped
    user: "1001:1001"                        # must match the host uid that owns cloudflared/<tunnel-id>.json — the image's default nonroot uid (65532) gets EACCES on the mounted credentials file otherwise
    command: tunnel --config /etc/cloudflared/config.yml run
    volumes:
      - ./cloudflared:/etc/cloudflared:ro
    depends_on: [wakapi]
    networks: [wakapi-net]

networks:
  wakapi-net:
volumes:
  wakapi-data:
```

`./cloudflared/config.yml` (alongside the credentials JSON copied from
`~/.cloudflared/<tunnel-id>.json`):

```yaml
tunnel: 78b8e934-7eef-4c85-9f23-1c280c239e0b
credentials-file: /etc/cloudflared/78b8e934-7eef-4c85-9f23-1c280c239e0b.json
ingress:
  - hostname: wakapi.maxhaider.dev
    service: http://wakapi:3000
  - service: http_status:404
```

`.env` (never committed — values only on the VPS, mode 600):
```
WAKAPI_PASSWORD_SALT=<openssl rand -hex 32, generated once on the VPS itself>
WAKAPI_INSECURE_COOKIES=false   # safe even though cloudflared→wakapi is plain HTTP inside the tunnel — Wakapi's Secure cookie flag is a static config choice (config/cookie.go), not derived from inspecting the request's TLS state, and the browser genuinely sees https://
WAKAPI_ALLOW_SIGNUP=false       # true only during the one-time bootstrap window below
```

The image's own `Dockerfile` already defaults to sqlite3 at `/data/wakapi.db`,
`WAKAPI_LISTEN_IPV4=0.0.0.0`, a non-root `USER nonroot`, and a built-in
`HEALTHCHECK` — none of that needs restating in compose.

## Bootstrap: create the one account without ever exposing signup

Wakapi's own signup toggle can't create the *first* account while closed, and
opening it on the public hostname — even briefly — isn't necessary:

```bash
# 1. add a temporary host-only port via override file
cat > docker-compose.override.yml <<'EOF'
services:
  wakapi:
    ports:
      - "127.0.0.1:3000:3000"
EOF
docker compose up -d wakapi        # cloudflared not started yet

# 2. from your laptop
ssh -L 3000:localhost:3000 OracleArm
# open http://localhost:3000, sign up (this is your only account — signup closes right after)

# 3. close signup, drop the temporary port, bring up the full stack
sed -i 's/WAKAPI_ALLOW_SIGNUP=true/WAKAPI_ALLOW_SIGNUP=false/' .env
rm docker-compose.override.yml
docker compose up -d               # now starts cloudflared too
```

Verify signup actually closed: `curl -s https://wakapi.maxhaider.dev/signup`
should return no `<form>`/`name="password"` markup.

## WakaTime relay + history import

Settings → **Integrations** tab → **WakaTime** section: paste your real
wakatime.com API key (leave the URL field as the default
`https://api.wakatime.com/api/v1`), click **Connect**. This both starts the
live relay described above and unlocks an **Import Data** button. Click it —
it queues an async job (`running wakatime dump import for user` in
`docker compose logs wakapi`), takes several minutes for a large history.

## Backup

`~/wakapi/backup.sh` — stop, tar the named volume, restart, prune >14 days:

```bash
#!/bin/bash
set -e
cd ~/wakapi
BACKUP_DIR=~/wakapi/backups
mkdir -p "$BACKUP_DIR"
docker compose stop wakapi
docker run --rm -v wakapi_wakapi-data:/data -v "$BACKUP_DIR":/backup alpine \
  tar czf /backup/wakapi-$(date +%F).tgz -C / data
docker compose start wakapi
find "$BACKUP_DIR" -name 'wakapi-*.tgz' -mtime +14 -delete
```

Cron (Oracle's minimal Ubuntu image doesn't ship `cron` — install it first):
```bash
sudo apt-get install -y cron && sudo systemctl enable --now cron
( crontab -l 2>/dev/null | grep -v 'wakapi/backup.sh' ; \
  echo "0 3 * * * /home/ubuntu/wakapi/backup.sh >> /home/ubuntu/wakapi/backup.log 2>&1" ) | crontab -
```

Stop-the-container approach over a live `cp`/`sqlite3 .backup` because the
dataset is tiny (single-digit KB so far) and a few seconds of downtime for a
personal tool is free — reach for `.backup`/`VACUUM INTO` only once the DB is
large enough that the stop window would actually matter.

## Gotchas hit along the way

- **DNS conflict**: `wakapi.maxhaider.dev` already had a stale A record
  (pointed at netcup) from a manual add before the tunnel existed.
  `cloudflared tunnel route dns` refuses to overwrite — delete the record in
  the dashboard first, or let `route dns` own the hostname from the start.
- **cloudflared UID mismatch**: the container's default `nonroot` user
  (65532) can't read credentials JSON owned by the VPS's real user (uid
  varies — check with `id`, don't assume 1000). Pin `user:` in compose to
  match.
- **VSCodium status bar false alarm**: after hand-editing `~/.wakatime.cfg`,
  the WakaTime *extension's* status bar can show a stale "api key not
  provided" error from before the edit — the underlying `terminal-wakatime`
  CLI layer was already sending heartbeats fine (cross-check
  `~/.wakatime/wakatime-internal.cfg`'s `heartbeats_last_sent_at` against the
  server's request log). Reload the VSCodium window to clear it.
- **Secrets pasted into chat get rotated, not just noted**: an API key typed
  into a chat session is treated as compromised the moment it's sent, even
  to a low-blast-radius single-user instance — regenerate it rather than
  reuse.

## Reusable for future self-hosted services

This method isn't Wakapi-specific — any future self-hosted tool on either
VPS should default to `cloudflared tunnel login` + `route dns` over opening
ports + Caddy/nginx + Let's Encrypt, unless there's a specific reason a
Cloudflare-fronted tunnel doesn't fit (e.g. non-HTTP protocols Cloudflare
Tunnel can't proxy).
