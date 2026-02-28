# Mobile Assessment Modules

Scripts in this directory target mobile application platforms:
- APK static and dynamic analysis
- iOS IPA assessment
- Certificate pinning bypass
- Deep-link and intent hijacking
- Insecure data storage checks

## Naming Convention

`<platform>_<technique>.py|sh`

Example: `apk_decompile.sh`, `ios_keychain_dump.py`

## Usage

```bash
vex mobile <script> [args...]
vex mobile <script> -ai [args...]
```
