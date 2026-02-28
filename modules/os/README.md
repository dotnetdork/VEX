# OS / Local Privilege Escalation Modules

Scripts in this directory target OS-level weaknesses:
- Linux / macOS local privilege escalation
- Windows privilege escalation
- SUID/SGID abuse
- Cron / scheduled task manipulation
- Kernel exploit helpers

## Naming Convention

`<os>_<technique>.py|sh`

Example: `linux_suid_scan.sh`, `win_token_impersonate.py`

## Usage

```bash
vex os <script> [args...]
vex os <script> -ai [args...]
```
