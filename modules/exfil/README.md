# Exfiltration Modules

Scripts in this directory handle data egress and stealth transfer:
- DNS tunnelling
- HTTPS C2 upload helpers
- Steganography-based exfil
- Cloud storage exfil (S3, Pastebin, etc.)
- File chunking and encryption helpers

## Naming Convention

`<channel>_exfil.py|sh`

Example: `dns_exfil.py`, `https_upload.sh`, `steg_png.py`

## Usage

```bash
vex exfil <script> [args...]
vex exfil <script> -ai [args...]
```
