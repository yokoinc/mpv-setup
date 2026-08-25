# Third-party files

This repository redistributes files from other projects. They are **not**
covered by the MIT license in `LICENSE`: each one keeps the license of its
own project. Licenses below are taken from the headers of the shipped files.

| File | Project / author | License |
|---|---|---|
| `scripts/modernz.lua` | [ModernZ](https://github.com/Samillion/ModernZ) v0.3.3 (Samillion), derived from mpv `osc.lua` via mpv-osc-modern (maoiscat) and ModernX (cyl0, dexeonify) | LGPL v2.1 |
| `script-opts/modernz-locale.json` | [ModernZ](https://github.com/Samillion/ModernZ) (translations) | LGPL v2.1 |
| `fonts/modernz-icons.ttf` | [ModernZ](https://github.com/Samillion/ModernZ) (icon font shipped with the script) | see the ModernZ project |
| `shaders/FSRCNNX_x2_16-0-4-1.glsl` | [igv](https://github.com/igv/FSRCNN-TensorFlow), (C) 2017-2021 | LGPL v3.0 or later |
| `shaders/KrigBilateral.glsl` | Shiandow | LGPL v3.0 or later |
| `shaders/SSimDownscaler.glsl` | Shiandow | LGPL v3.0 or later |
| `shaders/CAS.glsl` | Advanced Micro Devices, Inc., (C) 2017-2019, mpv port | MIT |
| `installer/mpv-install.bat` | [mpv](https://mpv.io/) Windows build (shinchiro), modified here (see the header of the file) | see the mpv project (GPL v2 or later) |
| `installer/mpv-icon.ico` | mpv project logo | see the mpv project |

The full license texts are linked from the headers of the files themselves:

- LGPL v2.1: https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
- LGPL v3.0: https://www.gnu.org/licenses/lgpl-3.0.html
- MIT (CAS): reproduced in full at the top of `shaders/CAS.glsl`

`installer/mpv-install.bat` is the only upstream file modified here; the
changes are listed in its header. Everything else is shipped verbatim.

mpv itself is **not** redistributed by this repository - the installer only
downloads it through `winget` or asks you to install it yourself.
