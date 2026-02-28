#!/usr/bin/env pwsh
# =============================================================================
# V.E.X. — Volatile Execution X-tension
# Cross-platform PowerShell launcher  (Windows / macOS / Linux)
#
# Usage:  vex <category> <script> [args...]
#         vex list [category]
#         vex help
# =============================================================================

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# OS detection
# ---------------------------------------------------------------------------
$VEX_OS = if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) { "windows" } `
     elseif ($IsMacOS)  { "macos" } `
     else               { "linux" }

# ---------------------------------------------------------------------------
# Resolve VEX_ROOT from this script's location (bin/../)
# ---------------------------------------------------------------------------
$VEX_ROOT    = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$MODULES_DIR = Join-Path $VEX_ROOT "modules"
$LIB_DIR     = Join-Path $VEX_ROOT "lib"

# ---------------------------------------------------------------------------
# Coloured output helpers
# ---------------------------------------------------------------------------
function Write-Info    ([string]$m) { Write-Host "[*] $m" -ForegroundColor Cyan }
function Write-Ok      ([string]$m) { Write-Host "[+] $m" -ForegroundColor Green }
function Write-Warn    ([string]$m) { Write-Host "[!] $m" -ForegroundColor Yellow }
function Write-Err     ([string]$m) { Write-Host "[-] $m" -ForegroundColor Red }

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
function Show-Banner {
    $os = switch ($VEX_OS) {
        "windows" { "Windows" }
        "macos"   { "macOS" }
        default   { "Linux" }
    }
    Write-Host ""
    Write-Host " /`$`$    /`$`$ /`$`$`$`$`$`$`$`$`$ /`$`$   /`$`$" -ForegroundColor DarkCyan
    Write-Host "| `$`$   | `$`$| `$`$_____/| `$`$  / `$`$" -ForegroundColor DarkCyan
    Write-Host "| `$`$   | `$`$| `$`$      |  `$`$/ `$`$/" -ForegroundColor DarkCyan
    Write-Host "|  `$`$ / `$`$/| `$`$`$`$`$    \  `$`$`$`$/" -ForegroundColor DarkCyan
    Write-Host " \  `$`$ `$`$/ | `$`$__/     >`$`$  `$`$" -ForegroundColor DarkCyan
    Write-Host "  \  `$`$`$`$/  | `$`$       /`$`$`$/\  `$`$" -ForegroundColor DarkCyan
    Write-Host "   \  `$`$/   | `$`$`$`$`$`$`$`$`$| `$`$  \ `$`$" -ForegroundColor DarkCyan
    Write-Host "    \_/    |________/|__/  |__/" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  VOLATILE EXECUTION X-TENSION" -ForegroundColor Cyan
    Write-Host " [ Red Team Script Management Framework ]" -ForegroundColor Gray
    Write-Host " [ OS: $os | VEX_ROOT: $VEX_ROOT ]" -ForegroundColor DarkGray
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Find Python 3 interpreter
# ---------------------------------------------------------------------------
function Find-Python3 {
    foreach ($candidate in @("python3", "python", "py")) {
        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($cmd) {
            $ver = & $cmd.Source --version 2>&1
            if ($ver -match "Python 3") { return $cmd.Source }
        }
    }
    return $null
}

# ---------------------------------------------------------------------------
# Find Bash interpreter
# Returns a scriptblock that runs: <bash> <script> [args]
# ---------------------------------------------------------------------------
function Find-Bash {
    if ($VEX_OS -eq "windows") {
        # Prefer WSL
        if (Get-Command wsl -ErrorAction SilentlyContinue) {
            return "wsl"
        }
        # Fall back to Git Bash / MSYS2
        foreach ($b in @("bash", "C:\Program Files\Git\bin\bash.exe",
                         "C:\Program Files (x86)\Git\bin\bash.exe")) {
            if (Get-Command $b -ErrorAction SilentlyContinue) { return $b }
        }
    } else {
        foreach ($b in @("bash", "/bin/bash", "/usr/bin/bash", "/usr/local/bin/bash")) {
            if (Get-Command $b -ErrorAction SilentlyContinue) { return $b }
        }
    }
    return $null
}

# ---------------------------------------------------------------------------
# Convert a Windows absolute path to a WSL path
# ---------------------------------------------------------------------------
function ConvertTo-WslPath ([string]$WinPath) {
    return (wsl wslpath -u ($WinPath -replace '\\', '/')).Trim()
}

# ---------------------------------------------------------------------------
# List categories
# ---------------------------------------------------------------------------
function Get-Categories ([string]$Prefix = "") {
    Get-ChildItem -Path $MODULES_DIR -Directory |
        ForEach-Object { "$Prefix$($_.Name)" }
}

# ---------------------------------------------------------------------------
# List modules
# ---------------------------------------------------------------------------
function Show-Modules ([string]$Category = "") {
    if ($Category) {
        $catPath = Join-Path $MODULES_DIR $Category
        if (-not (Test-Path $catPath)) {
            Write-Err "Unknown category: $Category"
            Write-Host "  Available: $(Get-Categories)" -ForegroundColor Gray
            exit 1
        }
        Write-Info "Scripts in '$Category':"
        Get-ChildItem -Path $catPath -File |
            Where-Object { $_.Extension -in @(".py", ".sh") -or $_.Name -notmatch '\.' } |
            ForEach-Object { Write-Host "    $($_.Name)" }
    } else {
        Write-Info "All available modules:"
        Get-ChildItem -Path $MODULES_DIR -Directory | ForEach-Object {
            Write-Host "  [$($_.Name)]" -ForegroundColor Yellow
            Get-ChildItem -Path $_.FullName -File |
                Where-Object { $_.Extension -in @(".py", ".sh") -or $_.Name -notmatch '\.' } |
                ForEach-Object { Write-Host "    $($_.Name)" }
        }
    }
}

# ---------------------------------------------------------------------------
# Find a script in a category directory
# Tries: exact name → name.py → name.sh → fuzzy basename match
# ---------------------------------------------------------------------------
function Find-ModuleScript ([string]$CatPath, [string]$Name) {
    # Exact
    $exact = Join-Path $CatPath $Name
    if (Test-Path $exact -PathType Leaf) { return $exact }

    # Known extensions
    foreach ($ext in @(".py", ".sh")) {
        $c = Join-Path $CatPath "$Name$ext"
        if (Test-Path $c -PathType Leaf) { return $c }
    }

    # Fuzzy: match by basename without extension
    $match = Get-ChildItem -Path $CatPath -File |
        Where-Object { [IO.Path]::GetFileNameWithoutExtension($_.Name) -eq $Name } |
        Select-Object -First 1
    if ($match) { return $match.FullName }

    return $null
}

# ---------------------------------------------------------------------------
# Execute a single script file with the supplied args
# ---------------------------------------------------------------------------
function Invoke-ModuleScript ([string]$Script, [string[]]$ExtraArgs) {
    $ext  = [IO.Path]::GetExtension($Script).ToLower()
    $name = [IO.Path]::GetFileName($Script)

    Write-Host "[>] Executing: $name $($ExtraArgs -join ' ')" -ForegroundColor White
    Write-Host ""

    if ($ext -eq ".py") {
        # ── Python: native on all platforms ──────────────────────────────
        $python = Find-Python3
        if (-not $python) {
            Write-Err "Python 3 not found. Install from https://python.org"
            exit 1
        }
        & $python $Script @ExtraArgs
        exit $LASTEXITCODE

    } elseif ($ext -eq ".sh") {
        # ── Bash script ───────────────────────────────────────────────────
        $bash = Find-Bash
        if (-not $bash) {
            Write-Err "No Bash interpreter found."
            Write-Host ""
            Write-Host "  Install one of the following, then re-open your terminal:" -ForegroundColor Gray
            if ($VEX_OS -eq "windows") {
                Write-Host "    Windows Subsystem for Linux : https://aka.ms/wsl"     -ForegroundColor Gray
                Write-Host "    Git for Windows (Git Bash)  : https://git-scm.com"   -ForegroundColor Gray
            } else {
                Write-Host "    Install bash via your system package manager."         -ForegroundColor Gray
            }
            exit 1
        }

        if ($VEX_OS -eq "windows" -and $bash -eq "wsl") {
            # Convert Windows path → WSL path, then run via WSL
            $wslScript = ConvertTo-WslPath $Script
            wsl bash $wslScript @ExtraArgs
        } else {
            & $bash $Script @ExtraArgs
        }
        exit $LASTEXITCODE

    } else {
        Write-Err "Cannot determine how to execute: $Script"
        Write-Err "File must have a .py or .sh extension."
        exit 1
    }
}

# ---------------------------------------------------------------------------
# AI context stub
# ---------------------------------------------------------------------------
function Show-AIContext ([string]$Category, [string]$Script, [string[]]$ExtraArgs) {
    $name = [IO.Path]::GetFileName($Script)
    Write-Host "[AI] ── VEX AI-Assist ─────────────────────────────────────────────────────" -ForegroundColor Magenta
    Write-Host "  Category : $Category"
    Write-Host "  Script   : $name"
    Write-Host "  Args     : $($ExtraArgs -join ' ')"
    Write-Host "  Path     : $Script"
    Write-Host ""
    Write-Host "  [AI] Analysing script capabilities…" -ForegroundColor Magenta
    Get-Content $Script -TotalCount 20 | ForEach-Object { Write-Host "  $_" }
    Write-Host "────────────────────────────────────────────────────────────────────────────" -ForegroundColor Magenta
    Write-Host "  NOTE: Full AI integration requires setting VEX_AI_KEY and pointing" -ForegroundColor DarkGray
    Write-Host "        lib/ai.sh at a supported LLM endpoint (see data/config.ini)." -ForegroundColor DarkGray
    Write-Host "────────────────────────────────────────────────────────────────────────────" -ForegroundColor Magenta
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Run a module
# ---------------------------------------------------------------------------
function Invoke-Module ([string]$Category, [string]$ScriptName, [string[]]$ExtraArgs) {
    $catPath = Join-Path $MODULES_DIR $Category
    if (-not (Test-Path $catPath)) {
        Write-Err "Unknown category: $Category"
        Write-Host "  Run 'vex list' to see available categories." -ForegroundColor Gray
        exit 1
    }

    $target = Find-ModuleScript $catPath $ScriptName
    if (-not $target) {
        Write-Err "Script '$ScriptName' not found in category '$Category'."
        Write-Host "  Run 'vex list $Category' to see available scripts." -ForegroundColor Gray
        exit 1
    }

    # Strip -ai flag
    $aiMode    = $false
    $cleanArgs = [System.Collections.Generic.List[string]]::new()
    foreach ($a in $ExtraArgs) {
        if ($a -eq "-ai") { $aiMode = $true } else { $cleanArgs.Add($a) }
    }

    if ($aiMode) { Show-AIContext $Category $target $cleanArgs.ToArray() }
    Invoke-ModuleScript $target $cleanArgs.ToArray()
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
function Show-Usage {
    $cats = Get-Categories "  "
    Write-Host @"
Usage:
  vex <category> <script> [args...]       Run a module script
  vex <category> <script> -ai [args...]   Run with AI-assisted context
  vex list [category]                     List available modules
  vex help                                Show this help

Categories:
$cats

Examples:
  vex web recon -t https://example.com
  vex network port_scan 192.168.1.0/24
  vex active-directory kerberoast -d corp.local -u admin -p pass
  vex list web
"@
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
Show-Banner

$cmd = if ($args.Count -gt 0) { $args[0] } else { "help" }

switch ($cmd) {
    { $_ -in @("help", "--help", "-h") } {
        Show-Usage
    }
    "list" {
        $cat = if ($args.Count -gt 1) { $args[1] } else { "" }
        Show-Modules $cat
    }
    default {
        if ($args.Count -lt 2) {
            Show-Usage
            exit 1
        }
        $extra = if ($args.Count -gt 2) { $args[2..($args.Count - 1)] } else { @() }
        Invoke-Module $args[0] $args[1] $extra
    }
}
