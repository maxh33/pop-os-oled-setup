# JoiasMax — timer diário do repricer (ambiente LOCAL)

**Repositório do projeto**: `Programacao/Repositorios/joiasmax-ecommerce` (fora
deste repo — aqui só ficam as unidades systemd de referência).

## O que faz

Dispara `joiasmax-ecommerce/local-dev/repricer-daily-test.sh` todo dia às
09:00: busca a cotação real do ouro, roda o repricer (máquina de estados
retido→confirmado, threshold 8%), aplica no WooCommerce **local** (sandbox
Docker, nunca produção) e grava relatório com amostra antes/depois em
`joiasmax-ecommerce/doc/importacao/evidencia-repricer-local-<data>.md`.

Pré-requisito: os containers `docker-compose.local.yml` do projeto precisam
estar de pé (`docker compose --env-file .env.local -f docker-compose.local.yml
up -d`) antes do horário do timer — o timer não sobe os containers sozinho.

## Instalação

```bash
cp configs/systemd/joiasmax-repricer.service configs/systemd/joiasmax-repricer.timer \
  ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now joiasmax-repricer.timer
```

## Verificação

```bash
systemctl --user list-timers joiasmax-repricer.timer
systemctl --user status joiasmax-repricer.service
```

Validado em 2026-08-11: disparo autônomo às 09:00:16, sem intervenção manual,
cotação R$718,21/g, 29.831 variações reprecificadas, auditor do catálogo
1934/1935 PASS (mesma falha legada pré-existente, `b027`).

## Notas

- `Persistent=true` no timer: se a máquina estiver desligada às 09:00, roda
  assim que ligar (não perde o dia).
- Path do repo do projeto está hardcoded no `.service` — se o checkout mudar
  de lugar, editar `WorkingDirectory=`/`ExecStart=` nos dois arquivos (aqui e
  em `~/.config/systemd/user/`).
- Histórico do bug que a implementação achou (repricer atualizava `_price`
  mas não `_jm_preco_avista`/`_jm_regra_venda`) fica documentado em
  `joiasmax-ecommerce/local-dev/catalog-extractor/LICOES.md` §59 — não
  duplicado aqui.
