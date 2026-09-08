# Wakapi Self-Host + Cloudflare Tunnel (cert-based, no API token)

Self-hosted WakaTime-compatible backend (github.com/muety/wakapi), deployed
on the idle Oracle ARM VPS instead of paying wakatime.com Premium. Client
`wakatime-cli` keeps sending heartbeats to wakatime.com too (dual
`[api_urls]`, see [15-wakatime-setup.md](15-wakatime-setup.md)) — the paid
account becomes a free offsite backup of the self-hosted instance.

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

## Key files (on Oracle ARM, never copied to any repo)

| File | Purpose |
|------|---------|
| `~/.cloudflared/cert.pem` | Zone-scoped auth cert from `tunnel login` |
| `~/.cloudflared/<tunnel-id>.json` | Tunnel credentials |
| `~/.cloudflared/config.yml` | Ingress rules (maps `wakapi.maxhaider.dev` → local Wakapi container port) — *not written yet, next step* |

## Reusable for future self-hosted services

This method isn't Wakapi-specific — any future self-hosted tool on either
VPS should default to `cloudflared tunnel login` + `route dns` over opening
ports + Caddy/nginx + Let's Encrypt, unless there's a specific reason a
Cloudflare-fronted tunnel doesn't fit (e.g. non-HTTP protocols Cloudflare
Tunnel can't proxy).
