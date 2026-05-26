# mpv-setup

Personal configuration for [mpv](https://mpv.io/) (vanilla shinchiro build)
on Windows, featuring [ModernZ](https://github.com/Samillion/ModernZ) as OSC,
quality shaders, dynamic HDR/resolution profiles, and a small script to
delete the file currently playing.

Everything installs by double-clicking a `.bat`.

---

## Table of contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Uninstall / rollback](#uninstall--rollback)
- [Repository layout](#repository-layout)
- [mpv configuration (`mpv.conf`)](#mpv-configuration-mpvconf)
- [ModernZ OSC (`script-opts/modernz.conf`)](#modernz-osc-script-optsmodernzconf)
- [Shaders](#shaders)
- [Dynamic profiles](#dynamic-profiles)
- [yt-dlp / YouTube](#yt-dlp--youtube)
- [Keyboard shortcuts](#keyboard-shortcuts)
- [Custom Lua scripts](#custom-lua-scripts)
- [Credits](#credits)

---

## Requirements

- Windows 10/11.
- **Vanilla mpv** installed. The shinchiro build is recommended
  (ships with the standard `mpv-install.bat`).
  Typical location: `C:\Program Files\MPV Player\` or `C:\Program Files\mpv\`.
- PowerShell 5.1 (shipped with Windows).
- For YouTube downloads from the OSC: `yt-dlp` + `ffmpeg` in `PATH`
  or next to `mpv.exe`.

> Target setup: mid-range GPU (GTX 1660 / RX 6600 and up), HDR display,
> local playback + YouTube/Twitch streaming.

---

## Installation

1. Clone or download this repository.
2. **Double-click `Install-ModernZ.bat`**.
   - The `.bat` runs `Install-ModernZ.ps1` with `-ExecutionPolicy Bypass`
     to avoid the usual PowerShell policy friction.
3. Confirm the destination (default: `%APPDATA%\mpv`).
4. At the end the script offers to run `mpv-install.bat` (shinchiro's
   installer) with UAC elevation to register Windows file associations.
   Accept if you want mpv to become the default player.

What the installer does:
- copies `mpv.conf`, `input.conf`, `scripts/`, `script-opts/`, `shaders/`, `fonts/`;
- backs up any existing file into `<dest>/_backup-YYYYMMDD-HHMMSS/`;
- cleans up old orphan files (`modernx.lua`, `modernx-osc-icon.ttf`, …);
- offers to register Windows file associations (UAC).

> If you prefer, you can still run the `.ps1` directly:
> right-click > Run with PowerShell, or
> `powershell -ExecutionPolicy Bypass -File .\Install-ModernZ.ps1`.

---

## Uninstall / rollback

- **Restore the previous config**: the `_backup-YYYYMMDD-HHMMSS` folder
  created under `%APPDATA%\mpv` contains every file that was overwritten.
- **Remove Windows file associations**: run
  `C:\Program Files\MPV Player\installer\mpv-uninstall.bat` as admin.
- **Full removal**: delete `%APPDATA%\mpv` (also wipes `watch-later`
  history).

---

## Repository layout

```
mpv-setup/
├── Install-ModernZ.bat         # double-click launcher (Windows)
├── Install-ModernZ.ps1         # PowerShell installer
├── mpv.conf                    # main mpv config
├── input.conf                  # custom key bindings (on top of defaults)
├── fonts/
│   └── modernz-icons.ttf       # icon font used by ModernZ
├── script-opts/
│   └── modernz.conf            # ModernZ OSC options
├── scripts/
│   ├── modernz.lua             # the ModernZ OSC
│   └── delete_current.lua      # delete the file currently playing
└── shaders/
    ├── CAS.glsl                # AMD Contrast Adaptive Sharpening
    ├── KrigBilateral.glsl      # chroma upscaling
    └── SSimDownscaler.glsl     # downscaling 4K -> 1080p/1440p
```

---

## mpv configuration (`mpv.conf`)

Highlights.

### Video pipeline
- `profile=high-quality` + `vo=gpu-next`: modern backend, ewa_lanczossharp, basic deband.
- `hwdec=auto-safe`: safe hardware decoding, saves CPU.
- `dither-depth=auto` + `temporal-dither=yes`: anti-banding on 8-bit displays.
- `video-sync=display-resample` + `interpolation=yes` + `tscale=oversample`: smooth playback, judder gone.

### HDR
- `target-colorspace-hint=yes`: HDR passthrough to the display (via gpu-next).
- `tone-mapping=bt.2446a`: modern algorithm to map UHD HDR to SDR when needed.
- `hdr-compute-peak=yes`: per-scene dynamic adjustment.

### Deband (anti-banding for streaming)
- `deband=yes`, `deband-iterations=4`, `deband-threshold=48`, `deband-grain=24`.
- Especially useful on low-bitrate YouTube/Twitch.

### Audio / subtitles
- Track priority: `fr`, `fre`, `fra`, `en`, `eng`.
- `volume-max=150`, `audio-pitch-correction=yes`.
- Subtitles: Noto Sans 42px, black border 2.5, light shadow, `sub-ass-override=force`.

### Screenshots
- High bit-depth PNG into `~~desktop/`, template `name-HH.MM.SS-#N`.

### Network cache
- `cache-secs=120`, `demuxer-max-bytes=400MiB`.

---

## ModernZ OSC (`script-opts/modernz.conf`)

mpv's built-in OSC is disabled (`osc=no` in `mpv.conf`) and replaced by
ModernZ. Custom bits:

- **Language**: `language=fr`, layout `modern`, `fluent` mixed icons.
- **Accent color**: warm orange `#FF8232` (alternative palettes commented
  in the file: Material Blue, Violet, Emerald Green, Netflix Red).
- **Enabled buttons**: subtitles, audio tracks, jump ±10 s / ±60 s,
  chapter prev/next, logarithmic volume, playlist, **yt-dlp download**,
  screenshot, ontop, loop, speed, info, fullscreen.
- **Behavior**: OSC reveals on bottom-zone hover (deadzone 0.5), stays
  visible on pause, thumbnails via thumbfast.

---

## Shaders

Three shaders stacked by default (cheap, big visual win):

| Shader | Role |
|---|---|
| `KrigBilateral.glsl` | chroma upscaling — nearly free, noticeably sharper |
| `SSimDownscaler.glsl` | downscale 4K → 1440p/1080p, cleaner than default |
| `CAS.glsl` | AMD Contrast Adaptive Sharpening, light sharpen |

Wired up via `glsl-shaders` / `glsl-shaders-append` in `mpv.conf`.

---

## Dynamic profiles

Three profiles auto-activate based on content:

| Profile | Condition | Effect |
|---|---|---|
| `hdr-display` | source bt.2020 / PQ / HLG | tone-mapping=auto, target-peak=auto |
| `high-res` | height ≥ 1440 px | deband-iterations reduced to 2 (preserves fine detail) |
| `low-res` | height < 720 px (DVD, old YouTube) | deband-iterations=4, threshold=64 |

All use `profile-restore=copy` (clean fall-back to defaults).

---

## yt-dlp / YouTube

Format defined in `mpv.conf`:

```
ytdl-format=bv*[vcodec~='^(av01)'][height<=2160]+ba/
            bv*[vcodec~='^(vp9)'][height<=2160]+ba/
            bv*[height<=2160]+ba/best
```

Priority **AV1 → VP9 → rest**, capped at 2160p, best audio track.
Auto subtitles in French + English.

ModernZ's "download" button saves into `~~desktop/mpv/`.

---

## Keyboard shortcuts

mpv's default bindings stay active (Space pause, `f` fullscreen, `m`
mute, arrow seek, etc. — see the
[official docs](https://mpv.io/manual/master/#keyboard-control)).

### Custom additions (`input.conf`)

| Key | Action |
|---|---|
| `DEL` | Send the current file to the recycle bin (recoverable) |
| `Shift+DEL` | Permanently delete the current file (no undo) |

### Useful ModernZ / mpv defaults (reminder)

| Key | Action |
|---|---|
| `Space` / `p` | Pause |
| `f` | Fullscreen |
| `m` | Mute |
| `←` / `→` | Seek ±5 s |
| `↑` / `↓` | Seek ±60 s |
| `[` / `]` | Speed ÷/× 1.1 |
| `BS` | Speed 1× |
| `s` | Screenshot (with subs) |
| `S` | Screenshot (no subs) |
| `Ctrl+s` | Raw screenshot (no rendering) |
| `q` / `Q` | Quit (Q keeps position) |
| `j` / `J` | Cycle subtitles |
| `#` | Cycle audio |
| `o` / `O` | Toggle OSD |

---

## Custom Lua scripts

### `delete_current.lua`
Deletes the file currently playing.
- `recycle` mode: Windows recycle bin (recoverable).
- `permanent` mode: permanent deletion.
- Refuses remote streams (`http://`, etc.).
- Bindings in `input.conf` (`DEL` / `Shift+DEL`).

---

## Credits

- [mpv](https://mpv.io/) — the player.
- [shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake)
  — vanilla Windows builds.
- [ModernZ](https://github.com/Samillion/ModernZ) — modern OSC (ModernX fork).
- [thumbfast](https://github.com/po5/thumbfast) — fast thumbnails
  (auto-integrates with ModernZ if installed).
- Shaders: `KrigBilateral` (igv), `SSimDownscaler` (igv),
  `CAS` (AMD, mpv port).
