# Certificado Digital A1 (ICP-Brasil) no Brave/Chromium

Setup para usar certificado digital A1 brasileiro em navegadores Chromium (Brave, Chrome,
Chromium) no Linux para autenticação em portais gov (GOV.BR, e-CAC, NFe, etc.).

## A1 vs A3

| Tipo | Armazenamento | Este guia |
|------|---------------|-----------|
| A1 | Arquivo `.pfx` / `.p12` (software) | ✅ Cobre |
| A3 | Token USB ou cartão inteligente | ❌ Requer `opensc` + `pcscd` |

## Arquivos do Certificado

| Arquivo | Formato | Conteúdo |
|---------|---------|----------|
| `certificado.pfx` | PKCS#12 | Certificado pessoal + chave privada |
| `Cadeia_Oficial.p7b` | PKCS#7 | Cadeia de CAs ICP-Brasil (28 certificados) |

> O erro **"Import is only supported for a single certificate"** no Brave acontece ao tentar
> importar o `.p7b` pela UI — ele contém múltiplos CAs. Use o método via terminal abaixo.

## Pré-requisitos

```bash
sudo apt install libnss3-tools   # certutil, pk12util
```

`openssl` já vem instalado no Pop!_OS.

## Instalação

### 1. Criar o banco NSS do usuário

Navegadores Chromium no Linux usam `~/.pki/nssdb/` como banco de certificados compartilhado:

```bash
mkdir -p ~/.pki/nssdb
certutil -d sql:$HOME/.pki/nssdb -N --empty-password
```

> Se o banco já existir ou retornar erro, pule para o próximo passo.

### 2. Importar o certificado pessoal (.pfx)

```bash
pk12util -d sql:$HOME/.pki/nssdb \
  -i "/caminho/para/certificado.pfx" \
  -W "SENHA_DO_PFX" -K ""
```

Saída esperada: `pk12util: PKCS12 IMPORT SUCCESSFUL`

### 3. Importar a cadeia ICP-Brasil (.p7b)

```bash
# Converter .p7b para PEM (múltiplos certificados)
openssl pkcs7 -in "/caminho/para/Cadeia_Oficial.p7b" \
  -print_certs -out /tmp/cadeia_icp.pem

# Extrair cada certificado individualmente e importar
awk '/-----BEGIN CERTIFICATE-----/{n++; f="/tmp/cert_icp_"n".pem"; in_cert=1}
     in_cert{print > f}
     /-----END CERTIFICATE-----/{close(f); in_cert=0}' /tmp/cadeia_icp.pem

for cert in /tmp/cert_icp_*.pem; do
  n=$(basename "$cert" .pem | sed 's/cert_icp_//')
  certutil -d sql:$HOME/.pki/nssdb -A -t "CT,," -n "ICP-Brasil-CA-$n" -i "$cert" 2>/dev/null
done

rm -f /tmp/cert_icp_*.pem /tmp/cadeia_icp.pem
```

> Flag `-t "CT,,"` = confiança para CAs de SSL/TLS

### 4. Reiniciar o Brave

Feche completamente e reabra o Brave.

## Verificação

```bash
# Listar certificados importados
certutil -d $HOME/.pki/nssdb -L
```

Saída esperada:

```
Certificate Nickname                     Trust Attributes
NSS Certificate DB:<nome da empresa>:... u,u,u
ICP-Brasil-CA-1                          CT,,
ICP-Brasil-CA-2                          CT,,
...
```

- `u,u,u` = certificado de usuário com chave privada
- `CT,,` = CA confiada para SSL

Verificar no Brave: `brave://settings/certificates` → aba **Your certificates**

## Login no GOV.BR

1. Acessar https://acesso.gov.br
2. Clicar em **"Entrar com certificado digital"**
3. O Brave exibe popup para selecionar o certificado
4. Selecionar o certificado da empresa e confirmar
5. Inserir a senha do certificado quando solicitado

## Troubleshooting

### SEC_ERROR_BAD_DATABASE ao rodar certutil

O banco pode ter ficado corrompido. Recriar do zero:

```bash
rm -rf ~/.pki/nssdb
mkdir -p ~/.pki/nssdb
certutil -d sql:$HOME/.pki/nssdb -N --empty-password
```

### Certificado não aparece no Brave

O Brave precisa ser reiniciado completamente (não apenas fechar a janela):

```bash
pkill -f brave
```

### GOV.BR rejeita o certificado (erro de CA)

Verificar se a cadeia foi importada:

```bash
certutil -d $HOME/.pki/nssdb -L | grep ICP-Brasil
```

Se vazio, reimportar o `.p7b` conforme o Passo 3.

### Certificado expirado

Certificados A1 têm validade de 1 ou 3 anos. Verificar a validade:

```bash
openssl pkcs12 -in certificado.pfx -nokeys -noout -passin pass:SENHA 2>/dev/null | \
  openssl x509 -noout -dates
```

## Key Files

| Arquivo | Propósito |
|---------|-----------|
| `~/.pki/nssdb/cert9.db` | Banco de certificados (SQLite) |
| `~/.pki/nssdb/key4.db` | Banco de chaves privadas |
| `~/.pki/nssdb/pkcs11.txt` | Módulos PKCS#11 registrados |
