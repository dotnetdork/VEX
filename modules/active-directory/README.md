# Active Directory Modules

Scripts in this directory target Microsoft Active Directory environments:
- Kerberoasting / AS-REP roasting
- BloodHound data collection
- LDAP enumeration
- DCSync / Pass-the-Hash / Pass-the-Ticket
- GPO and ACL abuse

## Naming Convention

`<technique>.py|sh`

Example: `kerberoast.py`, `ldap_enum.sh`, `bloodhound_collect.py`

## Usage

```bash
vex active-directory <script> [args...]
vex active-directory <script> -ai [args...]
```
