@echo off
:: =============================================================================
:: V.E.X. — Volatile Execution X-tension
:: Windows CMD / PowerShell launcher
::
:: Delegates to the Bash entry-point (bin\vex) via WSL or Git Bash.
:: Add the VEX\bin directory to your PATH and type "vex" from any prompt.
:: =============================================================================

setlocal

:: Directory containing this .bat file (without trailing backslash)
set "VEX_BIN=%~dp0"
if "%VEX_BIN:~-1%"=="\" set "VEX_BIN=%VEX_BIN:~0,-1%"

:: ---- Try WSL first ----------------------------------------------------------
where wsl >nul 2>&1
if %errorlevel% equ 0 (
    :: Convert the Windows path to a WSL path and invoke the Bash script
    for /f "delims=" %%P in ('wsl wslpath -u "%VEX_BIN%\vex"') do set "WSL_SCRIPT=%%P"
    wsl bash "%WSL_SCRIPT%" %*
    exit /b %errorlevel%
)

:: ---- Fall back to Git Bash / MSYS2 bash ------------------------------------
where bash >nul 2>&1
if %errorlevel% equ 0 (
    bash "%VEX_BIN%\vex" %*
    exit /b %errorlevel%
)

:: ---- No Bash found ----------------------------------------------------------
echo [!] No Bash interpreter found.
echo     Install one of the following, then re-open your terminal:
echo       - Windows Subsystem for Linux  : https://aka.ms/wsl
echo       - Git for Windows (Git Bash)   : https://git-scm.com
exit /b 1
