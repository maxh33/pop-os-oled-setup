# Recuperar acesso SSH a uma VPS NetCup travada (sem reinstalar)

## The Problem

`ssh user@servidor` para de autenticar — `Permission denied (publickey)`
ou `Too many authentication failures` — e não existe outro caminho de
acesso (nenhuma chave local bate com o `authorized_keys` do servidor).
A tela "SSH Keys" do Server Control Panel (SCP) da NetCup **não ajuda**: o
aviso na própria UI diz que uma chave cadastrada ali só é aplicada numa
reinstalação de imagem — destrutivo, apaga o servidor inteiro.

## Root Cause (padrão comum)

A chave pública local mudou (regenerada, ou usada num `~/.ssh/config` novo
para outra máquina) e o `authorized_keys` remoto nunca foi atualizado.
"Too many authentication failures" (em vez de "permission denied") costuma
ser efeito colateral de um agente SSH (1Password, `ssh-agent` com várias
chaves carregadas) oferecendo mais tentativas do que o `MaxAuthTries` do
servidor aceita antes de sequer testar a chave certa — mascara o problema
real atrás de um erro de rate-limit.

## THE FIX — Rescue system via API SCP (REST)

Não precisa reinstalar nada. A API SCP da NetCup deixa ativar um Linux
live ("rescue system", Grml) com senha root temporária, de onde dá pra
montar o disco real do servidor e editar `authorized_keys` direto.

### 1. Autenticar (device code OAuth)

```bash
curl -X POST 'https://www.servercontrolpanel.de/realms/scp/protocol/openid-connect/auth/device' \
  -d "client_id=scp" -d 'scope=offline_access openid' | jq
```

Abre a `verification_uri_complete` retornada, loga, aceita o grant. Depois:

```bash
curl -X POST 'https://www.servercontrolpanel.de/realms/scp/protocol/openid-connect/token' \
  -d 'grant_type=urn:ietf:params:oauth:grant-type:device_code' \
  -d 'device_code=<device-code>' -d 'client_id=scp' | jq
```

`access_token` dura só **300s**. Guarda o `refresh_token` (não expira
enquanto usado a cada 30 dias) e renova quando precisar:

```bash
curl 'https://www.servercontrolpanel.de/realms/scp/protocol/openid-connect/token' \
  -d 'client_id=scp' -d "refresh_token=<refresh_token>" -d 'grant_type=refresh_token' | jq
```

Nunca commitar o `refresh_token` em lugar nenhum — trate como credencial
(salvar num scratch file fora de repositório, ou `~/.secrets`).

### 2. Achar o `serverId`

```bash
curl 'https://www.servercontrolpanel.de/scp-core/api/v1/servers?limit=10' \
  -H "Authorization: Bearer $ACCESS" | jq
```

### 3. Desligar o servidor (pré-requisito do rescue system)

```bash
curl -X PATCH "https://www.servercontrolpanel.de/scp-core/api/v1/servers/$ID" \
  -H "Authorization: Bearer $ACCESS" \
  -H "Content-Type: application/merge-patch+json" \
  -d '{"state":"OFF"}'
```

**Gotchas do PATCH:**
- `Content-Type` tem que ser `application/merge-patch+json` — com
  `application/json` puro a API rejeita com "missing or invalid
  Content-Type".
- O valor do estado é `ON` / `OFF` / `SUSPENDED` (schema `ServerState1`) —
  **não** `RUNNING` / `SHUTOFF` (esse é o enum de *leitura* do estado
  atual, schema `ServerState`, campo diferente; usar por engano dá
  "Patch request not supported").
- O response é uma task assíncrona — dá pra pollar em
  `GET /api/v1/tasks/{uuid}` até `state` virar `FINISHED`.

### 4. Ativar o rescue system

```bash
curl -X POST "https://www.servercontrolpanel.de/scp-core/api/v1/servers/$ID/rescuesystem" \
  -H "Authorization: Bearer $ACCESS" -H "Content-Type: application/json" -d '{}'
```

Servidor precisa estar `SHUTOFF` (verificar `GET /servers/{id}` →
`serverLiveInfo.state`) antes disso, senão dá
`server.rescuesystem.invalidstate`. Pollar a task, depois pegar a senha:

```bash
curl "https://www.servercontrolpanel.de/scp-core/api/v1/servers/$ID/rescuesystem" \
  -H "Authorization: Bearer $ACCESS" | jq
# { "active": true, "password": "<senha-temporaria>" }
```

### 5. Logar no rescue como root (senha, não chave)

O rescue system é outro SO — o host key muda, e o cliente SSH recusa cair
pra autenticação por senha se detectar troca de host key com
`known_hosts` antigo populado. Força:

```bash
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
    -o PubkeyAuthentication=no -o PreferredAuthentications=password \
    root@<host-ou-ip>
```

Não automatizar esse login com a senha embutida num script — ferramentas
de auto-mode/classificadores de segurança tendem a bloquear isso (login
root com senha hardcoded tem cheiro de credential stuffing). É rápido o
bastante pra rodar manualmente uma vez.

### 6. Montar o disco real e editar o `authorized_keys`

```bash
lsblk                        # confirma o device (ex: /dev/vda3)
blkid /dev/vda3               # confirma filesystem (ext4 puro? LVM? LUKS?)
mkdir -p /mnt/sysroot
mount /dev/vda3 /mnt/sysroot
echo 'ssh-ed25519 AAAA... user@host' >> /mnt/sysroot/home/<usuario>/.ssh/authorized_keys
umount /mnt/sysroot
exit
```

Se `blkid` mostrar LVM (`TYPE="LVM2_member"`) ou LUKS, os passos de mount
mudam (`vgchange -ay` / `cryptsetup luksOpen` antes) — não coberto aqui,
esse servidor era ext4 direto na partição.

### 7. Desativar rescue e religar

```bash
curl -X DELETE "https://www.servercontrolpanel.de/scp-core/api/v1/servers/$ID/rescuesystem" \
  -H "Authorization: Bearer $ACCESS"
# pollar task até FINISHED, depois:
curl -X PATCH "https://www.servercontrolpanel.de/scp-core/api/v1/servers/$ID" \
  -H "Authorization: Bearer $ACCESS" -H "Content-Type: application/merge-patch+json" \
  -d '{"state":"ON"}'
```

Boot normal até a porta 22 responder de novo levou ~3-4 minutos numa VPS
NetCup "VPS 1000 G11". Testar com `until ssh ... echo OK; do sleep 3;
done` em vez de `sleep` fixo.

## Prevention

- No `~/.ssh/config`, todo host com autenticação por chave crítica leva
  `IdentitiesOnly yes` + `IdentityFile` explícito — evita o agente
  (1Password ou outro) oferecer chaves demais e disparar "too many
  authentication failures" mesmo quando a chave certa está autorizada.
  Ver `configs/ssh/config.example`.
- Ao regenerar uma chave SSH local para um host novo, checar se essa
  mesma chave (`~/.ssh/id_ed25519`) já era usada por outro host no
  `~/.ssh/config` — regenerar sem avisar quebra todo mundo que dependia
  do par antigo.

## Reference

Caso real documentado em
`joiasmax-ecommerce/doc/ambiente/acesso-ssh-vps-producao-netcup.md`
(2026-08-23) — inclui os valores reais de `serverId`, downtime medido
(~4min) e o contexto de por que precisou desse fix.
