# LG Buddy: acender a TV só com Shift/Ctrl (e não com o movimento do mouse)

Estado em 24/11/2026: **fase 1 (somente log) funcionando; as fases 2 e 3 ainda não foram aplicadas.**
O LG Buddy atual continua funcionando como estava. Veja também [14-lg-buddy-setup.md](14-lg-buddy-setup.md).

## Verificação depois da troca do driver NVIDIA

O LG Buddy **não depende do driver NVIDIA**: ele fala com a TV pela rede (Wake-on-LAN e `bscpylgtv`) e usa o `swayidle`
do COSMIC. Depois da troca de driver ([35](35-nvidia-upgrade-black-screen-recovery.md)) tudo estava intacto
(`/usr/bin/LG_Buddy_*`, o venv Python e as unidades do systemd) e ele já havia desligado a TV por inatividade
(`TV is on HDMI_4. Turning TV off (screen idle)`). Um erro no primeiro segundo do login
(`Unable to connect to the compositor`) se corrige sozinho no reinício automático da unidade.

## Por que qualquer movimento do mouse acende a TV

Dois mecanismos usam o `resume` do `swayidle`, que dispara com **qualquer** evento de entrada (movimento, rolagem):

- `LG_Buddy_Screen_Monitor`: `swayidle -w timeout 300 LG_Buddy_Screen_Off resume LG_Buddy_Screen_On`.
- `tv-wake-recover.service`: `swayidle -w timeout 280 true resume tv-wake-recover.sh`, que depois de 6 s alterna a
  entrada da TV (o que também a acende). Esse script tem a saída **`DP-3` da placa 0 fixa no código** (era da A2000);
  com outra GPU a saída não existe e ele faz o "bounce" toda vez.

O `swayidle` não filtra por tipo de evento, então não dá para resolver só com configuração dele.

## Plano (auditado por um segundo modelo antes de implantar)

Acordar só com **Shift ou Ctrl pressionados em teclado físico**, ignorando mouse (movimento, rolagem e botões):

1. `swayidle` só para **desligar** (`timeout 300 ... Screen_Off`), sem `resume`.
2. Um vigia em Python (`configs/lg-buddy/bin/lg-buddy-key-wake.py`) lê `/dev/input/event*` e reage só a `EV_KEY` press
   de Shift/Ctrl; se a TV foi apagada pelo LG Buddy (arquivo de estado `/run/user/UID/lg_buddy/screen_off_by_us`
   existe), aciona `LG_Buddy_Screen_On` e depois `tv-wake-recover.sh`.
3. Desativar o `tv-wake-recover.service` baseado em `resume`.

### Por que Shift/Ctrl e não botão do mouse

Mapeado com o mouse Logitech G903 LS: dois botões laterais chegam como `BTN_SIDE` (`0x113`) e `BTN_EXTRA` (`0x114`), um
terceiro envia a tecla **Print Screen** (`0x63`) e o quarto não aparece. Na prática viram voltar/avançar no navegador e
captura de tela, e a tecla que acende a TV também chega ao aplicativo em foco (sem a tela ligada). Shift e Ctrl não
fazem nada sozinhos em nenhum aplicativo.

### Armadilhas do evdev tratadas no vigia

- Filtrar por **capacidades**, não por nome: teclado = tem as teclas A a Z e **não** tem `REL_X`/`REL_Y`. Um mouse que
  também emite teclas (macros) fica de fora.
- Descartar dispositivos **virtuais** (sem `phys`, barramento virtual): `ydotoold`, `RustDesk UInput`,
  `mouce-library-fake-mouse`, para que ditado por voz e acesso remoto nunca acendam a TV. Excluir também Yubico (digita
  teclas ao tocar), botões de energia, tampa e CEC.
- Refazer o scan a cada 30 s e ao receber `ENODEV` (dispositivo USB volta com outro nó depois do resume).
- **Não registrar qual tecla**: só o tipo (`shift` ou `ctrl`) e a hora. Ler `/dev/input` equivale a um keylogger em
  potencial; o serviço roda sem rede (`RestrictAddressFamilies=AF_UNIX`), com `NoNewPrivileges`, `ProtectSystem=strict`
  e `ProtectHome=read-only`.

### Correções da auditoria (aplicadas nas fases 2 e 3)

- Drop-in do `LG_Buddy_screen.service` precisa de `ExecStart=` **vazio** antes da linha nova (senão há dois
  `ExecStart`). Reversão limpa: `systemctl --user revert LG_Buddy_screen.service`.
- `flock` compartilhado entre `Screen_Off`, `Screen_On` e o vigia (embrulhar o comando do `swayidle` no drop-in, sem
  mexer em `/usr/bin`), para o desligar e o ligar não rodarem juntos.
- O arquivo de estado só deve ser apagado **depois** de confirmar que a TV ligou; limpar também no resume de suspensão.
- Ação em unidade `oneshot` separada, com rede e `timeout 30`; o vigia continua sem rede.
- `tv-wake-recover.sh`: esperar a saída em loop (até 20 s) e tirar o nome `DP-3` do código.

## Armadilhas do systemd de usuário encontradas

- **`PrivateNetwork=yes` quebra a saída do serviço para o journal** num `systemd --user` sem privilégio: o serviço roda,
  mas nada aparece em `journalctl --user`. Usar `RestrictAddressFamilies=AF_UNIX`.
- `StartLimitIntervalSec` pertence à seção `[Unit]`, não a `[Service]`.

## Estado dos testes (fase 1)

Com `LOG_ONLY=1`: Shift pressionado gerou `gatilho=shift tv_apagada_pelo_lgbuddy=False`; movimento do mouse, rolagem,
cliques e digitação não geraram nenhum registro. O **Ctrl** ainda precisa de uma confirmação (o intervalo mínimo de 5 s
vale para qualquer gatilho, então um Ctrl logo depois do Shift é ignorado de propósito).

## Fases 2 e 3 (instaladas em 2026-11-24, ainda sem teste com a TV)

Os scripts **ativos** são as cópias de usuário em `~/.local/bin` (não os de `/usr/bin`), com backups `*.bak-20261124-0639`.
Em `configs/lg-buddy/`: `LG_Buddy_Screen_Monitor` reescrito (só o desligar por inatividade, embrulhado em `flock`),
`LG_Buddy_Screen_On` (apaga o arquivo de estado só depois do `set_input` dar certo), `lg-buddy-wake.sh` +
`lg-buddy-wake.service` (oneshot que liga a TV e, se existir o conector da TV, roda o `tv-wake-recover.sh`) e o
`lg-buddy-key-wake.py` em modo ação (`LOG_ONLY=0`: Shift/Ctrl com o arquivo de estado presente dispara o wake).
O `tv-wake-recover.service` antigo foi desativado.

Pendente: desligar a TV com `LG_Buddy_Screen_Off`, mexer/rolar/clicar o mouse (a TV deve continuar apagada) e apertar
Shift ou Ctrl (deve ligar em ~10 s). Atenção: `lg-buddy-wake.sh` e `tv-wake-recover.sh` ainda citam o conector `DP-3`
(saída da A2000); com a RX 6400 o conector é `HDMI-A-1`.

## Reversão

```bash
systemctl --user disable --now lg-buddy-key-wake.service
rm ~/.config/systemd/user/lg-buddy-key-wake.service ~/.local/bin/lg-buddy-key-wake.py
systemctl --user daemon-reload
# se as fases 2 e 3 tiverem sido aplicadas:
systemctl --user revert LG_Buddy_screen.service && systemctl --user enable --now tv-wake-recover.service
rm -f /run/user/$UID/lg_buddy/screen_off_by_us
```
