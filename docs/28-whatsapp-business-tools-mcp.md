# 28 — WhatsApp Business Tools MCP (Meta, oficial)

MCP remoto da Meta que deixa o Claude Code configurar a WhatsApp Business Platform (Cloud API): conta WhatsApp Business, número, verificação, registro, templates e webhooks. Usado para o assistente de atendimento da JoiasMax (plano em `joiasmax-ecommerce/doc/atendimento/`).

Estado: beta, lançamento gradual (anunciado em set/2026). A Meta o descreve como voltado a desenvolvimento e testes, não a envio em volume.

Fonte oficial: https://developers.facebook.com/documentation/mcp/whatsapp-business-tools-mcp

## Instalação

```bash
# na pasta do projeto (escopo local, grava em ~/.claude.json para esse projeto)
claude mcp add --transport http whatsapp_business_tools https://mcp.facebook.com/whatsapp_business_tools
claude mcp list   # deve mostrar "Needs authentication"
```

- Transporte: Streamable HTTP. Autenticação: OAuth com a conta de desenvolvedor da Meta (Facebook Login for Business). Nada de token em arquivo.
- **Reiniciar o Claude Code** depois do `mcp add` (`/exit`, depois `claude --continue` na mesma pasta). A lista de MCPs só é lida ao iniciar a sessão.
- Autenticar: `/mcp`, escolher `whatsapp_business_tools`, login Meta, escolher no consentimento **só o negócio necessário**.
- O login precisa ser refeito a cada reinício do cliente.
- Revisar ou revogar: Facebook, Configurações, Integrações Comerciais.
- Escopos pedidos: `business_management`, `whatsapp_business_management`, `whatsapp_business_messaging`.
- Para ter em todos os projetos, usar `--scope user` no `mcp add`.

## Pré-requisitos (o MCP não cria isso)

1. Conta de desenvolvedor Meta e **app** no Meta App Dashboard com o caso de uso de mensagens do WhatsApp Business, ligado a um portfólio comercial.
2. Ser **administrador do app** e do negócio (papel MANAGE). Sem isso o MCP para antes de qualquer ferramenta.
3. **Termos da Cloud API do WhatsApp Business** aceitos por um administrador (manual). Sem isso envio e registro de número ficam bloqueados.
4. Perfil do negócio completo (o MCP aponta o link se faltar).
5. Para produção: forma de pagamento e verificação do negócio (Business Verification).

## Fluxo de um número novo

| Passo | Ferramenta | Observação |
|---|---|---|
| listar negócios | `whatsapp_biz_businesses` | sempre confirmar qual negócio usar |
| adicionar | `whatsapp_biz_add_phone_number` | |
| enviar código | `whatsapp_biz_send_verification_code` | SMS ou voz, chega no chip; quem tem o chip repassa o código |
| verificar | `whatsapp_biz_verify_phone_number` | |
| registrar | `whatsapp_biz_register_phone_number` | |
| webhook | `whatsapp_biz_subscribe_webhook`, `whatsapp_biz_configure_webhooks` | depois do registro |
| conferir | `whatsapp_biz_phone_numbers`, `whatsapp_biz_onboarding_status` | estágio de onboarding |

Também há ferramentas de templates (criar, listar, atualizar, biblioteca), `whatsapp_biz_system_user_token` e `whatsapp_biz_send_message`.

## Cuidados

- **Número dedicado.** Registrar um número já ativo no app WhatsApp ou WhatsApp Business o desconecta de lá. Confirmar que o número está livre antes. Para usar o app e a API no mesmo número existe coexistência (onboarding de quem já usa o app), que o MCP não documenta.
- Texto livre só dentro da janela de 24h; fora dela, só template aprovado (aprovação costuma levar até ~24h).
- `whatsapp_biz_send_message` pede confirmação do destinatário antes de enviar.
- Limite de requisições por usuário e por ferramenta.
- O token permanente do usuário do sistema (para o n8n) vai para `~/.secrets` ou para o `.env` do n8n, nunca para arquivo versionado.
- Não coloque o número real do cliente ou da loja em docs versionados; este arquivo não traz.

## Referência de config

`configs/claude/mcp-servers.json` tem a entrada `whatsapp_business_tools` (tipo `http`) como cópia de referência.

## Relacionado

- Plano do assistente: `joiasmax-ecommerce/doc/atendimento/README.md`
- Bots de Telegram reaproveitados para alertas: `automation-platform` (`jm_repricer_bot` e o callback handler do blog)
