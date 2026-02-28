#!/usr/bin/env python3
"""
web/recon.py — Basic web reconnaissance helper.

Usage:
  vex web recon -t <target_url> [-o <output_file>]
"""

import argparse
import sys
import urllib.request
import urllib.error

HEADERS = {
    "User-Agent": "Mozilla/5.0 (compatible; VEX/1.0)",
}


def parse_args():
    p = argparse.ArgumentParser(
        description="Basic web reconnaissance: banner grab, header dump, redirect chain."
    )
    p.add_argument("-t", "--target", required=True, help="Target URL (e.g. https://example.com)")
    p.add_argument("-o", "--output", help="Write results to this file")
    return p.parse_args()


def recon(target: str) -> dict:
    results = {"target": target, "status": None, "headers": {}, "redirect_chain": []}
    req = urllib.request.Request(target, headers=HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            results["status"] = resp.status
            results["headers"] = dict(resp.headers)
            results["redirect_chain"] = [target]
    except urllib.error.HTTPError as e:
        results["status"] = e.code
        results["headers"] = dict(e.headers)
    except Exception as e:  # noqa: BLE001
        print(f"[-] Error: {e}", file=sys.stderr)
        sys.exit(1)
    return results


def main():
    args = parse_args()
    print(f"[*] Target  : {args.target}")
    data = recon(args.target)
    print(f"[*] Status  : {data['status']}")
    print("[*] Headers :")
    for k, v in data["headers"].items():
        print(f"    {k}: {v}")

    if args.output:
        with open(args.output, "w") as fh:
            for k, v in data["headers"].items():
                fh.write(f"{k}: {v}\n")
        print(f"[+] Results saved to {args.output}")


if __name__ == "__main__":
    main()
