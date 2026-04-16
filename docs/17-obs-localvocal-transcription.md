# OBS LocalVocal — Classroom Transcription Setup

## Overview

Real-time Portuguese transcription of university lectures using OBS Studio + LocalVocal plugin (Whisper-based). Saves `.srt` / `.vtt` files per class session for post-processing into study notes.

**Model in use:** Whisper Large V3 Portuguese Fsicoli (Marksdo variant, ~2.9 GB VRAM)
**GPU backend:** CUDA (flash attention enabled)
**Language:** Portuguese (`pt`)

---

## Prerequisites

- Pop!_OS 24.04 with NVIDIA drivers installed (see [HARDWARE.md](../HARDWARE.md))
- CUDA toolkit available (`nvidia-smi` working)
- OBS Studio installed (see installation section below)
- ~3 GB free disk space for model

---

## 1. Install OBS Studio

```bash
# Option A: apt (system package)
sudo apt install obs-studio

# Option B: Flatpak (more up-to-date, isolated)
flatpak install flathub com.obsproject.Studio
```

> **Recommendation:** Use the **apt version** if you need CUDA GPU acceleration in the plugin. Flatpak sandboxing can prevent CUDA library access.

---

## 2. Install obs-localvocal Plugin

The plugin is not in apt. Download the Linux release from the [locaal-ai/obs-localvocal](https://github.com/locaal-ai/obs-localvocal) GitHub releases page.

### For apt OBS install
```bash
# Extract the release archive, then:
mkdir -p ~/.config/obs-studio/plugins/obs-localvocal/bin/64bit
cp obs-localvocal.so ~/.config/obs-studio/plugins/obs-localvocal/bin/64bit/
cp -r data ~/.config/obs-studio/plugins/obs-localvocal/
```

### For Flatpak OBS install
```bash
mkdir -p ~/.var/app/com.obsproject.Studio/config/obs-studio/plugins/obs-localvocal/bin/64bit
cp obs-localvocal.so ~/.var/app/com.obsproject.Studio/config/obs-studio/plugins/obs-localvocal/bin/64bit/
cp -r data ~/.var/app/com.obsproject.Studio/config/obs-studio/plugins/obs-localvocal/
```

Restart OBS and confirm the plugin loads: **Tools → obs-localvocal** should appear in the menu.

---

## 3. Download the Portuguese Model

Models are stored at:
```
~/.config/obs-studio/plugin_config/obs-localvocal/models/
# or for Flatpak:
~/.var/app/com.obsproject.Studio/config/obs-studio/plugin_config/obs-localvocal/models/
```

Download the model via the plugin's built-in downloader:
1. Add a LocalVocal filter to any audio source
2. In the filter settings, open the **Model** dropdown
3. Select **Whisper Large V3 Portuguese Fsicoli (Marksdo)** → **Download**

Alternatively, copy the model file directly from Windows (if on the same machine via WSL):
```bash
MODEL_SRC="/mnt/c/Users/Admin/AppData/Roaming/obs-studio/plugin_config/obs-localvocal/models/ggml-large-v3-fsicoli.pt"
MODEL_DST="$HOME/.config/obs-studio/plugin_config/obs-localvocal/models/ggml-large-v3-fsicoli.pt"
mkdir -p "$MODEL_DST"
cp "$MODEL_SRC/ggml-large-v3-fsicoli.pt.bin" "$MODEL_DST/"
```

---

## 4. Audio Source Setup (PipeWire vs WASAPI)

On Windows the source is **Application Audio Capture (WASAPI)** — it captures a specific app's audio.
On Linux with PipeWire, the equivalent is capturing a **monitor sink**.

### Create a virtual sink for app audio capture
```bash
# Create a virtual sink (run once per session, or add to autostart)
pactl load-module module-null-sink sink_name=lecture_capture sink_properties=device.description="Lecture_Capture"
```

Then in your browser/video player, **route audio output to "Lecture Capture"** via PipeWire routing (e.g., `qpwgraph`, `pavucontrol`, or COSMIC audio settings).

In OBS, add an **Audio Input Capture** source pointed at `lecture_capture.monitor`.

### Alternative: monitor the whole desktop audio
In OBS → add **Audio Output Capture** → select your main output monitor source.
Simpler but captures all system audio, not app-specific.

---

## 5. Add the LocalVocal Filter

1. Right-click the audio source → **Filters**
2. Click `+` → **LocalVocal Transcription**
3. Configure with these exact settings:

### Filter Settings

| Setting | Value |
|---------|-------|
| Model | Whisper Large V3 Portuguese Fsicoli (Marksdo) |
| Language | Portuguese (`pt`) |
| Buffered output | ✅ enabled |
| Partial latency | `3000` ms |
| Buffer lines | `2` |
| Characters per line | `30` |
| Flash attention | ✅ enabled |
| No context | ✅ enabled |
| Save SRT subtitles | ✅ enabled |
| WebVTT captions | ✅ enabled (language: `pt`) |
| Caption to recording | ✅ enabled |
| Output file path | *(see path convention below)* |

### Advanced Settings

| Setting | Value |
|---------|-------|
| Temperature | `0.05` |
| Entropy threshold | `1.0` |
| Logprob threshold | `0.0` |
| No-speech threshold | `0.4` |
| Greedy best_of | `3` |
| Beam search size | `1` |
| Suppress regex | `(décadas\s*,?\s*){3,}` |
| Initial prompt | `Aula sobre assuntos relacionados ao curso de ciencia da computacao` |
| Backend device | `0` (GPU 0) |

> The **suppress regex** prevents a common hallucination where Whisper repeats "décadas" in silence gaps.
> Adjust the **initial prompt** per subject for better context (see examples below).

### Initial prompt examples by subject
```
Engenharia de Prompt:  "Aula sobre engenharia de prompt e aplicações em inteligência artificial."
Prototipagem:          "Aula sobre prototipagem de sistemas computacionais."
Generic CS:            "Aula sobre assuntos relacionados ao curso de ciencia da computacao."
```

---

## 6. Output Path Convention

Match the convention used in the `cs-cruzeiro-do-sul` repo (adjust the Linux path accordingly):

```
~/repos/cs-cruzeiro-do-sul/01-semestre/<disciplina>/aulas/<NOME-AULA-DATA>
```

Example:
```
~/repos/cs-cruzeiro-do-sul/01-semestre/prototipagem-sistemas/aulas/PROTOTIPAGEM-SABADO-11-04-8H
```

OBS will write `<path>.srt` and `<path>.vtt` files to this location during recording.

---

## 7. Subtitle Text Source

Add a **Text (FreeType 2)** source (Linux equivalent of Windows' text_gdiplus):

| Setting | Value |
|---------|-------|
| Source name | `LocalVocal Subtitles` |
| Font | Arial (or Liberation Sans), `72pt`, Regular |
| Outline | ✅ enabled, `7px`, black |
| Word wrap | ✅ enabled |
| Bounds type | Fixed size |
| Bounds width | `1500` |
| Bounds height | `230` |

In the LocalVocal filter, set **Subtitle source** → `LocalVocal Subtitles`.

---

## 8. GPU Acceleration (CUDA)

Flash attention requires the plugin to be built with **cuBLAS** support.
Check if your plugin release has CUDA enabled:

```bash
# Check if the .so links against CUDA libs
ldd ~/.config/obs-studio/plugins/obs-localvocal/bin/64bit/obs-localvocal.so | grep cuda
```

If no CUDA libs appear, download the CUDA-enabled release variant from the GitHub releases page (look for `-cuda` in the filename).

Verify GPU is active during transcription:
```bash
# While OBS is transcribing, check VRAM usage
nvidia-smi
# Should show obs or the plugin using ~3 GB VRAM
```

---

## 9. Profile and Scene Setup

Replicate the Windows profile `class_recording_transcriptions`:

1. In OBS → **Profile** → **New** → name it `class_recording_transcriptions`
2. Configure output settings to match your recording needs
3. Save the scene collection with all sources and the LocalVocal filter

---

## Troubleshooting

### Plugin doesn't appear in OBS
```bash
# Check the .so is in the right place
ls ~/.config/obs-studio/plugins/obs-localvocal/bin/64bit/

# Check OBS logs for plugin load errors
cat ~/.config/obs-studio/logs/$(ls -t ~/.config/obs-studio/logs/ | head -1) | grep -i localvocal
```

### No GPU acceleration / transcription is slow
```bash
# Verify CUDA is available to OBS
nvidia-smi
ldd ~/.config/obs-studio/plugins/obs-localvocal/bin/64bit/obs-localvocal.so | grep -E "cuda|cublas"

# If no CUDA: download the CUDA build of the plugin, not the default build
```

### Audio capture not working (no transcription output)
```bash
# List available audio sources
pactl list sources short

# Confirm your monitor source exists
pactl list sources | grep -A5 "lecture_capture"
```

### Model fails to load / OOM
- Large V3 requires ~3 GB VRAM. Check available VRAM: `nvidia-smi --query-gpu=memory.free --format=csv`
- If VRAM is tight, close other GPU-intensive apps, or fall back to `ggml-large-v3.bin` (standard, slightly less accurate for Portuguese)

### Hallucination loops ("décadas décadas décadas...")
The suppress regex `(décadas\s*,?\s*){3,}` handles this. If you see other repeated words, add them to the regex:
```
(décadas|palavra\s*){3,}
```

---

## Files

| File | Location |
|------|----------|
| Plugin binary | `~/.config/obs-studio/plugins/obs-localvocal/bin/64bit/obs-localvocal.so` |
| Plugin data | `~/.config/obs-studio/plugins/obs-localvocal/data/` |
| Models | `~/.config/obs-studio/plugin_config/obs-localvocal/models/` |
| Active model | `models/ggml-large-v3-fsicoli.pt/ggml-large-v3-fsicoli.pt.bin` (~2.9 GB) |
| Scene collection | `~/.config/obs-studio/basic/scenes/` |
| Profile | `~/.config/obs-studio/basic/profiles/class_recording_transcriptions/` |
| OBS logs | `~/.config/obs-studio/logs/` |

---

## Windows Config Reference

Original setup captured from:
- `C:\Users\Admin\AppData\Roaming\obs-studio\basic\scenes\Untitled.json`
- Profile: `class_recording_transcriptions`
- Filter UUID (Application Audio source): `f010f7c2-9f8a-4d19-b646-d2d5f8c12cbe`
