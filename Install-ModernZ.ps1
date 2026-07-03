# =============================================================
#  Install-ModernZ.ps1
#  Installe ModernZ + ta config polie pour mpv vanilla.
#
#  USAGE :
#   1. Clic droit sur ce fichier > "Exécuter avec PowerShell"
#      (ou ouvrir PowerShell et : .\Install-ModernZ.ps1)
#   2. Confirmer l'emplacement cible (défaut : %APPDATA%\mpv)
#
#  Le script :
#   - copie mpv.conf, input.conf, scripts, script-opts, shaders, fonts
#   - sauvegarde tout fichier existant dans _backup-YYYYMMDD-HHMMSS
#   - nettoie les vieux fichiers orphelins (modernx, etc.)
#
#  IMPORTANT : lancer ce script SOI-MEME (double-clic sur le .bat).
#  Ne PAS le faire executer par l'app Claude : ses ecritures vers
#  AppData sont detournees dans un bac a sable invisible pour mpv
#  (constate le 02/07/2026 — le vrai dossier restait vide).
# =============================================================

$ErrorActionPreference = 'Stop'
$src = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Source : $src" -ForegroundColor Cyan

# --- Choix de la destination ---
$candidates = @(
    "$env:APPDATA\mpv"     # 1) Emplacement standard mpv vanilla (shinchiro / CI build)
)

Write-Host ""
Write-Host "Choisis l'emplacement de la config mpv :" -ForegroundColor Yellow
for ($i = 0; $i -lt $candidates.Count; $i++) {
    $exists = if (Test-Path $candidates[$i]) { '[existe]' } else { '[à créer]' }
    Write-Host ("  [{0}] {1} {2}" -f ($i + 1), $candidates[$i], $exists)
}
Write-Host "  [c] Chemin personnalisé"
Write-Host ""
$choice = Read-Host "Ton choix (1 par défaut)"
if ([string]::IsNullOrWhiteSpace($choice)) { $choice = '1' }

switch ($choice) {
    '1'     { $dest = $candidates[0] }
    'c'     { $dest = Read-Host "Chemin complet" }
    default { $dest = $candidates[0] }
}

Write-Host ""
Write-Host "==> Destination : $dest" -ForegroundColor Cyan
if (-not (Test-Path $dest)) {
    Write-Host "    (création du dossier)"
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

# --- Crée les sous-dossiers ---
foreach ($sub in 'scripts', 'script-opts', 'fonts', 'shaders') {
    $p = Join-Path $dest $sub
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# --- Sauvegarde si fichiers existants ---
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $dest "_backup-$timestamp"
$toBackup = @(
    'mpv.conf',
    'input.conf',
    'scripts\modernx.lua',
    'scripts\modernz.lua',
    'scripts\delete_current.lua',
    'scripts\input.conf',
    'script-opts\modernz.conf',
    'script-opts\modernz-locale.json',
    'fonts\modernx-osc-icon.ttf'
) | Where-Object { Test-Path (Join-Path $dest $_) }

if ($toBackup.Count -gt 0) {
    Write-Host ""
    Write-Host "==> Sauvegarde des fichiers existants dans : $backup" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    foreach ($f in $toBackup) {
        $full = Join-Path $dest $f
        $rel  = $f
        $tgt  = Join-Path $backup $rel
        $tgtDir = Split-Path -Parent $tgt
        if (-not (Test-Path $tgtDir)) { New-Item -ItemType Directory -Path $tgtDir -Force | Out-Null }
        Copy-Item -Path $full -Destination $tgt -Force
        Write-Host "    sauvegardé : $rel"
    }
}

# --- Copies ---
Write-Host ""
Write-Host "==> Installation des fichiers" -ForegroundColor Green
Copy-Item -Path (Join-Path $src 'scripts\modernz.lua')        -Destination (Join-Path $dest 'scripts\modernz.lua')        -Force
Copy-Item -Path (Join-Path $src 'scripts\delete_current.lua') -Destination (Join-Path $dest 'scripts\delete_current.lua') -Force
Copy-Item -Path (Join-Path $src 'fonts\modernz-icons.ttf')    -Destination (Join-Path $dest 'fonts\modernz-icons.ttf')    -Force
Copy-Item -Path (Join-Path $src 'script-opts\modernz.conf')   -Destination (Join-Path $dest 'script-opts\modernz.conf')   -Force
Copy-Item -Path (Join-Path $src 'script-opts\modernz-locale.json') -Destination (Join-Path $dest 'script-opts\modernz-locale.json') -Force
Copy-Item -Path (Join-Path $src 'mpv.conf')                   -Destination (Join-Path $dest 'mpv.conf')                   -Force
Copy-Item -Path (Join-Path $src 'input.conf')                 -Destination (Join-Path $dest 'input.conf')                 -Force
Write-Host "    OK : modernz.lua, delete_current.lua, modernz-icons.ttf, modernz.conf, modernz-locale.json (interface FR), mpv.conf, input.conf"

# --- Shaders ---
$shaderSrc = Join-Path $src 'shaders'
if (Test-Path $shaderSrc) {
    Get-ChildItem -Path $shaderSrc -File | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination (Join-Path $dest "shaders\$($_.Name)") -Force
        Write-Host "    shader : $($_.Name)"
    }
}

# --- Nettoyage ---
Write-Host ""
Write-Host "==> Nettoyage des anciens fichiers" -ForegroundColor Green
$toRemove = @(
    'scripts\modernx.lua',
    'scripts\input.conf',
    'fonts\modernx-osc-icon.ttf'
)
foreach ($r in $toRemove) {
    $full = Join-Path $dest $r
    if (Test-Path $full) {
        Remove-Item -Path $full -Force
        Write-Host "    supprimé : $r"
    }
}

# --- Vérification : ce qui est réellement en place ---
Write-Host ""
Write-Host "==> Vérification du dossier $dest" -ForegroundColor Green
$deployed = Get-ChildItem -Path $dest -Recurse -File | Where-Object { $_.FullName -notmatch '_backup-' }
foreach ($d in $deployed) {
    Write-Host ("    {0,8} o.  {1}" -f $d.Length, $d.FullName.Substring($dest.Length + 1))
}
Write-Host ("    Total : {0} fichiers" -f $deployed.Count)

# --- Associations de fichiers (mpv-install.bat) ---
Write-Host ""
Write-Host "==> Associations de fichiers Windows" -ForegroundColor Green

$assocBat = $null
$candidatesBat = @(
    "C:\Program Files\MPV Player\installer\mpv-install.bat",
    "C:\Program Files\mpv\installer\mpv-install.bat"
)
foreach ($c in $candidatesBat) {
    if (Test-Path $c) { $assocBat = $c; break }
}
if (-not $assocBat) {
    $mpvCmd = (Get-Command mpv -ErrorAction SilentlyContinue).Source
    if ($mpvCmd) {
        $maybe = Join-Path (Split-Path -Parent $mpvCmd) 'installer\mpv-install.bat'
        if (Test-Path $maybe) { $assocBat = $maybe }
    }
}

if (-not $assocBat) {
    Write-Host "    mpv-install.bat introuvable (associations non modifiées)." -ForegroundColor Yellow
} else {
    Write-Host "    trouvé : $assocBat"
    $rep = Read-Host "Lancer maintenant pour associer les types de fichiers a mpv ? (O/n)"
    if ([string]::IsNullOrWhiteSpace($rep) -or $rep -match '^[OoYy]') {
        try {
            Write-Host "    lancement (UAC : accepte l'elevation)..." -ForegroundColor Cyan
            Start-Process -FilePath $assocBat -Verb RunAs -Wait
            Write-Host "    OK : associations mises a jour." -ForegroundColor Green
        } catch {
            Write-Host "    Echec : $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "    ignore."
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host " Installation terminée." -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Pour tester : ouvre une vidéo avec mpv et bouge la souris."
Write-Host "Si tu vois une OSC moderne avec accent orange, c'est gagné."
Write-Host ""
Read-Host "Appuie sur Entrée pour fermer"
