#!/usr/bin/env bash
# network/port_scan.sh — Lightweight port scanner wrapper around nmap.
#
# Usage:
#   vex network port_scan <target> [-p <ports>] [-o <output_prefix>]

set -euo pipefail

source "$(dirname "$0")/../../lib/utils.sh"

usage() {
  cat <<EOF
Usage: vex network port_scan <target> [options]

Options:
  -p, --ports <range>     Port range (default: 1-1024)
  -o, --output <prefix>   Output file prefix (results saved to loot/)
  -h, --help              Show this help
EOF
}

TARGET=""
PORTS="1-1024"
OUTPUT_PREFIX=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--ports)   PORTS="$2";         shift 2 ;;
    -o|--output)  OUTPUT_PREFIX="$2"; shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    -*)           warn "Unknown option: $1"; usage; exit 1 ;;
    *)            TARGET="$1";        shift ;;
  esac
done

[[ -z "$TARGET" ]] && { usage; exit 1; }

require_tools nmap

info "Scanning ${TARGET} (ports ${PORTS})…"

NMAP_ARGS=(-sV -p "${PORTS}" --open "${TARGET}")

if [[ -n "$OUTPUT_PREFIX" ]]; then
  OUT_DIR="$(loot_dir "port_scan")"
  NMAP_ARGS+=(-oA "${OUT_DIR}/${OUTPUT_PREFIX}")
  info "Output prefix: ${OUT_DIR}/${OUTPUT_PREFIX}"
fi

nmap "${NMAP_ARGS[@]}"
success "Scan complete."
