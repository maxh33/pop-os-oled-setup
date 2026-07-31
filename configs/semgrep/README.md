# Semgrep (semgrep/semgrep — CLI, não confundir com Aikido/Opengrep)

SAST self-hosted, 2.800+ regras de comunidade, LGPL-2.1, sem login/ceiling quando rodado via CLI local. **Não é o mesmo produto que o SaaS da Aikido** (Aikido forkou o engine em "Opengrep" e tem seu próprio free tier limitado — 10 repo/2 container/1 domínio/10 AI fix por mês; esse limite não existe aqui, é do produto SaaS deles, não do `semgrep scan` open source).

## Instalação (via uv, sem sudo)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
uv tool install semgrep
semgrep --version
```

## Uso

```bash
semgrep scan --config=auto -j 1 .
```

`--config=auto` baixa regras do registry remoto — se pedir login/consentimento, usar rulesets públicos locais sem conta: `semgrep scan --config=p/php --config=p/security-audit --config=p/secrets -j 1 .`

`-j 1` (um core) na primeira passada de um repo novo — evita spike de memória em ambiente sem cap configurado (ver `docs/18-wsl2-vmmem-freeze.md` se WSL). Depois de validar que roda estável, pode soltar o paralelismo default.

## Status neste momento

Uso manual de auditoria — ainda não está em hook de git nem na VPS. Decisão de virar automático/hook fica pendente até o workflow manual se provar no dia a dia.
