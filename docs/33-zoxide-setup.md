# zoxide - cd inteligente

Aprende as pastas visitadas e pula para elas com pedaços do nome.

## Instalação

```bash
sudo apt install zoxide fzf
```

Adicionar ao `~/.bashrc` (ver `configs/shell/bashrc-zoxide`), **antes** do `ble-attach`:

```bash
eval "$(zoxide init bash)"
```

Depois: `exec bash`.

## Uso

```bash
z cruzeiro sul   # pasta mais frequente que casa com todas as palavras
zi cruzeiro      # lista interativa (fzf)
zoxide query -ls # ver o que foi aprendido
```

- Só conhece pastas visitadas depois da instalação (primeira vez: caminho completo).
- Match é por substring, não corrige typo; para isso use `zi` ou `shopt -s cdspell dirspell`.

## Armadilha com ble.sh

O `~/.bashrc` carrega `ble.sh --noattach` e chama `ble-attach` no fim. O init do zoxide
precisa vir **antes** do `ble-attach` (junto de bash-preexec e wakatime). Colocado no fim
do arquivo (depois do attach), `z` respondia "no match found" porque o hook de prompt
nunca gravava. Use `exec bash` em vez de `source ~/.bashrc` para recarregar.
