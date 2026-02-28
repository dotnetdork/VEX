#!/usr/bin/env bash
# mobile/apk_decompile.sh — Decompile an APK using apktool and jadx.
#
# Usage:
#   vex mobile apk_decompile <apk_file> [-o <output_dir>]

set -euo pipefail

source "$(dirname "$0")/../../lib/utils.sh"

APK_FILE=""
OUTPUT_DIR=""

usage() {
  cat <<EOF
Usage: vex mobile apk_decompile <apk_file> [options]

Options:
  -o, --output <dir>   Output directory (default: loot/apk_decompile_<timestamp>)
  -h, --help           Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    -*)          warn "Unknown option: $1"; usage; exit 1 ;;
    *)           APK_FILE="$1"; shift ;;
  esac
done

[[ -z "$APK_FILE" ]] && { usage; exit 1; }
[[ -f "$APK_FILE" ]] || die "APK not found: ${APK_FILE}"

require_tools apktool

[[ -z "$OUTPUT_DIR" ]] && OUTPUT_DIR="$(loot_dir "apk_decompile")"

info "Decompiling ${APK_FILE} → ${OUTPUT_DIR}…"
apktool d -o "${OUTPUT_DIR}/apktool" "$APK_FILE"
success "apktool output: ${OUTPUT_DIR}/apktool"

if command -v jadx &>/dev/null; then
  info "Running jadx for Java source recovery…"
  jadx -d "${OUTPUT_DIR}/jadx" "$APK_FILE"
  success "jadx output: ${OUTPUT_DIR}/jadx"
else
  warn "jadx not found — skipping Java decompilation (install from https://github.com/skylot/jadx)."
fi
