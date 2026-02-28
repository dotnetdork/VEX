# V.E.X. — Volatile Execution X-tension

> An elite, modular Red Team framework for streamlined script execution.
> Featuring dynamic CLI discovery across Web, AD, and Cloud modules.
> Built for stealth and scalability with integrated AI-readiness via the `-ai` flag.

```
 /$$    /$$ /$$$$$$$$ /$$   /$$
| $$   | $$| $$_____/| $$  / $$
| $$   | $$| $$      |  $$/ $$/
|  $$ / $$/| $$$$$    \  $$$$/
 \  $$ $$/ | $$__/     >$$  $$
  \  $$$/  | $$       /$$/\  $$
   \  $/   | $$$$$$$$| $$  \ $$
    \_/    |________/|__/  |__/

  VOLATILE EXECUTION X-TENSION
 [ Red Team Script Management Framework ]
```

---

## Directory Structure

```
VEX/
├── bin/
│   └── vex                 # Master CLI entry-point
├── modules/
│   ├── web/                # Web application exploitation
│   ├── mobile/             # APK/iOS assessment tools
│   ├── os/                 # Local privilege escalation
│   ├── network/            # Scanning & protocol manipulation
│   ├── cloud/              # AWS / Azure / GCP misconfig scripts
│   ├── active-directory/   # Kerberoasting & AD enumeration
│   ├── exfil/              # Data egress & stealth transfer
│   └── post-ex/            # Persistence & cleanup
├── lib/
│   ├── utils.sh            # Shared Bash helpers (logging, dependency checks)
│   └── ai.sh               # AI-assist integration stub
├── data/
│   └── config.ini          # Global configuration template
├── loot/                   # ⚠ Git-ignored — operational output
└── results/                # ⚠ Git-ignored — operational output
```

---

## Quick Start

```bash
# Make the CLI available on your PATH
export PATH="$PATH:$(pwd)/bin"

# Show help and available categories
vex help

# List all modules
vex list

# List modules in a specific category
vex list web

# Run a module
vex web recon -t https://target.example.com

# Run with AI-assisted context (requires VEX_AI_KEY env var)
vex active-directory kerberoast -ai -d corp.local -u user -p pass
```

---

## Module Categories

| Category           | Description                                      |
|--------------------|--------------------------------------------------|
| `web`              | Web application exploitation (SQLi, XSS, SSRF…) |
| `mobile`           | APK / iOS assessment                             |
| `os`               | Local privilege escalation                       |
| `network`          | Port scanning, protocol fuzzing, MITM            |
| `cloud`            | AWS / Azure / GCP misconfiguration               |
| `active-directory` | Kerberoasting, LDAP enum, DCSync                 |
| `exfil`            | DNS tunnelling, HTTPS upload, steganography      |
| `post-ex`          | Persistence, lateral movement, log cleanup       |

---

## Adding a New Module

Drop any `.py`, `.sh`, or compiled executable into the appropriate `modules/<category>/` directory. VEX discovers scripts dynamically — no registration required.

```bash
cp my_tool.py modules/web/
vex web my_tool --help
```

---

## AI Integration

Set `VEX_AI_KEY` in your environment to enable live LLM queries via the `-ai` flag. Configure the endpoint and model in `data/config.ini` or via environment variables:

```bash
export VEX_AI_KEY="sk-..."
export VEX_AI_ENDPOINT="https://api.openai.com/v1/chat/completions"
export VEX_AI_MODEL="gpt-4o"

vex web recon -ai -t https://target.example.com
```

---

> **Legal Notice:** This framework is intended exclusively for authorised penetration testing and security research. Misuse against systems without explicit written permission is illegal. The authors assume no liability.

