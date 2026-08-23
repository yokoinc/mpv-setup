# mpv-setup

Configuration personnelle de [mpv](https://mpv.io/) (build vanilla shinchiro)
sous Windows, avec [ModernZ](https://github.com/Samillion/ModernZ) comme OSC,
des shaders de qualité, des profils dynamiques HDR/résolution, et un petit
script pour supprimer le fichier en cours de lecture.

Tout s'installe en double-cliquant un `.bat`.

---

## Démarrage rapide (nouvelle machine)

Ce dépôt fournit **la config uniquement, pas mpv lui-même** — mais
l'installeur s'occupe désormais aussi de mpv :

1. **Récupère ce dépôt.** `git clone https://github.com/yokoinc/mpv-setup`
   ou télécharge le ZIP et extrais-le.
2. **Double-clique `Install-ModernZ.bat`.** Il cherche d'abord `mpv.exe` ;
   s'il est absent, il propose d'installer le
   [build shinchiro](https://github.com/shinchiro/mpv-winbuild-cmake)
   via `winget install shinchiro.mpv` (accepte l'élévation UAC). Confirme
   ensuite la destination de la config (`%APPDATA%\mpv`).
3. **Définis mpv comme lecteur par défaut** pour `.mkv` / `.avi` — Windows
   ne laisse que *toi* le faire à la main : clic droit sur une vidéo →
   *Ouvrir avec* → *Choisir une autre application* → **mpv** → coche
   *Toujours*. (Aucun installeur ni script ne peut définir le défaut ;
   voir [Associations de fichiers](#associations-de-fichiers).)

Si `winget` n'est pas disponible, installe mpv à la main depuis les
[releases shinchiro](https://github.com/shinchiro/mpv-winbuild-cmake/releases)
(par défaut : `C:\Program Files\MPV Player\`) puis relance le `.bat`. Un build
**récent** est indispensable — cette config utilise `gpu-next` et
`autocreate-playlist`.

> **Note :** si un dossier `portable_config` se trouve à côté de `mpv.exe`,
> mpv ignore complètement `%APPDATA%\mpv`. L'installeur t'avertit et te
> permet de viser ce dossier à la place via l'option `[c]`.

C'est tout. Ouvre une vidéo, tu devrais voir la barre ModernZ en français.

---

## Sommaire

- [Démarrage rapide (nouvelle machine)](#démarrage-rapide-nouvelle-machine)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Désinstallation / retour arrière](#désinstallation--retour-arrière)
- [Arborescence du dépôt](#arborescence-du-dépôt)
- [Configuration mpv (`mpv.conf`)](#configuration-mpv-mpvconf)
- [OSC ModernZ (`script-opts/modernz.conf`)](#osc-modernz-script-optsmodernzconf)
- [Shaders](#shaders)
- [Profils dynamiques](#profils-dynamiques)
- [yt-dlp / YouTube](#yt-dlp--youtube)
- [Raccourcis clavier](#raccourcis-clavier)
- [Associations de fichiers](#associations-de-fichiers)
- [Scripts Lua maison](#scripts-lua-maison)
- [Mettre à jour ModernZ](#mettre-à-jour-modernz)
- [Crédits](#crédits)

---

## Prérequis

- Windows 10/11.
- **mpv** — ce dépôt ne contient que de la config, pas `mpv.exe`.
  L'installeur le détecte et, s'il manque, installe le build shinchiro
  **récent** via `winget` (paquet `shinchiro.mpv`). L'installer toi-même
  au préalable fonctionne aussi.
  Emplacement typique : `C:\Program Files\MPV Player\` ou `C:\Program Files\mpv\`.
- **winget** (App Installer, préinstallé sur Windows 11) — nécessaire
  uniquement si tu veux que l'installeur récupère mpv pour toi.
- Le build doit lire `%APPDATA%\mpv` (installation normale). Pour un build
  **portable** (config à côté de `mpv.exe`), choisis l'option `[c]` de
  l'installeur et pointe-la vers ce dossier `portable_config`.
- PowerShell 5.1 (fourni avec Windows).
- Pour les téléchargements YouTube depuis l'OSC : `yt-dlp` + `ffmpeg` dans
  le `PATH` ou à côté de `mpv.exe`.

> Configuration cible : écran HDR, lecture locale + streaming YouTube/Twitch.
> La config de base tourne sur un GPU milieu de gamme (GTX 1660 / RX 6600 et
> au-dessus). L'upscaler **FSRCNNX** activé par défaut est plus lourd —
> conseillé à partir d'une **RTX 30xx / équivalent** ; sur une carte plus
> modeste, retire ce shader (voir [Shaders](#shaders)).

---

## Installation

1. Clone ou télécharge ce dépôt.
2. **Double-clique `Install-ModernZ.bat`**.
   - Le `.bat` lance `Install-ModernZ.ps1` avec `-ExecutionPolicy Bypass`
     pour éviter les frictions habituelles avec la politique PowerShell.
3. Confirme la destination (par défaut : `%APPDATA%\mpv`).
4. À la fin, le script propose de lancer `mpv-install.bat` (l'installeur
   de shinchiro) avec élévation UAC pour enregistrer les associations de
   fichiers Windows. Accepte si tu veux que mpv devienne le lecteur par
   défaut.

Ce que fait l'installeur :
- copie `mpv.conf`, `input.conf`, `scripts/`, `script-opts/`, `shaders/`, `fonts/` ;
- sauvegarde tout fichier existant dans `<dest>/_backup-AAAAMMJJ-HHMMSS/` ;
- nettoie les vieux fichiers orphelins (`modernx.lua`, `modernx-osc-icon.ttf`, …) ;
- propose d'enregistrer les associations de fichiers Windows (UAC).

> Si tu préfères, tu peux toujours lancer le `.ps1` directement :
> clic droit > Exécuter avec PowerShell, ou
> `powershell -ExecutionPolicy Bypass -File .\Install-ModernZ.ps1`.

> **⚠️ Lance l'installeur toi-même — jamais via l'application de bureau Claude.**
> Les écritures de Claude dans `%APPDATA%` sont silencieusement redirigées
> vers son bac à sable MSIX
> (`AppData\Local\Packages\Claude_*\LocalCache\Roaming`) : le vrai
> `%APPDATA%\mpv` reste intact alors que tout *semble* installé.
> Ça nous est arrivé le 02/07/2026 : mpv a tourné avec une config vide
> pendant des semaines.

---

## Désinstallation / retour arrière

- **Restaurer la config précédente** : le dossier `_backup-AAAAMMJJ-HHMMSS`
  créé dans `%APPDATA%\mpv` contient tous les fichiers qui ont été écrasés.
- **Retirer les associations de fichiers Windows** : lance
  `C:\Program Files\MPV Player\installer\mpv-uninstall.bat` en administrateur.
- **Suppression complète** : supprime `%APPDATA%\mpv` (efface aussi
  l'historique `watch-later`).

---

## Arborescence du dépôt

```
mpv-setup/
├── Install-ModernZ.bat         # lanceur à double-cliquer (Windows)
├── Install-ModernZ.ps1         # installeur PowerShell
├── installer/
│   ├── mpv-install.bat         # copie étendue du .bat d'associations de shinchiro
│   └── mpv-icon.ico            # icône des types de fichiers enregistrés
├── mpv.conf                    # config principale de mpv
├── input.conf                  # raccourcis personnalisés (en plus des défauts)
├── fonts/
│   └── modernz-icons.ttf       # police d'icônes utilisée par ModernZ
├── script-opts/
│   ├── modernz.conf            # options de l'OSC ModernZ
│   └── modernz-locale.json     # traductions ModernZ (interface en français)
├── scripts/
│   ├── modernz.lua             # l'OSC ModernZ
│   └── delete_current.lua      # supprime le fichier en cours de lecture
└── shaders/
    ├── FSRCNNX_x2_16-0-4-1.glsl # upscaling luma neural (lourd, qualité max)
    ├── CAS.glsl                # AMD Contrast Adaptive Sharpening
    ├── KrigBilateral.glsl      # upscaling chroma
    └── SSimDownscaler.glsl     # downscaling 4K -> 1080p/1440p
```

---

## Configuration mpv (`mpv.conf`)

Les points marquants.

### Pipeline vidéo
- `profile=high-quality` + `vo=gpu-next` : backend moderne, ewa_lanczossharp, deband de base.
- `hwdec=auto-safe` : décodage matériel sûr, économise le CPU.
- `dither-depth=auto` + `temporal-dither=yes` : anti-banding sur les écrans 8 bits.
- `video-sync=display-resample` + `interpolation=yes` + `tscale=oversample` : lecture fluide, judder éliminé.

### HDR
- `target-colorspace-hint=yes` : passthrough HDR vers l'écran (via gpu-next).
- `tone-mapping=bt.2446a` : algorithme moderne pour ramener l'HDR UHD en SDR si besoin.
- `hdr-compute-peak=yes` : ajustement dynamique scène par scène.

### Deband (anti-banding pour le streaming)
- `deband=yes`, `deband-iterations=4`, `deband-threshold=48`, `deband-grain=24`.
- Particulièrement utile sur YouTube/Twitch à faible bitrate.

### Audio / sous-titres
- Priorité des pistes : `fr`, `fre`, `fra`, `en`, `eng`.
- `volume-max=150`, `audio-pitch-correction=yes`.
- Sous-titres : Noto Sans 42px, bordure noire 2.5, ombre légère, `sub-ass-override=force`.

### Captures d'écran
- PNG en haute profondeur de bits dans `~~desktop/`, modèle `nom-HH.MM.SS-#N`.

### Cache réseau
- `cache-secs=120`, `demuxer-max-bytes=400MiB`.

---

## OSC ModernZ (`script-opts/modernz.conf`)

L'OSC intégré de mpv est désactivé (`osc=no` dans `mpv.conf`) et remplacé
par ModernZ. Les réglages personnalisés :

- **Langue** : `language=fr`, layout `modern`, icônes mixtes `fluent`.
- **Couleur d'accent** : orange chaud `#FF8232` (palettes alternatives en
  commentaire dans le fichier : Material Blue, Violet, Vert Émeraude,
  Rouge Netflix).
- **Boutons activés** : sous-titres, pistes audio, saut ±10 s / ±60 s,
  chapitre précédent/suivant, volume logarithmique, playlist,
  **téléchargement yt-dlp**, capture d'écran, ontop, boucle, vitesse,
  infos, plein écran.
- **Comportement** : l'OSC apparaît au survol de la zone basse (deadzone
  0.5) et reste visible en pause. Les miniatures de la seekbar nécessitent
  le script optionnel [thumbfast](https://github.com/po5/thumbfast) —
  **non fourni** ; dépose `thumbfast.lua` dans `scripts/` pour les activer.

---

## Shaders

Chaîne de shaders, appliquée dans l'ordre (luma → chroma → downscale → sharpen) :

| Shader | Rôle |
|---|---|
| `FSRCNNX_x2_16-0-4-1.glsl` | **upscaling luma neural** — gros gain sur du sub-1080p → grand écran. Lourd ; conseillé à partir d'une **RTX 30xx / équivalent**. |
| `KrigBilateral.glsl` | upscaling chroma — quasi gratuit, nettement plus net |
| `SSimDownscaler.glsl` | downscale 4K → 1440p/1080p, plus propre que le défaut |
| `CAS.glsl` | AMD Contrast Adaptive Sharpening, accentuation légère |

Branchés via `glsl-shaders` / `glsl-shaders-append` dans `mpv.conf`.

> **FSRCNNX s'applique à toutes les sources** (c'est un prescaler luma 2×
> inconditionnel). C'est idéal en upscaling ; sur du 4K natif c'est du GPU
> gaspillé, mais sans dommage sur une carte capable. Sur un GPU modeste,
> retire cette ligne de `mpv.conf` et garde les trois autres.

---

## Profils dynamiques

Trois profils s'activent automatiquement selon le contenu :

| Profil | Condition | Effet |
|---|---|---|
| `hdr-display` | source bt.2020 / PQ / HLG | tone-mapping=auto, target-peak=auto |
| `high-res` | hauteur ≥ 1440 px | deband-iterations réduit à 2 (préserve les fins détails) |
| `low-res` | hauteur < 720 px (DVD, vieux YouTube) | deband-iterations=4, threshold=64 |

Tous utilisent `profile-restore=copy` (retour propre aux valeurs par défaut).

---

## yt-dlp / YouTube

Format défini dans `mpv.conf` :

```
ytdl-format=bv*[vcodec~='^(av01)'][height<=2160]+ba/
            bv*[vcodec~='^(vp9)'][height<=2160]+ba/
            bv*[height<=2160]+ba/best
```

Priorité **AV1 → VP9 → reste**, plafonné à 2160p, meilleure piste audio.
Sous-titres automatiques en français + anglais.

Le bouton « télécharger » de ModernZ enregistre dans `~~desktop/mpv/`.

---

## Raccourcis clavier

Les raccourcis par défaut de mpv restent actifs (Espace pause, `f` plein
écran, `m` muet, flèches pour naviguer, etc. — voir la
[documentation officielle](https://mpv.io/manual/master/#keyboard-control)).

### Ajouts personnalisés (`input.conf`)

| Touche | Action |
|---|---|
| `SUPPR` | Envoie le fichier courant à la corbeille (récupérable) |
| `Maj+SUPPR` | Supprime définitivement le fichier courant (irréversible) |

### Défauts ModernZ / mpv utiles (rappel)

| Touche | Action |
|---|---|
| `Espace` / `p` | Pause |
| `f` | Plein écran |
| `m` | Muet |
| `←` / `→` | Navigation ±5 s |
| `↑` / `↓` | Navigation ±60 s |
| `[` / `]` | Vitesse ÷/× 1.1 |
| `Retour arrière` | Vitesse 1× |
| `s` | Capture d'écran (avec sous-titres) |
| `S` | Capture d'écran (sans sous-titres, image source) |
| `Ctrl+s` | Capture de la fenêtre telle qu'affichée |
| `q` / `Q` | Quitter (Q conserve la position) |
| `j` / `J` | Faire défiler les sous-titres |
| `#` | Faire défiler les pistes audio |
| `o` / `O` | Afficher/masquer l'OSD |

---

## Associations de fichiers

Faire en sorte que mpv s'ouvre quand tu double-cliques un `.mkv`, `.mp4`,
`.avi`, … repose sur **deux couches distinctes** sous Windows — c'est ce
qui piège tout le monde :

1. **Enregistrer mpv comme gestionnaire disponible.** C'est ce que fait
   `mpv-install.bat`, et l'installeur propose de le lancer (avec élévation).
   Il ajoute mpv à la liste *Ouvrir avec* et au panneau *Applications par
   défaut*. Ce dépôt embarque une **copie étendue**
   (`installer/mpv-install.bat`) avec des extensions en plus par rapport à
   la liste de shinchiro : `.m4b .gif .webp .avif .dsf .dff .mpc .mp+ .caf
   .w64 .ac4`. L'installeur la privilégie.
2. **Choisir mpv comme défaut** pour chaque extension. Depuis Windows 8,
   c'est verrouillé derrière un hash par utilisateur dans
   `HKCU\...\FileExts\<ext>\UserChoice`. **Aucun script ni installeur ne
   peut le définir** — Windows le réserve délibérément à un clic humain.
   `mpv-install.bat` lui-même se contente d'ouvrir le panneau
   *Applications par défaut* et de te dire de finir là-bas.

Après installation, définis donc le défaut **à la main**, une fois par
extension :

> Clic droit sur une vidéo → **Ouvrir avec** → **Choisir une autre
> application** → **mpv** → coche **Toujours utiliser cette application**.

(`.mp4` pointe peut-être déjà vers mpv via le ProgID `mpv.file` de certains
builds ; `.mkv`/`.avi` restent en général sur le lecteur du Windows Store
tant que tu ne les changes pas.)

---

## Scripts Lua maison

### `delete_current.lua`
Supprime le fichier en cours de lecture.
- Mode `recycle` : corbeille Windows (récupérable).
- Mode `permanent` : suppression définitive.
- Refuse les flux distants (`http://`, etc.).
- Raccourcis dans `input.conf` (`SUPPR` / `Maj+SUPPR`).

---

## Mettre à jour ModernZ

Version fournie : **ModernZ v0.3.3**. Seul `scripts/modernz.lua` est lié à
la release ModernZ ; la police d'icônes et le fichier de locale changent
rarement.

Pour passer à la dernière version amont :

1. Télécharge le script courant dans ce dépôt :
   ```powershell
   iwr https://raw.githubusercontent.com/Samillion/ModernZ/main/modernz.lua `
       -OutFile scripts\modernz.lua
   ```
2. (Optionnel) rafraîchis aussi les traductions :
   ```powershell
   iwr https://raw.githubusercontent.com/Samillion/ModernZ/main/extras/locale/modernz-locale.json `
       -OutFile script-opts\modernz-locale.json
   ```
3. Vérification — chaque option définie dans `script-opts/modernz.conf`
   devrait toujours être reconnue par le nouveau script (une option
   inconnue génère juste un avertissement et est ignorée). Lance mpv une
   fois depuis un terminal et surveille les messages `[modernz]`.
4. Relance `Install-ModernZ.bat` sur chaque machine pour déployer (il
   sauvegarde l'ancienne version d'abord).

> `language=fr` dans `modernz.conf` ne fonctionne que parce que
> `script-opts/modernz-locale.json` est présent — ModernZ ne fournit
> **aucune** traduction en propre. Garde ce fichier à côté du script.

---

## Crédits

- [mpv](https://mpv.io/) — le lecteur.
- [shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake)
  — les builds Windows vanilla.
- [ModernZ](https://github.com/Samillion/ModernZ) v0.3.3 — OSC moderne (fork de ModernX).
- [thumbfast](https://github.com/po5/thumbfast) — miniatures rapides
  (s'intègre automatiquement à ModernZ si installé).
- Shaders : [`FSRCNNX`](https://github.com/igv/FSRCNN-TensorFlow) (igv),
  `KrigBilateral` (igv), `SSimDownscaler` (igv), `CAS` (AMD, portage mpv).
