@echo off
REM =============================================================
REM  Install-ModernZ.bat
REM  Double-cliquez ce fichier pour lancer Install-ModernZ.ps1
REM  sans se soucier de l'ExecutionPolicy PowerShell.
REM =============================================================
setlocal
set "PS1=%~dp0Install-ModernZ.ps1"

if not exist "%PS1%" (
    echo [ERREUR] Install-ModernZ.ps1 introuvable a cote de ce .bat.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo [Le script PowerShell s'est termine avec le code %RC%]
    pause
)

endlocal & exit /b %RC%
