# Sem imagem na RX 6400: HDMI sem EDID, 640x480 e `video=` (2026-11-24)

Com a A2000 fora (investigação do reinício sob CUDA, ver doc 35), a RX 6400 ficou como única placa e o Pop ficou
sem tela. Registro do que foi visto e do que resolveu.

## Sintoma

- Sem imagem; `cosmic-greeter` em `failed` (já ocorre sem monitor).
- `/sys/class/drm/card0-HDMI-A-1/status` e `DP-1`: `disconnected`, `edid` com 0 byte.
- A TV (LG B3) obedecia aos comandos (`set_input HDMI_2` → `HDMI_4`, `returnValue: True`) e **informava sinal na entrada**
  (`get_inputs`: `hdmiPlugIn: True`, `hdmiSignalExist: True`). Ou seja, cabo e porta estavam certos e a placa não
  lia a identificação da TV (EDID/HPD).
- Um reinício por queda de energia não mudou nada.

## Equívoco comum

`HDMI-A-1` é o nome que o kernel dá à **primeira saída HDMI da placa**; não tem relação com a "HDMI 1" da TV.

## O que funcionou

1. Forçar o conector (temporário, root): `echo on | sudo tee /sys/class/drm/card0-HDMI-A-1/status` e
   `sudo systemctl restart cosmic-greeter`. A imagem voltou, mas só em **640x480**: sem EDID o kernel só conhece o
   modo de segurança, e `cosmic-randr mode ... 3840 2160` devolve `ModeNotFound` (a UI só lista modos conhecidos).
2. Parâmetro de kernel permanente: `sudo kernelstub -a "video=HDMI-A-1:3840x2160@60e"`. O `e` força o conector ligado e
   cria o modo 4K. Após reiniciar, `HDMI-A-1` voltou `connected` e o modo atual passou a **3840x2160 @ 120 Hz**.
   Reverter: `sudo kernelstub -d "video=HDMI-A-1:3840x2160@60e"`.

## Observações

- O `@60` do parâmetro não limitou o resultado: a lista de modos veio do EDID lido após o reinício.
- Antes eu havia afirmado, de memória, que a HDMI da RX 6400 ficaria em 4K60 por falta de HDMI 2.1 (FRL) no `amdgpu`.
  O teste mostrou 4K 120 Hz; tratar aquela afirmação como não confirmada.
- Sobraram nos parâmetros de boot `nvidia-drm.modeset=1` e `nvidia-modeset.hdmi_deepcolor=0` (sem efeito sem a NVIDIA).
- Sem `sudo` sem senha, o ajuste exige `ssh -t` (a senha é pedida no terminal do usuário).
- Scripts do LG Buddy com `DP-3` precisam trocar para `HDMI-A-1` enquanto a A2000 estiver fora (doc 36).

## Lição

Sem monitor detectado, o problema pode ser a leitura do EDID e não o cabo: conferir `get_inputs` da TV
(`hdmiSignalExist`) antes de trocar hardware, e forçar o conector por `status`/`video=` como contorno.
