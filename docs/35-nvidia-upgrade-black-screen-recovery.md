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

## Pendente: reinício seco sob carga da GPU

Problema anterior e **independente** do driver: reinício sem aviso quando a GPU é exigida (carregar o modelo
Whisper `large` pelo OBS LocalVocal em CUDA). O log do boot que terminou assim parou de repente, **sem** mensagem de
desligamento, sem `Xid`, sem kernel panic e sem OOM, ~72 s depois de `Using GPU device 0 (CUDA0)`, e foi **antes** do
upgrade (driver 580 estável). Aponta para energia/PCIe/hardware, não para o 595. A A2000 é de 70 W e se alimenta só pelo
slot. Plano: reproduzir com carga controlada monitorando `nvidia-smi dmon` e temperaturas, e habilitar `pstore` e
`rasdaemon` para o próximo reset deixar rastro. Atualize este documento com o resultado.
