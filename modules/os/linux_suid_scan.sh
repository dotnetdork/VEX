#!/usr/bin/env bash
# os/linux_suid_scan.sh — Scan for SUID/SGID binaries on the local system.
#
# Usage:
#   vex os linux_suid_scan [-o <output_file>]

set -euo pipefail

source "$(dirname "$0")/../../lib/utils.sh"

OUTPUT_FILE=""

usage() {
  cat <<EOF
Usage: vex os linux_suid_scan [options]

Options:
  -o, --output <file>   Write results to file
  -h, --help            Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    *) warn "Unknown option: $1"; usage; exit 1 ;;
  esac
done

info "Scanning for SUID/SGID binaries…"

RESULTS="$(find / -xdev \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null | sort)"

if [[ -z "$RESULTS" ]]; then
  warn "No SUID/SGID binaries found (or insufficient permissions)."
else
  echo "$RESULTS"
  COUNT="$(echo "$RESULTS" | wc -l)"
  if [[ "$COUNT" -eq 1 ]]; then
    success "Found 1 SUID/SGID binary."
  else
    success "Found ${COUNT} SUID/SGID binaries."
  fi
  if [[ -n "$OUTPUT_FILE" ]]; then
    echo "$RESULTS" > "$OUTPUT_FILE"
    info "Results saved to ${OUTPUT_FILE}"
  fi
fi
