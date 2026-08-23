# =============================================================
#  Install-ModernZ.ps1
#  Installs ModernZ + this polished config for vanilla mpv.
#
#  USAGE:
#   1. Right-click this file > "Run with PowerShell"
#      (or open PowerShell and run: .\Install-ModernZ.ps1)
#   2. Confirm the target location (default: %APPDATA%\mpv)
#
#  The script:
#   - checks that mpv is installed; if not, offers to install it
#     with winget (package shinchiro.mpv)
#   - copies mpv.conf, input.conf, scripts, script-opts, shaders, fonts
#   - backs up any existing file into _backup-YYYYMMDD-HHMMSS
#   - removes old leftover files (modernx, etc.)
#
#  IMPORTANT: run this script YOURSELF (double-click the .bat).
#  Do NOT let the Claude desktop app run it: its writes to
#  AppData are redirected into a sandbox that mpv cannot see
#  (seen on 2026-07-02 - the real folder stayed empty).
# =============================================================

$ErrorActionPreference = 'Stop'
$src = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Source: $src" -ForegroundColor Cyan

# --- Check / install mpv ---
# This repo ships settings only: without mpv.exe they are useless.
function Find-MpvExe {
    $paths = @(
        "$env:ProgramFiles\MPV Player\mpv.exe",
        "$env:ProgramFiles\mpv\mpv.exe",
        "${env:ProgramFiles(x86)}\MPV Player\mpv.exe",
        "${env:ProgramFiles(x86)}\mpv\mpv.exe",
        "$env:LOCALAPPDATA\Programs\MPV Player\mpv.exe",
        "$env:LOCALAPPDATA\Programs\mpv\mpv.exe"
    )
    foreach ($p in $paths) { if ($p -and (Test-Path $p)) { return $p } }

    $appPaths = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\mpv.exe'
    $reg = (Get-ItemProperty -Path $appPaths -ErrorAction SilentlyContinue).'(default)'
    if ($reg -and (Test-Path $reg)) { return $reg }

    $cmd = Get-Command mpv.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    return $null
}

Write-Host ""
Write-Host "==> Looking for mpv" -ForegroundColor Cyan
$mpvExe = Find-MpvExe

if ($mpvExe) {
    Write-Host "    found: $mpvExe" -ForegroundColor Green
} else {
    Write-Host "    mpv is not installed on this machine." -ForegroundColor Yellow
    Write-Host ""

    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        Write-Host "    winget not found: automatic install is not possible." -ForegroundColor Red
        Write-Host "    Install mpv manually, then run this script again:"
        Write-Host "      https://github.com/shinchiro/mpv-winbuild-cmake/releases"
        Read-Host "Press Enter to close"
        exit 1
    }

    $rep = Read-Host "Install mpv now with winget (shinchiro.mpv)? (Y/n)"
    if (-not ([string]::IsNullOrWhiteSpace($rep) -or $rep -match '^[OoYy]')) {
        Write-Host "    Cancelled: install mpv, then run this script again." -ForegroundColor Yellow
        Read-Host "Press Enter to close"
        exit 1
    }

    Write-Host "    installing (UAC: accept the elevation prompt)..." -ForegroundColor Cyan
    # winget writes to stderr: relax ErrorActionPreference for the call.
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & winget.exe install --id shinchiro.mpv --source winget --exact `
        --accept-package-agreements --accept-source-agreements
    $rc = $LASTEXITCODE
    $ErrorActionPreference = $prevEap

    $mpvExe = Find-MpvExe
    if (-not $mpvExe) {
        Write-Host ""
        Write-Host "    Install failed (winget returned $rc)." -ForegroundColor Red
        Write-Host "    Install mpv manually, then run this script again:"
        Write-Host "      https://github.com/shinchiro/mpv-winbuild-cmake/releases"
        Read-Host "Press Enter to close"
        exit 1
    }
    Write-Host "    OK: mpv installed -> $mpvExe" -ForegroundColor Green
}

# --- Classic pitfall: portable_config next to mpv.exe ---
$portableCfg = Join-Path (Split-Path -Parent $mpvExe) 'portable_config'
if (Test-Path $portableCfg) {
    Write-Host ""
    Write-Host "    WARNING: a portable_config folder exists next to mpv.exe:" -ForegroundColor Yellow
    Write-Host "      $portableCfg"
    Write-Host "    While it is there, mpv IGNORES %APPDATA%\mpv. Target that path" -ForegroundColor Yellow
    Write-Host "    with option [c] below, or delete/rename that folder." -ForegroundColor Yellow
}

# --- Destination choice ---
$candidates = @(
    "$env:APPDATA\mpv"     # 1) standard location for vanilla mpv (shinchiro / CI build)
)

Write-Host ""
Write-Host "Choose where the mpv config goes:" -ForegroundColor Yellow
for ($i = 0; $i -lt $candidates.Count; $i++) {
    $exists = if (Test-Path $candidates[$i]) { '[exists]' } else { '[will be created]' }
    Write-Host ("  [{0}] {1} {2}" -f ($i + 1), $candidates[$i], $exists)
}
Write-Host "  [c] Custom path"
Write-Host ""
$choice = Read-Host "Your choice (1 by default)"
if ([string]::IsNullOrWhiteSpace($choice)) { $choice = '1' }

switch ($choice) {
    '1'     { $dest = $candidates[0] }
    'c'     { $dest = Read-Host "Full path" }
    default { $dest = $candidates[0] }
}

Write-Host ""
Write-Host "==> Destination: $dest" -ForegroundColor Cyan
if (-not (Test-Path $dest)) {
    Write-Host "    (creating the folder)"
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

# --- Create the subfolders ---
foreach ($sub in 'scripts', 'script-opts', 'fonts', 'shaders') {
    $p = Join-Path $dest $sub
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# --- Back up existing files ---
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
    Write-Host "==> Backing up existing files into: $backup" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    foreach ($f in $toBackup) {
        $full = Join-Path $dest $f
        $rel  = $f
        $tgt  = Join-Path $backup $rel
        $tgtDir = Split-Path -Parent $tgt
        if (-not (Test-Path $tgtDir)) { New-Item -ItemType Directory -Path $tgtDir -Force | Out-Null }
        Copy-Item -Path $full -Destination $tgt -Force
        Write-Host "    backed up: $rel"
    }
}

# --- Copies ---
Write-Host ""
Write-Host "==> Installing files" -ForegroundColor Green
Copy-Item -Path (Join-Path $src 'scripts\modernz.lua')        -Destination (Join-Path $dest 'scripts\modernz.lua')        -Force
Copy-Item -Path (Join-Path $src 'scripts\delete_current.lua') -Destination (Join-Path $dest 'scripts\delete_current.lua') -Force
Copy-Item -Path (Join-Path $src 'fonts\modernz-icons.ttf')    -Destination (Join-Path $dest 'fonts\modernz-icons.ttf')    -Force
Copy-Item -Path (Join-Path $src 'script-opts\modernz.conf')   -Destination (Join-Path $dest 'script-opts\modernz.conf')   -Force
Copy-Item -Path (Join-Path $src 'script-opts\modernz-locale.json') -Destination (Join-Path $dest 'script-opts\modernz-locale.json') -Force
Copy-Item -Path (Join-Path $src 'mpv.conf')                   -Destination (Join-Path $dest 'mpv.conf')                   -Force
Copy-Item -Path (Join-Path $src 'input.conf')                 -Destination (Join-Path $dest 'input.conf')                 -Force
Write-Host "    OK: modernz.lua, delete_current.lua, modernz-icons.ttf, modernz.conf, modernz-locale.json (translations), mpv.conf, input.conf"

# --- Shaders ---
$shaderSrc = Join-Path $src 'shaders'
if (Test-Path $shaderSrc) {
    Get-ChildItem -Path $shaderSrc -File | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination (Join-Path $dest "shaders\$($_.Name)") -Force
        Write-Host "    shader: $($_.Name)"
    }
}

# --- Cleanup ---
Write-Host ""
Write-Host "==> Removing old files" -ForegroundColor Green
$toRemove = @(
    'scripts\modernx.lua',
    'scripts\input.conf',
    'fonts\modernx-osc-icon.ttf'
)
foreach ($r in $toRemove) {
    $full = Join-Path $dest $r
    if (Test-Path $full) {
        Remove-Item -Path $full -Force
        Write-Host "    removed: $r"
    }
}

# --- Check what is actually in place ---
Write-Host ""
Write-Host "==> Checking folder $dest" -ForegroundColor Green
$deployed = Get-ChildItem -Path $dest -Recurse -File | Where-Object { $_.FullName -notmatch '_backup-' }
foreach ($d in $deployed) {
    Write-Host ("    {0,8} B   {1}" -f $d.Length, $d.FullName.Substring($dest.Length + 1))
}
Write-Host ("    Total: {0} files" -f $deployed.Count)

# --- File associations (mpv-install.bat) ---
Write-Host ""
Write-Host "==> Windows file associations" -ForegroundColor Green

$assocBat = $null
$candidatesBat = @(
    (Join-Path $src 'installer\mpv-install.bat'),   # copy shipped in this repo (extra extensions)
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
    Write-Host "    mpv-install.bat not found (associations left untouched)." -ForegroundColor Yellow
} else {
    Write-Host "    found: $assocBat"
    $rep = Read-Host "Run it now to register the file types with mpv? (Y/n)"
    if ([string]::IsNullOrWhiteSpace($rep) -or $rep -match '^[OoYy]') {
        try {
            Write-Host "    running (UAC: accept the elevation prompt)..." -ForegroundColor Cyan
            Start-Process -FilePath $assocBat -Verb RunAs -Wait
            Write-Host "    OK: associations updated." -ForegroundColor Green
        } catch {
            Write-Host "    Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "    skipped."
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host " Installation complete." -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "To test: open a video with mpv and move the mouse."
Write-Host "If you see a modern OSC with an orange accent, you are set."
Write-Host ""
Read-Host "Press Enter to close"
