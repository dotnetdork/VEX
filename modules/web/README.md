# Web Application Exploitation Modules

Scripts in this directory target web application vulnerabilities including:
- SQL injection
- Cross-site scripting (XSS)
- SSRF / XXE / SSTI
- Authentication bypass
- Directory traversal

## Naming Convention

`<technique>_<target|tool>.py|sh`

Example: `sqli_blind.py`, `xss_reflector.sh`

## Usage

```bash
vex web <script> [args...]
vex web <script> -ai [args...]   # with AI-assisted context
```
