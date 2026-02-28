@echo off
:: =============================================================================
:: V.E.X. — Volatile Execution X-tension
:: Windows CMD / PowerShell launcher
::
:: Delegates to vex.ps1 (cross-platform PowerShell launcher).
:: Add the VEX\bin directory to your PATH and type "vex" from any prompt.
:: =============================================================================

setlocal

:: Directory containing this .bat file (without trailing backslash)
set "VEX_BIN=%~dp0"
if "%VEX_BIN:~-1%"=="\" set "VEX_BIN=%VEX_BIN:~0,-1%"

:: ---- Try PowerShell 7+ (pwsh) first -----------------------------------------
where pwsh >nul 2>&1
if %errorlevel% equ 0 (
    pwsh -NoLogo -NonInteractive -File "%VEX_BIN%\vex.ps1" %*
    exit /b %errorlevel%
)

:: ---- Fall back to Windows PowerShell 5 (powershell) -------------------------
where powershell >nul 2>&1
if %errorlevel% equ 0 (
    powershell -NoLogo -NonInteractive -File "%VEX_BIN%\vex.ps1" %*
    exit /b %errorlevel%
)

:: ---- Last resort: try Bash directly (legacy behaviour) ----------------------
where wsl >nul 2>&1
if %errorlevel% equ 0 (
    for /f "delims=" %%P in ('wsl wslpath -u "%VEX_BIN%\vex"') do set "WSL_SCRIPT=%%P"
    wsl bash "%WSL_SCRIPT%" %*
    exit /b %errorlevel%
)

where bash >nul 2>&1
if %errorlevel% equ 0 (
    bash "%VEX_BIN%\vex" %*
    exit /b %errorlevel%
)

:: ---- Nothing found ----------------------------------------------------------
echo [!] Neither PowerShell nor Bash was found.
echo     Install one of the following, then re-open your terminal:
echo       - PowerShell 7  : https://aka.ms/powershell
echo       - Git for Windows (Git Bash) : https://git-scm.com
exit /b 1
