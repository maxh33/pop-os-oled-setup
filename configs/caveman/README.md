# Caveman (JuliusBrussee/caveman)

Plugin de compressão de tokens de output do Claude Code — estilo de resposta mais direto/conciso. Nível padrão fixado em `lite` (conciso profissional, não o "caveman" literal) — código/commits/PRs continuam escritos normalmente (boundary do próprio plugin).

## Reinstalação nesta máquina

```bash
claude plugin marketplace add JuliusBrussee/caveman
claude plugin install caveman@caveman
```

Copiar `config.json` deste diretório para `~/.config/caveman/config.json` — é o que fixa o nível padrão `lite` globalmente, sem precisar rodar `/caveman lite` a cada sessão.

Verificar ativação: `cat ~/.claude/.caveman-active`.
