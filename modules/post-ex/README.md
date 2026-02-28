# Post-Exploitation Modules

Scripts in this directory handle persistence and cleanup operations:
- Cron / service-based persistence
- Registry run-key persistence (Windows)
- Log and artefact cleanup
- Rootkit / implant helpers
- Lateral movement helpers

## Naming Convention

`<action>_<technique>.py|sh`

Example: `persist_cron.sh`, `cleanup_logs.sh`, `lateral_wmi.py`

## Usage

```bash
vex post-ex <script> [args...]
vex post-ex <script> -ai [args...]
```
