#!/usr/bin/env python3
"""
cloud/aws_s3_enum.py — AWS S3 bucket enumeration helper.

Requires boto3 or the aws CLI. Attempts to list accessible buckets
and checks for public read/write access on a given bucket name.

Usage:
  vex cloud aws_s3_enum [-b <bucket>] [-p <aws_profile>]
"""

import argparse
import subprocess
import sys


def parse_args():
    p = argparse.ArgumentParser(description="AWS S3 bucket enumeration")
    p.add_argument("-b", "--bucket",  help="Specific bucket name to probe")
    p.add_argument("-p", "--profile", default="default", help="AWS CLI profile (default: default)")
    return p.parse_args()


def run(cmd: list[str]) -> tuple[int, str]:
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.returncode, result.stdout + result.stderr


def main():
    args = parse_args()
    base = ["aws", "--profile", args.profile]

    # Check CLI is available
    rc, _ = run(["aws", "--version"])
    if rc != 0:
        print("[-] aws CLI not found. Install from https://aws.amazon.com/cli/", file=sys.stderr)
        sys.exit(1)

    if args.bucket:
        print(f"[*] Probing bucket: s3://{args.bucket}")
        for acl_cmd in [
            base + ["s3", "ls", f"s3://{args.bucket}"],
            base + ["s3api", "get-bucket-acl", "--bucket", args.bucket],
        ]:
            rc, out = run(acl_cmd)
            label = "[+]" if rc == 0 else "[-]"
            print(f"{label} {' '.join(acl_cmd[3:])}")
            if out.strip():
                print(out.strip())
    else:
        print("[*] Listing all accessible buckets…")
        rc, out = run(base + ["s3", "ls"])
        if rc != 0:
            print(f"[-] Could not list buckets:\n{out}", file=sys.stderr)
            sys.exit(1)
        print(out)


if __name__ == "__main__":
    main()
