# =============================================================
#  Install-ModernZ.ps1
#  Installe ModernZ + ta config polie pour mpv (mpvio).
#
#  USAGE :
#   1. Clic droit sur ce fichier > "Exécuter avec PowerShell"
#      (ou ouvrir PowerShell en admin et : .\Install-ModernZ.ps1)
#   2. Choisir l'emplacement cible (recommandé : %APPDATA%\mpv)
#
#  Le script :
#   - copie modernz.lua + modernz-icons.ttf
#   - copie ton modernz.conf et mpv.conf personnalisés
#   - retire l'ancien modernx.lua / modernx-osc-icon.ttf
#   - retire le fichier scripts/input.conf orphelin
# =============================================================

$ErrorActionPreference = 'Stop'
$src = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Source : $src" -ForegroundColor Cyan

# --- Choix de la destination ---
$candidates = @(
    "$env:APPDATA\mpv.net",                                                # 1) mpv.net (RECOMMANDÉ si mpv.net installé)
    "$env:APPDATA\mpv",                                                    # 2) mpv vanilla (shinchiro/CI build)
    "C:\ProgramData\chocolatey\lib\mpvio.install\tools\portable_config",   # 3) ancien mpvio chocolatey (admin requis)
    "C:\ProgramData\chocolatey\lib\mpvio.portable\tools\portable_config"   # 4) variante portable
)

Write-Host ""
Write-Host "Choisis l'emplacement de la config mpv :" -ForegroundColor Yellow
for ($i = 0; $i -lt $candidates.Count; $i++) {
    $exists = if (Test-Path $candidates[$i]) { '[existe]' } else { '[à créer]' }
    Write-Host ("  [{0}] {1} {2}" -f ($i + 1), $candidates[$i], $exists)
}
Write-Host "  [c] Chemin personnalisé"
Write-Host ""
$choice = Read-Host "Ton choix (1 par défaut, recommandé)"
if ([string]::IsNullOrWhiteSpace($choice)) { $choice = '1' }

switch ($choice) {
    '1' { $dest = $candidates[0] }
    '2' { $dest = $candidates[1] }
    '3' { $dest = $candidates[2] }
    'c' { $dest = Read-Host "Chemin complet" }
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
    'scripts\modernx.lua',
    'scripts\modernz.lua',
    'scripts\input.conf',
    'script-opts\modernz.conf',
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
Write-Host "==> Installation des fichiers ModernZ" -ForegroundColor Green
Copy-Item -Path (Join-Path $src 'scripts\modernz.lua')        -Destination (Join-Path $dest 'scripts\modernz.lua')        -Force
Copy-Item -Path (Join-Path $src 'scripts\delete_current.lua') -Destination (Join-Path $dest 'scripts\delete_current.lua') -Force
Copy-Item -Path (Join-Path $src 'fonts\modernz-icons.ttf')    -Destination (Join-Path $dest 'fonts\modernz-icons.ttf')    -Force
Copy-Item -Path (Join-Path $src 'script-opts\modernz.conf')   -Destination (Join-Path $dest 'script-opts\modernz.conf')   -Force
Copy-Item -Path (Join-Path $src 'mpv.conf')                   -Destination (Join-Path $dest 'mpv.conf')                   -Force
Copy-Item -Path (Join-Path $src 'input.conf')                 -Destination (Join-Path $dest 'input.conf')                 -Force
Write-Host "    OK : modernz.lua, delete_current.lua, modernz-icons.ttf, modernz.conf, mpv.conf, input.conf"

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

Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host " Installation terminée." -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Pour tester : ouvre une vidéo avec mpv et bouge la souris."
Write-Host "Si tu vois une OSC moderne avec accent orange, c'est gagné."
Write-Host ""
if ($dest -ne $candidates[0]) {
    Write-Host "ASTUCE : pour éviter que Chocolatey n'écrase ta config à la prochaine" -ForegroundColor Yellow
    Write-Host "        mise à jour de mpvio, déplace ta config dans : $env:APPDATA\mpv" -ForegroundColor Yellow
    Write-Host "        (mpv lit cet emplacement en priorité sur Windows)" -ForegroundColor Yellow
    Write-Host ""
}
Read-Host "Appuie sur Entrée pour fermer"
