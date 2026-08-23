@echo off
REM =============================================================
REM  Install-ModernZ.bat
REM  Double-click this file to run Install-ModernZ.ps1 without
REM  worrying about the PowerShell ExecutionPolicy.
REM =============================================================
setlocal
set "PS1=%~dp0Install-ModernZ.ps1"

if not exist "%PS1%" (
    echo [ERROR] Install-ModernZ.ps1 not found next to this .bat file.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo [The PowerShell script exited with code %RC%]
    pause
)

endlocal & exit /b %RC%
