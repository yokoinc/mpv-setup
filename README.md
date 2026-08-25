# mpv-setup

Personal [mpv](https://mpv.io/) configuration (vanilla shinchiro build) for
Windows, with [ModernZ](https://github.com/Samillion/ModernZ) as the OSC,
quality shaders, dynamic HDR/resolution profiles, and a small script to
delete the file currently being played.

Everything installs by double-clicking a `.bat`.

---

## Quick start (new machine)

This repo ships **the config only, not mpv itself** - but the installer can
now take care of mpv too:

1. **Get this repo.** `git clone https://github.com/yokoinc/mpv-setup`
   or download the ZIP and extract it.
2. **Double-click `Install-ModernZ.bat`.** It looks for `mpv.exe` first;
   if it is missing, it offers to install the
   [shinchiro build](https://github.com/shinchiro/mpv-winbuild-cmake)
   with `winget install shinchiro.mpv` (accept the UAC prompt). Then
   confirm where the config goes (`%APPDATA%\mpv`).
3. **Set mpv as the default player** for `.mkv` / `.avi` - Windows only
   lets *you* do that by hand: right-click a video, *Open with*,
   *Choose another app*, **mpv**, tick *Always*. (No installer or script
   can set the default; see [File associations](#file-associations).)

If `winget` is not available, install mpv by hand from the
[shinchiro releases](https://github.com/shinchiro/mpv-winbuild-cmake/releases)
(default location: `C:\Program Files\MPV Player\`) and run the `.bat` again.
A **recent** build is required - this config uses `gpu-next` and
`autocreate-playlist`.

> **Note:** if a `portable_config` folder sits next to `mpv.exe`, mpv
> ignores `%APPDATA%\mpv` entirely. The installer warns you and lets you
> target that folder instead with option `[c]`.

That is all. Open a video and you should see the ModernZ bar.

> **This is a personal config.** A few settings follow my own habits and
> are tagged `PERSONAL PREFERENCE` in `mpv.conf`: the audio and subtitle
> track priority (`alang` / `slang`, French first) and the yt-dlp
> auto-subtitle languages (`fr,en`). Search for that tag and reorder them
> to your own languages. The OSC language is set in
> `script-opts/modernz.conf` (`language=en`, 11 translations available).

---

## Contents

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
- [License](#license)

---

## Requirements

- Windows 10/11.
- **mpv** - this repo only contains config, not `mpv.exe`. The installer
  detects it and, if missing, installs the **recent** shinchiro build with
  `winget` (package `shinchiro.mpv`). Installing it yourself beforehand
  works just as well.
  Typical location: `C:\Program Files\MPV Player\` or `C:\Program Files\mpv\`.
- **winget** (App Installer, preinstalled on Windows 11) - only needed if
  you want the installer to fetch mpv for you.
- The build must read `%APPDATA%\mpv` (normal install). For a **portable**
  build (config next to `mpv.exe`), pick option `[c]` in the installer and
  point it at that `portable_config` folder.
- PowerShell 5.1 (ships with Windows).
- For YouTube downloads from the OSC: `yt-dlp` + `ffmpeg` in `PATH` or next
  to `mpv.exe`.

> Target setup: HDR display, local playback + YouTube/Twitch streaming.
> The base config runs on a mid-range GPU (GTX 1660 / RX 6600 and up). The
> **FSRCNNX** upscaler enabled by default is heavier - recommended from an
> **RTX 30xx / equivalent** upwards; on a lighter card, drop that shader
> (see [Shaders](#shaders)).

---

## Installation

1. Clone or download this repo.
2. **Double-click `Install-ModernZ.bat`**.
   - The `.bat` runs `Install-ModernZ.ps1` with `-ExecutionPolicy Bypass`
     to avoid the usual PowerShell policy friction.
3. Confirm the destination (default: `%APPDATA%\mpv`).
4. At the end, the script offers to run `mpv-install.bat` (shinchiro's
   installer) with UAC elevation to register the Windows file
   associations. Accept it if you want mpv to become the default player.

What the installer does:
- copies `mpv.conf`, `input.conf`, `scripts/`, `script-opts/`, `shaders/`, `fonts/`;
- backs up any existing file into `<dest>/_backup-YYYYMMDD-HHMMSS/`;
- removes old leftover files (`modernx.lua`, `modernx-osc-icon.ttf`, ...);
- offers to register the Windows file associations (UAC).

> You can always run the `.ps1` directly instead: right-click > Run with
> PowerShell, or
> `powershell -ExecutionPolicy Bypass -File .\Install-ModernZ.ps1`.

> **Run the installer yourself - never through the Claude desktop app.**
> Claude's writes to `%APPDATA%` are silently redirected into its MSIX
> sandbox (`AppData\Local\Packages\Claude_*\LocalCache\Roaming`): the real
> `%APPDATA%\mpv` stays untouched while everything *looks* installed.
> That happened here on 2026-07-02: mpv ran with an empty config for weeks.

---

## Uninstall / rollback

- **Restore the previous config**: the `_backup-YYYYMMDD-HHMMSS` folder
  created in `%APPDATA%\mpv` holds every file that was overwritten.
- **Remove the Windows file associations**: run
  `C:\Program Files\MPV Player\installer\mpv-uninstall.bat` as administrator.
- **Full removal**: delete `%APPDATA%\mpv` (this also wipes the
  `watch-later` history).

---

## Repository layout

```
mpv-setup/
+-- Install-ModernZ.bat         # double-click launcher (Windows)
+-- Install-ModernZ.ps1         # PowerShell installer
+-- installer/
|   +-- mpv-install.bat         # extended copy of shinchiro's association .bat
|   +-- mpv-icon.ico            # icon for the registered file types
+-- mpv.conf                    # main mpv config
+-- input.conf                  # custom key bindings (on top of the defaults)
+-- fonts/
|   +-- modernz-icons.ttf       # icon font used by ModernZ
+-- script-opts/
|   +-- modernz.conf            # ModernZ OSC options
|   +-- modernz-locale.json     # ModernZ translations (11 languages)
+-- scripts/
|   +-- modernz.lua             # the ModernZ OSC
|   +-- delete_current.lua      # deletes the file being played
+-- shaders/
    +-- FSRCNNX_x2_16-0-4-1.glsl # neural luma upscaling (heavy, best quality)
    +-- CAS.glsl                # AMD Contrast Adaptive Sharpening
    +-- KrigBilateral.glsl      # chroma upscaling
    +-- SSimDownscaler.glsl     # 4K -> 1080p/1440p downscaling
```

---

## mpv configuration (`mpv.conf`)

The highlights.

### Video pipeline
- `profile=high-quality` + `vo=gpu-next`: modern backend, ewa_lanczossharp, basic deband.
- `hwdec=auto-safe`: safe hardware decoding, saves CPU.
- `dither-depth=auto` + `temporal-dither=yes`: anti-banding on 8-bit displays.
- `video-sync=display-resample` + `interpolation=yes` + `tscale=oversample`: smooth playback, judder gone.

### HDR
- `target-colorspace-hint=yes`: HDR passthrough to the display (via gpu-next).
- `tone-mapping=bt.2446a`: modern algorithm to bring UHD HDR down to SDR when needed.
- `hdr-compute-peak=yes`: dynamic, scene-by-scene adjustment.

### Deband (anti-banding for streaming)
- `deband=yes`, `deband-iterations=4`, `deband-threshold=48`, `deband-grain=24`.
- Especially useful on low-bitrate YouTube/Twitch.

### Audio / subtitles
- Track priority: `fr`, `fre`, `fra`, `en`, `eng` - **personal preference,
  French first**; reorder `alang` / `slang` to your own languages.
- `volume-max=150`, `audio-pitch-correction=yes`.
- Subtitles: Noto Sans 42px, 2.5 black border, light shadow, `sub-ass-override=force`.

### Screenshots
- High-bit-depth PNG in `~~desktop/`, template `name-HH.MM.SS-#N`.

### Network cache
- `cache-secs=120`, `demuxer-max-bytes=400MiB`.

---

## ModernZ OSC (`script-opts/modernz.conf`)

The built-in mpv OSC is disabled (`osc=no` in `mpv.conf`) and replaced by
ModernZ. The custom settings:

- **Language**: `language=en`, `modern` layout, mixed `fluent` icons. Set
  `language=fr` (or any other key of `modernz-locale.json`) for a
  translated interface.
- **Accent color**: warm orange `#FF8232` (alternative palettes are listed
  as comments in the file: Material Blue, Purple, Emerald Green, Netflix
  Red).
- **Enabled buttons**: subtitles, audio tracks, 10s / 60s jumps, previous
  and next chapter, logarithmic volume, playlist, **yt-dlp download**,
  screenshot, ontop, loop, speed, info, fullscreen.
- **Behaviour**: the OSC appears when hovering the bottom area (deadzone
  0.5) and stays visible on pause. Seekbar thumbnails need the optional
  [thumbfast](https://github.com/po5/thumbfast) script - **not shipped
  here**; drop `thumbfast.lua` into `scripts/` to enable them.

---

## Shaders

Shader chain, applied in order (luma, chroma, downscale, sharpen):

| Shader | Role |
|---|---|
| `FSRCNNX_x2_16-0-4-1.glsl` | **neural luma upscaling** - big gain on sub-1080p content on a large screen. Heavy; recommended from an **RTX 30xx / equivalent** upwards. |
| `KrigBilateral.glsl` | chroma upscaling - nearly free, clearly sharper |
| `SSimDownscaler.glsl` | 4K to 1440p/1080p downscale, cleaner than the default |
| `CAS.glsl` | AMD Contrast Adaptive Sharpening, light sharpening |

Wired up with `glsl-shaders` / `glsl-shaders-append` in `mpv.conf`.

> **FSRCNNX applies to every source** (it is an unconditional 2x luma
> prescaler). That is ideal when upscaling; on native 4K it is wasted GPU
> time, but harmless on a capable card. On a modest GPU, remove that line
> from `mpv.conf` and keep the other three.

---

## Dynamic profiles

Three profiles switch on automatically depending on the content:

| Profile | Condition | Effect |
|---|---|---|
| `hdr-display` | bt.2020 / PQ / HLG source | tone-mapping=auto, target-peak=auto |
| `high-res` | height >= 1440 px | deband-iterations lowered to 2 (keeps fine detail) |
| `low-res` | height < 720 px (DVD, old YouTube) | deband-iterations=4, threshold=64 |

All of them use `profile-restore=copy` (clean return to the defaults).

---

## yt-dlp / YouTube

Format set in `mpv.conf`:

```
ytdl-format=bv*[vcodec~='^(av01)'][height<=2160]+ba/
            bv*[vcodec~='^(vp9)'][height<=2160]+ba/
            bv*[height<=2160]+ba/best
```

Priority is **AV1, then VP9, then anything else**, capped at 2160p, with
the best audio track. Automatic subtitles in French and English
(`sub-lang="fr,en"` - change it to your own languages).

The ModernZ download button saves to `~~desktop/mpv/`.

---

## Keyboard shortcuts

The default mpv bindings stay active (Space pause, `f` fullscreen, `m`
mute, arrows to seek, etc. - see the
[official documentation](https://mpv.io/manual/master/#keyboard-control)).

### Custom additions (`input.conf`)

| Key | Action |
|---|---|
| `DEL` | Moves the current file to the Recycle Bin (recoverable) |
| `Shift+DEL` | Deletes the current file permanently - press twice within 3 s to confirm |

### Handy ModernZ / mpv defaults (reminder)

| Key | Action |
|---|---|
| `Space` / `p` | Pause |
| `f` | Fullscreen |
| `m` | Mute |
| `Left` / `Right` | Seek 5 s back/forward |
| `Up` / `Down` | Seek 60 s forward/back |
| `[` / `]` | Speed down/up by 1.1 |
| `Backspace` | Speed back to 1x |
| `s` | Screenshot (with subtitles) |
| `S` | Screenshot (no subtitles, source image) |
| `Ctrl+s` | Screenshot of the window as displayed |
| `q` / `Q` | Quit (Q saves the position) |
| `j` / `J` | Cycle through subtitle tracks |
| `#` | Cycle through audio tracks |
| `o` / `O` | Show/hide the OSD |

---

## File associations

Getting mpv to open when you double-click a `.mkv`, `.mp4`, `.avi`, ...
relies on **two separate layers** on Windows - which is what trips
everyone up:

1. **Register mpv as an available handler.** That is what
   `mpv-install.bat` does, and the installer offers to run it (elevated).
   It adds mpv to the *Open with* list and to the *Default apps* panel.
   This repo ships an **extended copy** (`installer/mpv-install.bat`) with
   extra extensions on top of shinchiro's list: `.m4b .gif .webp .avif
   .dsf .dff .mpc .mp+ .caf .w64 .ac4`. The installer prefers that copy.
2. **Pick mpv as the default** for each extension. Since Windows 8 this is
   locked behind a per-user hash in
   `HKCU\...\FileExts\<ext>\UserChoice`. **No script or installer can set
   it** - Windows deliberately reserves it for a human click.
   `mpv-install.bat` itself just opens the *Default apps* panel and tells
   you to finish there.

So after installing, set the default **by hand**, once per extension:

> Right-click a video, **Open with**, **Choose another app**, **mpv**,
> tick **Always use this app**.

(`.mp4` may already point at mpv through the `mpv.file` ProgID of some
builds; `.mkv` and `.avi` usually stay on the Windows Store player until
you change them.)

---

## Custom Lua scripts

### `delete_current.lua`
Deletes the file currently being played.
- `recycle` mode: Windows Recycle Bin (recoverable), acts on the first press.
- `permanent` mode: permanent delete, so it asks for a second press within
  3 seconds (`CONFIRM_WINDOW` at the top of the script). Loading another
  file cancels the pending confirmation.
- Refuses remote streams (`http://`, etc.).
- Bound in `input.conf` (`DEL` / `Shift+DEL`).

---

## Updating ModernZ

Shipped version: **ModernZ v0.3.3**. Only `scripts/modernz.lua` is tied to
the ModernZ release; the icon font and the locale file rarely change.

To move to the latest upstream version:

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
3. Check: every option set in `script-opts/modernz.conf` should still be
   recognised by the new script (an unknown option only produces a warning
   and is ignored). Run mpv once from a terminal and watch the
   `[modernz]` messages.
4. Run `Install-ModernZ.bat` again on each machine to deploy (it backs up
   the old version first).

> A `language=` value other than `default` only works because
> `script-opts/modernz-locale.json` is present - ModernZ ships **no**
> translations of its own. Keep that file next to the script.

---

## Credits

- [mpv](https://mpv.io/) - the player.
- [shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake)
  - the vanilla Windows builds.
- [ModernZ](https://github.com/Samillion/ModernZ) v0.3.3 - modern OSC (a ModernX fork).
- [thumbfast](https://github.com/po5/thumbfast) - fast thumbnails
  (ModernZ picks it up automatically if installed).
- Shaders: [`FSRCNNX`](https://github.com/igv/FSRCNN-TensorFlow) (igv),
  `KrigBilateral` (Shiandow), `SSimDownscaler` (Shiandow), `CAS` (AMD, mpv port).

---

## License

The files written for this repository (installer, `mpv.conf`, `input.conf`,
`modernz.conf`, `delete_current.lua`, this README) are under the MIT license
- see [LICENSE](LICENSE).

The OSC script, its icon font and locale file, the shaders and
`installer/mpv-install.bat` come from other projects and keep their own
licenses (LGPL v2.1, LGPL v3.0, MIT, GPL) - see
[THIRD-PARTY.md](THIRD-PARTY.md). mpv itself is not redistributed here.
