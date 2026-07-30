# Ponytail (DietrichGebert/ponytail)

Plugin de Claude Code focado em reduzir over-engineering no código gerado por agentes de IA — filosofia YAGNI/stdlib-first. Antes de escrever código novo, o agente passa por uma escada de decisão: a necessidade é real? já existe no código? stdlib resolve? recurso nativo da plataforma resolve? já tem dependência instalada que resolve? cabe numa linha? só então escreve código novo.

Diferente de RTK (comprime output de comando) e Caveman (comprime estilo de resposta), o Ponytail atua na **qualidade/tamanho do código gerado** — é uma camada nova, não sobreposta às outras duas.

## Reinstalação nesta máquina

```bash
node --version   # dependência obrigatória — sem node no PATH, a ativação automática por sessão fica silenciosa
claude plugin marketplace add DietrichGebert/ponytail
claude plugin install ponytail@ponytail
```

Copiar `config.json` deste diretório para `~/.config/ponytail/config.json` — fixa o nível padrão `full` globalmente (mesmo padrão de persistência do `configs/caveman/`). Alternativa: variável de ambiente `PONYTAIL_DEFAULT_MODE` (prioridade sobre o config.json). Níveis disponíveis: `lite`/`full` (default de fábrica)/`ultra`/`off`.

## Validação (antes de adotar)

`/ponytail-gain` não mede nada real no seu repo — só exibe as medianas oficiais do benchmark deles (o próprio `SKILL.md` da ferramenta proíbe calcular um número por-repo). Antes de adotar, rodamos um mini-benchmark próprio: 3 dos 12 tickets oficiais documentados em `benchmarks/agentic/tasks.py` do próprio projeto, rodados via `claude -p` headless contra o fixture oficial deles (`tiangolo/full-stack-fastapi-template`@`cd83fc10`), comparando `PONYTAIL_DEFAULT_MODE=off` vs. `PONYTAIL_DEFAULT_MODE=full`, modelo Sonnet 5 (não Haiku 4.5, que é o que eles usam no benchmark oficial).

**Resultado (n=1 por combinação — escala smoke-test, não estatisticamente robusta):**

| Ticket | Baseline → Ponytail | Nota |
|---|---|---|
| Add a date picker component | 210 → 15 linhas, 3 deps novas → 0 | Baseline instalou `react-day-picker`+Radix; Ponytail usou `<input type="date">` nativo |
| Add an endpoint to duplicate an item | 19 → 62 linhas | Ponytail escreveu **mais** código — adicionou 3 testes legítimos pro endpoint novo |
| Add a color picker component | 55 → 37 linhas | Baseline do Sonnet 5 já era razoavelmente enxuto; ganho menor que o -54% anunciado (esperado — modelo melhor que o do benchmark oficial deles) |

Total: -60% linhas, -36% custo, -67% tempo, -39% turnos. Nenhuma checagem de segurança/permissão foi cortada em nenhum dos 6 diffs revisados manualmente.
