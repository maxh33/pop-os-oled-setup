# Tela preta após `apt full-upgrade`: driver NVIDIA 595 com bibliotecas 580 (23/11/2026)

Registro do incidente e do conserto, para não repetir o erro. Máquina: Pop!_OS 24.04 com COSMIC, kernel `7.2.15`,
uma RTX A2000 12 GB (as outras GPUs não estavam instaladas na hora).

## Sintoma

Depois de `apt upgrade` + `apt full-upgrade` e um reboot, o boot passa pelo menu e pelo kernel e fica numa tela
preta com um `_` piscando. `Ctrl+Alt+F3` mostra o login por um instante e volta para o `_`.

## O que o log mostrou

- O boot **terminava normal** (`graphical.target` alcançado). Quem quebrava era o `cosmic-greeter`, reiniciando em
  loop (`restart counter` passou de 40): `greeter exited without creating a session`.
- `nvidia-smi` falhava com `Failed to initialize NVML: Driver/library version mismatch`.
- `cat /proc/driver/nvidia/version` mostrava o **módulo do kernel 595.104.02**, enquanto as bibliotecas de usuário
  (`libnvidia-ml.so.580.178.04`) eram **580.178.04**.

## Causa

O `apt full-upgrade` instalou `nvidia-dkms-595` (módulo novo) e **removeu** `nvidia-driver-580-open` e
`nvidia-kernel-common-580`, sem trazer as bibliotecas 595 (`libnvidia-gl-595` etc.). O módulo e a userland ficaram em
séries diferentes e o greeter, que usa a GPU, morria. Os dois módulos compilaram bem (`dkms status` mostrava
`installed` para os kernels `7.1.5` e `7.2.15`); o defeito era o conjunto de pacotes inconsistente.

## O que não funcionou (para não repetir)

Voltar para o 580 **não é mais limpo**: no repositório da Pop, o metapacote `nvidia-driver-580-open` passou a ter o
595 como dependência. Rodar `apt install nvidia-driver-580-open` seguido de `apt purge` dos pacotes 595 removeu também
os pacotes 580 e deixou o sistema **sem nenhum driver NVIDIA**. Nesse estado o kernel liga a placa ao `nova-core`
(driver genérico, sem saída de vídeo): `card0` sem conectores, tela preta de novo, outra causa.
Instalar só `nvidia-utils-580` também não resolve: ele traz apenas o `nvidia-smi`, sem driver.

## Conserto que funcionou

Alinhar tudo no 595, como o repositório já espera:

```
sudo apt install nvidia-driver-595-open
sudo reboot
```

Antes de rodar, vale simular: `apt-get -s install nvidia-driver-595-open` (a simulação mostrou 21 pacotes novos e a
remoção de `nvidia-utils-580` e `libnvidia-compute-580/535`, que o 595 substitui). Depois do reboot:

```
head -2 /proc/driver/nvidia/version     # módulo 595.104.02
nvidia-smi                              # lista a placa e driver_version 595
```

## Segunda causa da tela preta: nenhum monitor detectado

A A2000 só tem saídas **DisplayPort**. Com a placa trocada, os 4 conectores ficaram `disconnected` e o
`cosmic-greeter` não sobe sem nenhum display: ele falha e entra em `start-limit-hit` (`Start request repeated too
quickly`). Depois de ligar um monitor (ou um dongle emulador de EDID) em uma saída DP, o serviço **não se recupera
sozinho**:

```
sudo systemctl reset-failed cosmic-greeter && sudo systemctl restart cosmic-greeter
```

(ou reiniciar com a tela já ligada). Conectores: `for c in /sys/class/drm/card0-*/status; do echo $c $(cat $c); done`.
Sem display, também não há captura de tela para acesso remoto gráfico; SSH continua funcionando.

## Como diagnosticar de fora (SSH)

1. `journalctl -b -u cosmic-greeter --no-pager | tail -30`: loop do greeter e o motivo.
2. `cat /proc/driver/nvidia/version` e `nvidia-smi`: versão do módulo e se a userland casa.
3. `/usr/sbin/dkms status`: módulo compilado para o kernel em uso (`dkms` fica fora do `PATH` de usuário comum).
4. `grep -E "^(Start-Date|Commandline|Install|Remove)" /var/log/apt/history.log | tail`: o que o upgrade trocou.
5. Se nada ajudar: no boot, `Espaço` abre o systemd-boot e permite escolher o kernel anterior (que também tem o
   módulo 595 compilado).

## Acesso remoto: Tailscale SSH pede reautenticação

O Tailscale SSH, na política do tailnet, pode estar com ação `check`: pede uma confirmação extra de identidade no
navegador, de tempos em tempos (`checkPeriod`). Quando vence, o `ssh` fica parado, imprime um link
(`Tailscale SSH requires an additional check`) e só entra depois de aprovado. Não é falha de rede nem de chave. Para
automações sem supervisão, aumentar o `checkPeriod` ou usar `accept` para o dispositivo de origem na política de
acesso (`login.tailscale.com/admin/acls`). Veja também [34-remote-access](34-remote-access-ssh-tailscale-rustdesk.md).

## Reinício seco sob carga de CUDA: investigação (23/11/2026, em andamento)

Problema **independente** do driver: o PC reinicia sozinho, sem aviso, quando a GPU executa CUDA. Já acontecia antes
do upgrade (driver 580, kernel 7.1.5) e, segundo o dono, também com a RTX 3070 nesta mesma placa-mãe. Máquina: ASRock
X570M Pro4 (BIOS P5.60, 19/01/2024), Ryzen 9 5900X, 4 x 32 GB de RAM (128 GB), A2000 12 GB (70 W, sem conector auxiliar).

### Sintoma exato

- Após o reset o PC volta sozinho em ~1 min. O journal do boot que caiu termina **sem** mensagem de desligamento,
  sem `Xid`, kernel panic, OOM, MCE, BERT/APEI, erro de NVMe ou AER. Não há `/dev/watchdog`.
- `Previous system reset reason [0x00080800]: software wrote 0x6 to reset control register 0xCF9` aparece em **todos**
  os boots, inclusive nos normais: **não serve para distinguir** reset por hardware de reset por software.
- O journal perde os últimos ~30 s num reset brusco. Para ver o instante, rodar um monitor que grava com `fsync` a cada
  0,5 s (`nvidia-smi --query-gpu=temperature.gpu,power.draw,clocks.sm,utilization.gpu,pcie.link.gen.current,
  clocks_throttle_reasons.active`).

### Testes e resultados (todos reproduziram, exceto CPU+RAM)

| Teste | Resultado |
|---|---|
| OBS LocalVocal, Whisper `large` em CUDA (driver 580) | caiu ~72 s depois de carregar o modelo |
| Kernel CUDA FMA curto (driver 595) | caiu em segundos |
| Rampa de carga, slot CPU x16 em **Gen4** | caiu em ~14 s (53 W, 49 °C, sem throttle) |
| Mesma rampa, slot em **Gen3** | caiu em ~32 s (52 W, 50 °C) |
| Mesma rampa, slot em **Gen2** | etapa 1 passou 45 s; etapa 2 caiu em ~17 s (69 W, 59 °C, throttle de potência) |
| A2000 no slot do **chipset** (x4, Gen4) | caiu em ~42 s (51 W, 45 °C); depois **passou a rampa inteira** (6,5 min, pico 69 W) |
| OBS + Whisper com a A2000 sem monitor (dongle) e a **RX 6400** como GPU de vídeo | caiu ~1 a 30 s depois do `Loading whisper model ... CUDA0` |
| OBS + Whisper, A2000 a 26 W / 20 % de uso | caiu ~60 s depois de carregar o modelo (**o menor consumo de todas as quedas**) |
| **CPU + RAM sem GPU**: 24 threads, 70 GB verificados, 10 min | **passou**: 0 erros de RAM, Tctl máx. 62,5 °C |

### O que ficou descartado

Versão do driver (580 e 595), kernel (7.1.5 e 7.2.15), velocidade do link (Gen2/3/4), slot (CPU e chipset), potência
(26 W já derruba), temperatura, throttle, erros PCIe/AER, RAM e carga de CPU (o teste de 10 min passou), e GPU de vídeo
(cair com a RX 6400 como principal). O gatilho comum é **a A2000 com contexto CUDA ativo por ~1 a 60 s**.

### Lições do método

- O contador `AER` e os logs do boot seguinte não guardam o crash; só o monitor com `fsync` preserva o último segundo.
- `pkill -f nome-do-script` dentro de um comando SSH mata a própria sessão (casa com a linha de comando do `ssh`): usar o PID.
- O teste de RAM em sistema (escrever padrão e verificar em várias threads) foi escrito em C com `gcc -pthread`
  porque `stress-ng` e `memtester` não estavam instalados.

### Hipóteses que restam e próximos passos

1. **BIOS**: carregar padrões (EXPO/XMP desligado, PCIe em Auto), IOMMU/Above 4G/ReBAR e o AGESA P5.60 de jan/2024.
   Com 4 pentes de 32 GB, o primeiro boot depois de mudar o BIOS pode demorar minutos com a tela preta e códigos
   alternando no display de debug (treinamento de memória): esperar 3 a 5 min antes de reiniciar à força.
2. **Teste sem CUDA/NVIDIA**: carga de compute na RX 6400 via Vulkan (por exemplo `ffmpeg` com filtros Vulkan em
   `renderD128`). Se ela também reiniciar o PC, o defeito é da plataforma (placa-mãe, slot, fonte).
3. **Teste no Windows** (dual-boot), FurMark ou OCCT por 2 a 3 min: separa Linux de hardware/BIOS.
4. **Hardware**: reencaixar 24 pinos e EPS, fonte emprestada, A2000 em outro PC, tirar 2 dos 4 pentes.
5. **Captura do último log**: `netconsole` para outra máquina e `pstore`/`ramoops`; se for o BIOS que reseta, o kernel
   não imprime nada, então a evidência só existe no boot seguinte (BERT/MCA).

Enquanto isso, a transcrição de aulas deve rodar **sem CUDA** (CPU ou outro backend) ou em outra máquina.

### Plugin do OBS some depois de trocar o driver

Ao trocar pacotes NVIDIA, o `apt` removeu o `obs-localvocal` (ele foi instalado com `--ignore-depends`, então o
`dpkg` não considera a dependência satisfeita). A configuração do OBS e os modelos ficam intactos. Reinstalar (o `.deb`
estava em `~/Downloads/obs-localvocal/`) e prender o pacote:

```bash
sudo dpkg -i --ignore-depends=libnvidia-compute-570 ~/Downloads/obs-localvocal/obs-localvocal-nvidia.deb
sudo apt-mark hold obs-localvocal
```

Atenção: como `root`, `~` aponta para `/root`. Usar o caminho completo do usuário.
