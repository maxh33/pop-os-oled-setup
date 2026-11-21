# Acesso remoto sem supervisão (SSH + Tailscale + RustDesk)

Objetivo: deixar o desktop acessível enquanto o dono viaja. SSH via Tailscale é o plano que não depende de
sessão gráfica; RustDesk é o acesso visual.

## Diagnóstico (21/11/2026)

- Sessão COSMIC é **Wayland** (não existe sessão X11; sem GDM, o DM é `cosmic-greeter`, então
  `WaylandEnable=false` em `/etc/gdm3/custom.conf` não se aplica).
- RustDesk 1.5.0, serviço `enabled`. No Wayland ele pede a captura de tela ao `xdg-desktop-portal`, que mostra
  um diálogo local. Sem clique, o conector recebe "A solicitação de compartilhamento de tela no dispositivo
  remoto foi encerrada sem ser concluída". Com o monitor OLED desconectado e só o dongle HDMI (EDID emulado)
  ligado, o diálogo aparece numa tela que ninguém vê.
- O `RustDesk2.toml` apontava para o servidor público `rs-ny.rustdesk.com`, não para o servidor self-hosted.
- `openssh-server` e Tailscale não estavam instalados.

## SSH

```bash
sudo apt install -y openssh-server && sudo systemctl enable --now ssh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo '<CHAVE_PUBLICA_DO_CLIENTE>' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
```

Teste a chave a partir do cliente. Só então aplique `configs/ssh/50-hardening.conf`:

```bash
sudo cp configs/ssh/50-hardening.conf /etc/ssh/sshd_config.d/ && sudo sshd -t && sudo systemctl reload ssh
```

`ufw` estava inativo. Se ativar: `sudo ufw allow from 192.168.0.0/24 to any port 22` (nunca expor a 22 na internet).

## Tailscale (acesso fora da LAN)

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh     # abre uma URL de login; autorizar no navegador
tailscale ip -4
```

O cliente (ex.: WSL do notebook) precisa do Tailscale na mesma conta. Entrada de `~/.ssh/config`: ver `Host popos`
em `configs/ssh/config.example`.

## Energia e tela

COSMIC guarda em `~/.config/cosmic/com.system76.CosmicIdle/v1/` (cópias em
`configs/cosmic/com.system76.CosmicIdle/v1/`): `screen_off_time` e `suspend_on_ac_time` em `None`. A tela
apagada atrapalha a captura no Wayland. Trava extra contra suspensão:

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

## Pendente

- Aplicar o `50-hardening.conf` depois do teste de chave pelo Tailscale.
- Login automático (Configurações > Usuários), para quedas de energia (sem nobreak).
- RustDesk: definir servidor/key do self-hosted, confirmar senha permanente, decidir 2FA (regenerar o secret) e
  testar se o portal Wayland guarda a permissão. Se não guardar, a saída é uma sessão Xorg.
- Fixar o IP da LAN no roteador (reserva por MAC).
