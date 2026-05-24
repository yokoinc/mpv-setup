# =============================================================
#  Patch-MpvnetLocale.ps1
#  Patche le fichier .mo français de mpv.net pour ajouter des
#  traductions manquantes en amont (ex: "Drop files or URLs to
#  play here.").
#
#  À relancer après chaque update de mpv.net (winget upgrade)
#  car le .mo dans le dossier d'install est écrasé.
#
#  USAGE :
#    .\Patch-MpvnetLocale.ps1
#
#  Sécurité : un backup .mo.bak est créé à la première exécution.
# =============================================================

$ErrorActionPreference = 'Stop'
# Force UTF-8 pour les Write-Host (sinon les accents se mangent en cp1252)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- Dictionnaire de traductions à injecter ---
# Ajoute ici toute string qui apparaît en anglais dans mpv.net
# (vérifier qu'elle n'est PAS déjà dans le .mo upstream avant).
$Translations = [ordered]@{
    'Drop files or URLs to play here.' = 'Glissez fichiers ou URL ici pour lire.'
}

$Mo = "$env:LOCALAPPDATA\Programs\mpv.net\Locale\fr\LC_MESSAGES\mpvnet.mo"
if (-not (Test-Path $Mo)) {
    throw "Fichier .mo introuvable : $Mo (mpv.net n'est peut-être pas installé)"
}

# --- Backup ---
$backup = "$Mo.bak"
if (-not (Test-Path $backup)) {
    Copy-Item $Mo $backup
    Write-Host "Backup créé : $backup"
}

# --- Lecture du .mo ---
function Read-MoEntries {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    # Magic LE = de 12 04 95. On compare byte-à-byte pour éviter les
    # pièges de typage int32/uint32 en PowerShell.
    if ($bytes[0] -ne 0xde -or $bytes[1] -ne 0x12 -or $bytes[2] -ne 0x04 -or $bytes[3] -ne 0x95) {
        $hex = "{0:x2}{1:x2}{2:x2}{3:x2}" -f $bytes[3], $bytes[2], $bytes[1], $bytes[0]
        throw "Magic .mo invalide (0x$hex). Attendu 0x950412de (little-endian)."
    }
    $nstrings     = [BitConverter]::ToUInt32($bytes, 8)
    $origTableOff = [BitConverter]::ToUInt32($bytes, 12)
    $transTableOff= [BitConverter]::ToUInt32($bytes, 16)

    $entries = [ordered]@{}
    for ($i = 0; $i -lt $nstrings; $i++) {
        $oP = $origTableOff + $i * 8
        $oLen = [BitConverter]::ToUInt32($bytes, $oP)
        $oOff = [BitConverter]::ToUInt32($bytes, $oP + 4)
        $msgid = [System.Text.Encoding]::UTF8.GetString($bytes, $oOff, $oLen)

        $tP = $transTableOff + $i * 8
        $tLen = [BitConverter]::ToUInt32($bytes, $tP)
        $tOff = [BitConverter]::ToUInt32($bytes, $tP + 4)
        $msgstr = [System.Text.Encoding]::UTF8.GetString($bytes, $tOff, $tLen)

        $entries[$msgid] = $msgstr
    }
    return $entries
}

# --- Écriture du .mo (sans table de hash) ---
function Write-MoEntries {
    param([string]$Path, $Entries)

    # Tri ordinal (requis par la spec pour la binary search)
    $keys = New-Object 'System.Collections.Generic.List[string]'
    foreach ($k in $Entries.Keys) { $keys.Add($k) }
    $keys.Sort([System.StringComparer]::Ordinal)

    $n = $keys.Count
    $headerSize    = 28
    $origTableOff  = $headerSize
    $transTableOff = $origTableOff + $n * 8
    $stringsStart  = $transTableOff + $n * 8

    $stringsBytes  = New-Object 'System.Collections.Generic.List[byte]'
    $origDesc      = New-Object 'System.Collections.Generic.List[byte]'
    $transDesc     = New-Object 'System.Collections.Generic.List[byte]'

    foreach ($key in $keys) {
        $valueBytes = [System.Text.Encoding]::UTF8.GetBytes([string]$Entries[$key])
        $keyBytes   = [System.Text.Encoding]::UTF8.GetBytes($key)

        $kOff = $stringsStart + $stringsBytes.Count
        $stringsBytes.AddRange($keyBytes)
        $stringsBytes.Add([byte]0)
        $origDesc.AddRange([BitConverter]::GetBytes([uint32]$keyBytes.Length))
        $origDesc.AddRange([BitConverter]::GetBytes([uint32]$kOff))

        $vOff = $stringsStart + $stringsBytes.Count
        $stringsBytes.AddRange($valueBytes)
        $stringsBytes.Add([byte]0)
        $transDesc.AddRange([BitConverter]::GetBytes([uint32]$valueBytes.Length))
        $transDesc.AddRange([BitConverter]::GetBytes([uint32]$vOff))
    }

    $header = New-Object 'System.Collections.Generic.List[byte]'
    # Magic 0x950412de en little-endian (byte par byte pour éviter les pièges de cast)
    $header.AddRange([byte[]](0xde, 0x12, 0x04, 0x95))
    $header.AddRange([BitConverter]::GetBytes([uint32]0))
    $header.AddRange([BitConverter]::GetBytes([uint32]$n))
    $header.AddRange([BitConverter]::GetBytes([uint32]$origTableOff))
    $header.AddRange([BitConverter]::GetBytes([uint32]$transTableOff))
    $header.AddRange([BitConverter]::GetBytes([uint32]0))  # hash size = 0
    $header.AddRange([BitConverter]::GetBytes([uint32]0))  # hash offset = 0

    $output = New-Object 'System.Collections.Generic.List[byte]'
    $output.AddRange($header)
    $output.AddRange($origDesc)
    $output.AddRange($transDesc)
    $output.AddRange($stringsBytes)

    [System.IO.File]::WriteAllBytes($Path, $output.ToArray())
}

# --- Patch ---
$entries = Read-MoEntries -Path $Mo
$before = $entries.Count

$added = 0
$updated = 0
foreach ($k in $Translations.Keys) {
    if ($entries.Contains($k)) {
        if ($entries[$k] -ne $Translations[$k]) { $updated++ }
    } else {
        $added++
    }
    $entries[$k] = $Translations[$k]
}

Write-MoEntries -Path $Mo -Entries $entries

# --- Vérification : relit et confirme ---
$check = Read-MoEntries -Path $Mo
$ok = $true
foreach ($k in $Translations.Keys) {
    if ($check[$k] -ne $Translations[$k]) {
        Write-Host "ÉCHEC vérif : '$k' n'a pas été correctement patché" -ForegroundColor Red
        $ok = $false
    }
}

if ($ok) {
    Write-Host ""
    Write-Host "Patch OK." -ForegroundColor Green
    Write-Host "  entrées avant  : $before"
    Write-Host "  entrées après  : $($check.Count)"
    Write-Host "  +$added ajout(s), $updated mise(s) à jour"
    Write-Host ""
    Write-Host "Relance mpv.net pour voir le changement."
}
