# Network Scanning & Protocol Manipulation Modules

Scripts in this directory target network-layer operations:
- Host and port discovery
- Service fingerprinting
- Protocol fuzzing
- MITM / ARP poisoning helpers
- Packet crafting

## Naming Convention

`<technique>_<protocol|scope>.py|sh`

Example: `port_scan.sh`, `arp_spoof.py`, `dns_enum.sh`

## Usage

```bash
vex network <script> [args...]
vex network <script> -ai [args...]
```
