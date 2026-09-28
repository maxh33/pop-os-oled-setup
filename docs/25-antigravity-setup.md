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
