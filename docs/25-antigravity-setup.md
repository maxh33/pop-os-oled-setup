# Antigravity (AGY) CLI Setup & Architecture

Guia de instalação, estrutura de configuração e integração de regras para o **Google Antigravity (AGY)** no Pop!_OS 24.04 / Linux.

---

## 1. Visão Geral

O **Google Antigravity (`agy`)** é uma plataforma e CLI de desenvolvimento com agentes autônomos e pair programming baseada nos modelos Gemini (como Gemini 3.8 Flash e Gemini 3.8 Pro).

- **Binário CLI:** `~/.local/bin/agy`
- **Diretório de Dados & Logs:** `~/.gemini/antigravity-cli/`
- **Configurações Globais Compartilhadas:** `~/.gemini/config/`
- **Configuração de Execução do CLI:** `~/.gemini/antigravity-cli/settings.json`

---

## 2. Estrutura de Diretórios e Escopos

O Antigravity opera com uma hierarquia estrita de descoberta (do diretório local até a raiz global):

```
~/.gemini/
├── antigravity-cli/
│   ├── settings.json          # Configuração de permissões, modelo, tema e workspaces confiáveis
│   ├── history.jsonl          # Histórico de sessões
│   └── brain/                 # Sessões ativas, transcrições e artefatos
└── config/                    # Configurações globais compartilhadas da máquina
    ├── GEMINI.md              # Regras globais aplicadas em TODOS os projetos
    ├── AGENTS.md              # Symlink ou espelho de GEMINI.md
    ├── mcp_config.json        # Servidores Model Context Protocol (MCP) globais
    ├── hooks.json             # Lifecycle hooks globais
    ├── skills/                # Skills globais (ex: ~/.gemini/config/skills/<nome>/SKILL.md)
    └── plugins/               # Bundles de plugins instalados
```

Nos repositórios locais (projetos):
```
meu-projeto/
├── GEMINI.md                  # Regras locais do projeto (carregadas na raiz)
├── .agents/                   # Customizações do projeto versionadas no git
│   ├── rules/                 # Regras modulares (ex: antigravity-rtk-rules.md)
│   ├── skills/                # Procedimentos operacionais sob demanda
│   │   └── <nome>/
│   │       └── SKILL.md
│   ├── hooks.json             # Lifecycle hooks locais do projeto
│   └── mcp_config.json        # MCP servers específicos do projeto
```

---

## 3. Limites de Regras e Orçamento de Tokens

> [!IMPORTANT]
> **Teto por Arquivo de Regra**: No AGY, cada arquivo de regra (`GEMINI.md` ou `.agents/rules/*.md`) tem um limite rígido de **24 KB (24.000 bytes)**.
> Qualquer conteúdo que exceda 24 KB é truncado silenciosamente pelo agente.
>
> **Orçamento Agregado**: Todas as regras ativas compartilham um orçamento global de **20.000 tokens**. Arquivos que excedem o orçamento são rebaixados para ponteiros sob demanda.

### Estratégia de Modularização:
Para repositórios grandes com instruções extensas:
1. Manter o `GEMINI.md` na raiz conciso (< 20 KB) contendo:
   - Visão geral, stack e arquitetura de containers.
   - Comandos essenciais de deploy, testes, logs e emergência.
   - Pointers para regras especializadas.
2. Dividir regras especializadas em arquivos dedicados sob `.agents/rules/*.md`.

---

## 4. Otimização de Tokens com RTK (Rust Token Killer)

O RTK possui integração nativa oficial com o Antigravity.

### Configuração no Projeto:
```bash
# Dentro do repositório
rtk init --agent antigravity
```

Isso gera automaticamente `.agents/rules/antigravity-rtk-rules.md`, instruindo o AGY a priorizar comandos prefixados com `rtk` (`rtk git status`, `rtk docker ps`, etc.), gerando economia de 60-90% de tokens de contexto.

---

## 5. Skills no Antigravity

Diferente do Claude Code (que usava `.claude/skills/` e arquivos separados `.claude/agents/*.md`), o Antigravity unifica a especificação de skills diretamente em `.agents/skills/<nome>/SKILL.md`:

- **Geração de Slash Commands**: Toda pasta `.agents/skills/<nome>/SKILL.md` disponibiliza imediatamente um comando slash `/<nome>` no chat.
- **Progressive Disclosure**: Apenas o nome e descrição do frontmatter YAML entram no contexto inicial; as instruções completas só são lidas se a skill for ativada pelo modelo ou pelo usuário.

### Exemplo de SKILL.md:
```markdown
---
name: site-health-check
description: >-
  Checa status HTTP em massa de uma lista de URLs do ambiente local ou produção.
  Use para checar 404s ou após deploy.
---

# Procedimento
1. Escreva URLs em /tmp/urls.txt
2. Execute local-dev/check-urls.sh http://localhost:8080 /tmp/urls.txt
3. Reporte a tabela de status.
```

---

## 6. Governança, Commits e Segurança

O AGY herda as mesmas regras inegociáveis do ambiente:

1. **Variáveis de Ambiente Primeiro**: Nenhuma credencial hardcoded. Armazenamento em `~/.secrets` (chmod 600) ou `.env` gitignorado.
2. **Auditoria de Commits**:
   - `gemini-git-helper.sh` antes de commitar.
   - Pre-commit e pre-push hooks ativos em `~/bin/git-hooks/`.
3. **Formatação de Commit**:
   - **Conventional Commits estrito**: `feat:`, `fix:`, `chore:`, `docs:`, etc.
   - **PROIBIDO adicionar `Co-Authored-By` trailers**.
   - **NENHUMA menção de atribuição de IA** nos commits.
4. **Delegação Pesada ao Codex**:
   - Bulk edits e builds extensas roteados para o Codex CLI (`codex`).

---

## 7. Arquivos de Referência e Backup

Cópias das configurações estão armazenadas neste repositório em:
- `configs/antigravity/GEMINI.md`: Espelho das instruções globais em `~/.gemini/config/GEMINI.md`.
- `configs/antigravity/settings.json`: Espelho de `~/.gemini/antigravity-cli/settings.json`.
- `configs/antigravity/mcp_config.json`: Espelho de `~/.gemini/config/mcp_config.json`.

---

## 8. Controle de Navegador Web com Browser-Use & Chrome DevTools (CDP)

O AGY suporta controle nativo e visual de navegadores Chromium em paridade total com o recurso "Claude in Chrome" do Claude Code, utilizando a biblioteca e CLI **`browser-use`** acoplados ao Chrome real do host via Chrome DevTools Protocol (CDP).

### 8.1. Instalação e Requisitos

1. **Instalação do CLI**:
   ```bash
   uv tool install browser-use
   ```
   Disponibiliza os binários `browser-use`, `bu` e `browser` no PATH.

2. **Modelo de Visão e Raciocínio**:
   O `browser-use` utiliza o Gemini nativamente consumindo a variável `GEMINI_API_KEY`:
   ```python
   from browser_use import ChatGoogle
   llm = ChatGoogle(model="gemini-2.5-flash")
   ```

### 8.2. Arquitetura da Ponte WSL2 ↔ Windows Host

Em ambientes de desenvolvimento onde o agente roda dentro do WSL2 (Ubuntu) e o Google Chrome roda no Windows:

1. **Rede Espelhada Obrigatória (`networkingMode=mirrored`)**:
   No Windows em `C:\Users\<user>\.wslconfig`:
   ```ini
   [wsl2]
   memory=8GB
   processors=4
   swap=4GB
   networkingMode=mirrored
   ```
   *Por que:* Sem o modo espelhado, o WSL2 opera sob uma rede NAT virtual e o Windows Firewall bloqueia conexões de entrada na porta de depuração (9222). Com `networkingMode=mirrored`, Windows e WSL compartilham o mesmo `localhost` (`127.0.0.1`) com latência zero e sem intermediários.
   *Aplicação:* Rodar `wsl --shutdown` no PowerShell e reabrir o terminal.

2. **Symlink do Perfil do Chrome**:
   Para que o daemon do `browser-use` localize o arquivo `DevToolsActivePort` automaticamente no Linux:
   ```bash
   ln -sfn "/mnt/c/Users/<user>/AppData/Local/Google/Chrome/User Data" ~/.config/google-chrome
   ```

3. **Ativação da Depuração Remota no Chrome**:
   - **Opção 1**: No Chrome já aberto, acesse `chrome://inspect/#remote-debugging` e clique em *"Allow remote debugging"*.
   - **Opção 2**: Iniciar o Chrome diretamente com a porta e o perfil desejado:
     ```cmd
     "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --profile-directory="Profile 5"
     ```

### 8.3. Gotchas Críticos Observados em Produção

1. **Chrome M128+ e WebSocket Puro (404 em `/json/version`)**:
   Nas versões recentes do Chrome, os endpoints HTTP REST tradicionais (como `/json/version` e `/json/list`) retornam 404 por segurança. A conexão deve ser feita diretamente via WebSocket lendo a rota única do arquivo `DevToolsActivePort`:
   `ws://127.0.0.1:9222/devtools/browser/<uuid>`
2. **Caixa de Diálogo "Allow remote debugging?"**:
   Ao iniciar o primeiro handshake CDP externo, o Chrome exibe um diálogo de segurança na interface do Windows solicitando aprovação do usuário. É necessário clicar em *"Allow"* uma única vez para destravar o handshake.
3. **Eventos Sintéticos vs Cliques Reais em Popups/LTI**:
   Eventos `element.click()` disparados via DOM injection frequentemente são bloqueados pelo popup blocker nativo do Chrome ao tentar abrir modais autenticados ou ferramentas LTI (ex: DreamShaper, Blackboard).
   *Solução:* Disparar eventos reais de compositor via coordenadas calculadas:
   ```python
   # No browser-use CLI / CDP:
   click_at_xy(x, y)
   ```
4. **Comportamento de Sessão de Portais Acadêmicos/SSO (LMS / LTI 1.3)**:
   - Portais acadêmicos (como o da Cruzeiro do Sul) operam sob arquitetura SPA com tokens JWT/OAuth temporários que expiram com inatividade.
   - Ferramentas externas acopladas (como DreamShaper via Blackboard) utilizam *one-time launch tokens* gerados via LTI. Se a sessão expirar ou o token cair, o refresh direto na aba externa falha (redireciona para tela de login). A retomada exige refazer o lançamento a partir do botão no Blackboard, que gera um token novo e abre uma aba autenticada automaticamente.

### 8.4. Exemplos Práticos de Uso

**Via CLI Interativo (`browser-use`)**:
```bash
browser-use <<'PY'
goto_url("https://joiasmax.com.br")
wait_for_load()
print(page_info())
PY
```

**Via Agente Autônomo com Visão (`Agent`)**:
```python
import asyncio
from pathlib import Path
from browser_use import Agent, Browser, ChatGoogle

async def main():
    lines = (Path.home() / ".config/google-chrome/DevToolsActivePort").read_text().splitlines()
    ws_url = f"ws://127.0.0.1:{lines[0].strip()}{lines[1].strip()}"

    browser = Browser(cdp_url=ws_url, is_local=True)
    llm = ChatGoogle(model="gemini-2.5-flash")

    agent = Agent(
        task="Acesse o site, encontre o produto e adicione ao carrinho.",
        llm=llm,
        browser=browser,
        use_vision=True,
    )
    await agent.run()

asyncio.run(main())
```

---

## 9. Model Context Protocol (MCP) no Antigravity

O Antigravity suporta o padrão **Model Context Protocol (MCP)** para estender suas ferramentas nativas com servidores locais (stdio) ou remotos (http/SSE).

### 9.1. Comandos de Gerenciamento CLI (`agy mcp`)

```bash
# Listar todos os servidores configurados
agy mcp list

# Adicionar um servidor MCP via stdio
agy mcp add <nome> <comando> [argumentos...]

# Adicionar com variáveis de ambiente
agy mcp add --env KEY=value <nome> <comando> [argumentos...]

# Habilitar / Desabilitar temporariamente
agy mcp disable <nome>
agy mcp enable <nome>

# Remover um servidor
agy mcp remove <nome>
```

### 9.2. Servidores Configurados no Ambiente

As configurações globais ficam salvas em `~/.gemini/config/mcp_config.json` (com backup neste repositório em `configs/antigravity/mcp_config.json`).

| Servidor MCP | Pacote / Comando | Finalidade Principal |
| :--- | :--- | :--- |
| **`context7`** | `npx -y @upstash/context7-mcp` | Documentações oficiais de APIs e frameworks em tempo real, sem alucinações. |
| **`github`** | `npx -y @modelcontextprotocol/server-github` | Consulta e gerenciamento de repositórios, PRs, issues e branches via GitHub API. |
| **`playwright`** | `npx -y @playwright/mcp` | Automação e testes de navegador via seletores CSS/DOM e snapshots estruturados. |
| **`claude-in-chrome`** | `claude --claude-in-chrome-mcp` | Bridge nativa com a extensão do Brave/Chrome. Permite ao AGY controlar abas da janela ativa sem abrir perfis virgens. |

### 9.3. Segurança & Gestão de Segredos no MCP

Em conformidade com a regra de segurança do ambiente (**zero credenciais hardcoded**):
- O servidor `github` consome `${GITHUB_PERSONAL_ACCESS_TOKEN}`.
- O token é exportado dinamicamente no `~/.bashrc` via GitHub CLI:
  ```bash
  if command -v gh &> /dev/null; then
      export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token 2>/dev/null)"
      export GITHUB_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN"
  fi
  ```
  Isso garante que nenhum token fique exposto em arquivos de configuração ou versionado no Git.

### 9.4. Comparativo com o Setup do Claude Code

- **`gemini` MCP**: Usado no Claude Code para economizar contexto do Sonnet delegando código longo. **Desnecessário no AGY**, pois o próprio AGY é executado diretamente sobre modelos Gemini 3.8 com janela nativa de 1 milhão de tokens.
- **`desktop-commander`**: Usado no Claude Desktop para contornar restrições de sandbox. **Redundante no AGY**, que já dispõe de terminal Bash completo (`run_command`), PTY interativo e controle de processos de fundo (`manage_task`).

---

## 10. Bootstrap em Novas Máquinas (Linux & Windows)

Se você estiver configurando uma nova máquina do zero com uma instalação nova do `agy`, basta clonar este repositório e executar o script de automação correspondente ao seu sistema operacional:

### 10.1. Linux / WSL2 / Pop!_OS
```bash
git clone https://github.com/maxh33/pop-os-oled-setup.git
cd pop-os-oled-setup
./scripts/bootstrap-antigravity.sh
```

O script realiza:
1. Criação dos diretórios `~/.gemini/antigravity-cli` e `~/.gemini/config`.
2. Cópia do `settings.json`, `GEMINI.md`, `mcp_config.json` e symlink `AGENTS.md`.
3. Injeção de export dinâmico de `GITHUB_PERSONAL_ACCESS_TOKEN` via `gh` no `~/.bashrc`.
4. Symlink de compatibilidade `~/.config/google-chrome` -> `BraveSoftware/Brave-Browser` para automações agênticas.
5. Instalação / verificação de `browser-use` via `uv`.

### 10.2. Windows (PowerShell)
```powershell
git clone https://github.com/maxh33/pop-os-oled-setup.git
cd pop-os-oled-setup
.\scripts\bootstrap-antigravity.ps1
```

O script realiza a criação das pastas equivalentes em `$env:USERPROFILE\.gemini`, copia as configurações centrais e valida as dependências do ambiente Windows.

---

## 11. Automação com o Navegador Real (Evitando Sessões Virgens e Perda de Extensões)

### 11.1. O Diagnóstico: Por que perfis clonados (`/tmp`) quebram a experiência
Quando uma ferramenta agêntica clona uma pasta de perfil (`~/.config/BraveSoftware/Brave-Browser/Profile X`) para `/tmp` para iniciar uma instância com `--remote-debugging-port`:
1. **Quebra de Integridade de Extensões**: O Chromium calcula assinaturas HMAC no arquivo `Secure Preferences` atreladas ao caminho absoluto original do perfil. Ao rodar em `/tmp`, a validação falha e o navegador desabilita silenciosamente extensões de terceiros (1Password, Dark Reader, adblockers).
2. **Isolamento de Processo & Desconexão de Blobs**: A instância secundária roda em um processo de SO separado (`PID` diferente). Abas em tempo real, blobs gerados em memória (ex: `blob:https://web.whatsapp.com/...`) e sockets de sessão autenticada não são compartilhados com o navegador de uso diário.

### 11.2. Abordagem 1: Bridge Nativa de Extensão via MCP (`claude-in-chrome`)
Adicionado ao `~/.gemini/config/mcp_config.json` e ao repositório:
```json
"claude-in-chrome": {
  "command": "claude",
  "args": ["--claude-in-chrome-mcp"],
  "disabled": false
}
```
- **Como opera**: O servidor stdio do MCP conecta diretamente ao Native Messaging Host (`~/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.anthropic.claude_code_browser_extension.json`), comunicando-se com a extensão instalada no Brave principal (`PID` ativo).
- **Vantagens**:
  - Controla diretamente a janela ativa do usuário (`tabs_context_mcp`).
  - Todas as extensões (1Password, Dark Reader) continuam 100% ativas e renderizadas.
  - Todas as sessões, cookies e logins existentes são reutilizados na hora sem abrir janelas extras.
  - Zero dependência de cotas de IA externas usando ferramentas locais de DOM/JS (`javascript_tool`, `get_page_text`, `navigate`, `tabs_create_mcp`, `tabs_close_mcp`).

### 11.3. Abordagem 2: Navegador Diário com `--remote-debugging-port=9222` Nativo
Para permitir que ferramentas agênticas baseadas em CDP (Playwright, browser-use, scripts Python) controlem o navegador sem criar instâncias paralelas:
1. Copie o lançador desktop do sistema para o diretório de usuário:
   ```bash
   cp /usr/share/applications/brave-browser.desktop ~/.local/share/applications/brave-browser.desktop
   ```
2. Adicione a flag `--remote-debugging-port=9222` nas linhas `Exec`:
   ```ini
   Exec=/usr/bin/brave-browser-stable --remote-debugging-port=9222 %U
   ```
3. Ao iniciar o Brave diariamente pelo dock/menu do Pop!_OS, o navegador real sempre escutará na porta `9222`. Qualquer ferramenta pode se acoplar a ele via `http://localhost:9222` de forma transparente.

### 11.4. Interoperabilidade Cruzada: AGY Controlando o Claude in Chrome

Graças à padronização do protocolo aberto **Model Context Protocol (MCP)**, o Antigravity (`agy`) é capaz de consumir servidores de ferramentas concebidos por qualquer ecossistema:

```
┌─────────────────────────────────────────────────────────────┐
│                 Antigravity CLI (agy)                       │
│             Modelo: Gemini 3.8 (1M tokens)                  │
└──────────────────────────┬──────────────────────────────────┘
                           │ Protocolo MCP (stdio JSON-RPC)
┌──────────────────────────▼──────────────────────────────────┐
│              claude --claude-in-chrome-mcp                  │
└──────────────────────────┬──────────────────────────────────┘
                           │ Native Messaging Host (stdio)
┌──────────────────────────▼──────────────────────────────────┐
│   Extensão do Brave/Chrome (Claude in Chrome / ID fcoe...)   │
│             Janela Real do Usuário (PID Ativo)              │
│       • Todas as Extensões Ativas (1Password, Dark Reader)   │
│       • Todos os Logins Preservados (WhatsApp, SSO, Contas) │
└─────────────────────────────────────────────────────────────┘
```

#### Vantagens Estratégicas:
1. **Reaproveitamento de Infraestrutura Pronta**: Você não precisa reinstalar extensões ou reautenticar nenhuma sessão. O AGY herda instantaneamente toda a bridge que já estava configurada para o Claude Code.
2. **Independência de Cotas da Anthropic**: O raciocínio agêntico, planejamento de passos e geração de seletores são feitos pelos modelos Gemini do AGY. Usando as ferramentas de manipulação direta (`javascript_tool`, `get_page_text`, `navigate`, `computer`), o AGY não consome limites de tokens semanais da Anthropic.
3. **Preferência de Navegação Padronizada**: O AGY tem como regra de ouro operar na sessão do navegador apontada pelo usuário, eliminando a fricção de reautenticações diárias.



