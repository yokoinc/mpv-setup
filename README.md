# mpv-setup

Personal configuration for [mpv](https://mpv.io/) (vanilla shinchiro build)
on Windows, featuring [ModernZ](https://github.com/Samillion/ModernZ) as OSC,
quality shaders, dynamic HDR/resolution profiles, and a small script to
delete the file currently playing.

Everything installs by double-clicking a `.bat`.

---

## Quick start (new machine)

Order matters — this repo ships **config only, not mpv itself**:

1. **Install mpv first.** Grab the latest Windows build from
   [shinchiro releases](https://github.com/shinchiro/mpv-winbuild-cmake/releases)
   and install it (default: `C:\Program Files\MPV Player\`). Newer is
   better — this config uses recent options (`gpu-next`,
   `autocreate-playlist`), so an up-to-date mpv is required.
2. **Get this repo.** `git clone https://github.com/yokoinc/mpv-setup`
   or download the ZIP and extract it.
3. **Double-click `Install-ModernZ.bat`** and confirm the default
   destination (`%APPDATA%\mpv`).
4. **Set mpv as default player** for `.mkv` / `.avi` — Windows only lets
   *you* do this by hand: right-click a video → *Open with* → *Choose
   another app* → **mpv** → tick *Always*. (An installer/script cannot
   set the default; see [File associations](#file-associations).)

That's it. Open a video, you should see the ModernZ bar in French.

---

## Table of contents

- [Quick start (new machine)](#quick-start-new-machine)
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
- [File associations](#file-associations)
- [Custom Lua scripts](#custom-lua-scripts)
- [Updating ModernZ](#updating-modernz)
- [Credits](#credits)

---

## Requirements

- Windows 10/11.
- **mpv installed first** — this repo is config only, it does not contain
  `mpv.exe`. Install a **recent** vanilla build (the shinchiro build is
  recommended; it ships the standard `mpv-install.bat`).
  Typical location: `C:\Program Files\MPV Player\` or `C:\Program Files\mpv\`.
- The build must read `%APPDATA%\mpv` (normal install). For a **portable**
  build (config next to `mpv.exe`), pick the installer's `[c]` custom-path
  option and point it at that `portable_config` folder.
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

> **⚠️ Run the installer yourself — never through the Claude desktop app.**
> Claude's writes to `%APPDATA%` are silently redirected into its MSIX
> sandbox (`AppData\Local\Packages\Claude_*\LocalCache\Roaming`), so the
> real `%APPDATA%\mpv` stays untouched while everything *looks* installed.
> This bit us on 2026-07-02: mpv ran with an empty config for weeks.

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
│   ├── modernz.conf            # ModernZ OSC options
│   └── modernz-locale.json     # ModernZ translations (French UI)
├── scripts/
│   ├── modernz.lua             # the ModernZ OSC
│   └── delete_current.lua      # delete the file currently playing
└── shaders/
    ├── FSRCNNX_x2_16-0-4-1.glsl # neural luma upscaling (heavy, best quality)
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
  visible on pause. Seekbar thumbnails need the optional
  [thumbfast](https://github.com/po5/thumbfast) script — **not bundled**;
  drop `thumbfast.lua` into `scripts/` to enable them.

---

## Shaders

Shader chain, applied in order (luma → chroma → downscale → sharpen):

| Shader | Role |
|---|---|
| `FSRCNNX_x2_16-0-4-1.glsl` | **neural luma upscaling** — big win on sub-1080p → large screen. Heavy, but a mid/high GPU (GTX 1660+, RTX 30xx) eats it. |
| `KrigBilateral.glsl` | chroma upscaling — nearly free, noticeably sharper |
| `SSimDownscaler.glsl` | downscale 4K → 1440p/1080p, cleaner than default |
| `CAS.glsl` | AMD Contrast Adaptive Sharpening, light sharpen |

Wired up via `glsl-shaders` / `glsl-shaders-append` in `mpv.conf`.

> **FSRCNNX runs on every source** (it's an unconditional 2× luma
> prescaler). That's ideal when upscaling; on native-4K content it's
> wasted GPU work but harmless on a capable card. On a weak GPU, drop this
> line from `mpv.conf` and keep the other three.

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
| `S` | Screenshot (no subs, source frame) |
| `Ctrl+s` | Screenshot of the window as displayed |
| `q` / `Q` | Quit (Q keeps position) |
| `j` / `J` | Cycle subtitles |
| `#` | Cycle audio |
| `o` / `O` | Toggle OSD |

---

## File associations

Making mpv open when you double-click a `.mkv`, `.mp4`, `.avi`, … has
**two distinct layers** on Windows — this trips everyone up:

1. **Registering mpv as an available handler.** This is what
   `mpv-install.bat` (shinchiro) does, and the installer offers to run it.
   It adds mpv to the *Open with* list and the *Default apps* panel.
2. **Choosing mpv as the default** for each extension. Since Windows 8
   this is locked behind a per-user hash in
   `HKCU\...\FileExts\<ext>\UserChoice`. **No script or installer can set
   it** — Windows deliberately reserves it for a human click. `mpv-install.bat`
   itself just opens the *Default apps* panel and tells you to finish there.

So after installing, set the default **by hand**, once per extension:

> Right-click a video → **Open with** → **Choose another app** → **mpv**
> → tick **Always use this app**.

(`.mp4` may already point to mpv via the `mpv.file` ProgID from some
builds; `.mkv`/`.avi` usually default to the Windows Store player until
you change them.)

---

## Custom Lua scripts

### `delete_current.lua`
Deletes the file currently playing.
- `recycle` mode: Windows recycle bin (recoverable).
- `permanent` mode: permanent deletion.
- Refuses remote streams (`http://`, etc.).
- Bindings in `input.conf` (`DEL` / `Shift+DEL`).

---

## Updating ModernZ

Bundled version: **ModernZ v0.3.3**. Only `scripts/modernz.lua` is tied to
the ModernZ release; the icon font and the locale file rarely change.

To refresh to the latest upstream:

1. Download the current script into this repo:
   ```powershell
   iwr https://raw.githubusercontent.com/Samillion/ModernZ/main/modernz.lua `
       -OutFile scripts\modernz.lua
   ```
2. (Optional) refresh the translations too:
   ```powershell
   iwr https://raw.githubusercontent.com/Samillion/ModernZ/main/extras/locale/modernz-locale.json `
       -OutFile script-opts\modernz-locale.json
   ```
3. Sanity check — every option you set in `script-opts/modernz.conf`
   should still be recognised by the new script (an unknown option just
   logs a warning and is ignored). Run mpv once from a terminal and watch
   for `[modernz]` messages.
4. Re-run `Install-ModernZ.bat` on each machine to deploy (it backs up the
   old version first).

> `language=fr` in `modernz.conf` only works because
> `script-opts/modernz-locale.json` is present — ModernZ ships **no**
> translations of its own. Keep that file alongside the script.

---

## Credits

- [mpv](https://mpv.io/) — the player.
- [shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake)
  — vanilla Windows builds.
- [ModernZ](https://github.com/Samillion/ModernZ) v0.3.3 — modern OSC (ModernX fork).
- [thumbfast](https://github.com/po5/thumbfast) — fast thumbnails
  (auto-integrates with ModernZ if installed).
- Shaders: [`FSRCNNX`](https://github.com/igv/FSRCNN-TensorFlow) (igv),
  `KrigBilateral` (igv), `SSimDownscaler` (igv), `CAS` (AMD, mpv port).
