# OpenVPN Setup (Personal VPS)

Connect to a personal VPS via OpenVPN, managed through NetworkManager. All traffic is routed through the VPN tunnel.

## Prerequisites

```bash
sudo apt install openvpn network-manager-openvpn network-manager-openvpn-gnome
```

## How It Works

- OpenVPN client connects to a personal VPS running OpenVPN server
- Keys and certificates are generated on the VPS, then copied to this machine
- NetworkManager manages the connection (GUI toggle or `nmcli`)
- Full tunnel mode — all traffic (including DNS) goes through the VPN

## Certificate Structure

All certificates are stored with restricted permissions:

```
~/.cert/nm-openvpn/              # chmod 700
├── <client>-ca.pem              # CA certificate (issued by VPS)
├── <client>-cert.pem            # Client certificate
├── <client>-key.pem             # Client private key (chmod 600)
└── <client>-tls-auth.pem        # TLS authentication key
```

The original `.ovpn` file (used for import) is at `~/<client-name>.ovpn`.

## Configuration Template

A sanitized template is at: `configs/openvpn/client.ovpn.template`

Key settings:
- **Protocol:** UDP on port 1194
- **Device:** `tun` (tunnel interface)
- **Auth:** TLS with client certificate + TLS-auth key (key-direction 1)
- **Routing:** `redirect-gateway def1` — full tunnel, all traffic through VPN
- **Validation:** `remote-cert-tls server` — verifies server certificate

## Setup on Fresh Install

### 1. Install packages

```bash
sudo apt install openvpn network-manager-openvpn network-manager-openvpn-gnome
```

### 2. Generate keys on VPS

SSH into your VPS and generate a new client certificate:

```bash
# On the VPS (example using easy-rsa)
cd /etc/openvpn/easy-rsa/
./easyrsa gen-req <client-name> nopass
./easyrsa sign-req client <client-name>
```

Export the `.ovpn` file with embedded certificates (your VPS setup may vary).

### 3. Copy .ovpn file to this machine

```bash
scp user@your-vps-ip:~/<client-name>.ovpn ~/
```

### 4. Import into NetworkManager

**Via GUI:**
1. Open **Settings > Network > VPN**
2. Click **+** to add a VPN
3. Select **Import from file...**
4. Choose `~/<client-name>.ovpn`
5. Connection is created automatically with all certs extracted to `~/.cert/nm-openvpn/`

**Via CLI:**

```bash
nmcli connection import type openvpn file ~/<client-name>.ovpn
```

### 5. Verify the connection

```bash
# Connect
nmcli connection up <client-name>

# Check status
nmcli connection show --active | grep vpn

# Verify IP changed
curl ifconfig.me

# Disconnect
nmcli connection down <client-name>
```

## Daily Usage

```bash
# Connect
nmcli connection up <connection-name>

# Disconnect
nmcli connection down <connection-name>

# Check if connected
nmcli connection show --active | grep vpn

# Show connection details
nmcli connection show <connection-name>
```

Or use the **COSMIC/GNOME network indicator** in the system tray to toggle VPN on/off.

## Certificate Renewal

Client certificate validity is ~10 years. When renewal is needed:

1. Generate new client cert on VPS
2. Export new `.ovpn` file
3. Delete old connection: `nmcli connection delete <connection-name>`
4. Import new `.ovpn` file (step 4 above)

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Connection fails after fresh install | Ensure all 3 packages are installed (including `-gnome`) |
| "No VPN secrets" error | Re-import the `.ovpn` file — certs may not have extracted properly |
| Connected but no internet | Check `redirect-gateway def1` is in config, restart NetworkManager: `sudo systemctl restart NetworkManager` |
| DNS leaks | Verify DNS is routed through VPN: `resolvectl status` |
| Connection drops frequently | Check VPS server logs; may need `keepalive 10 120` on server side |
