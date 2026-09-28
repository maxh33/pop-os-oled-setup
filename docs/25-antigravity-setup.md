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
