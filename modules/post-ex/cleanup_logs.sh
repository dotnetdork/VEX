#!/usr/bin/env bash
# post-ex/cleanup_logs.sh — Artefact and log cleanup helper.
#
# Removes common evidence artefacts from a compromised Linux host.
# WARNING: For authorised penetration testing only.
#
# Usage:
#   vex post-ex cleanup_logs [-n] [-v]

set -euo pipefail

source "$(dirname "$0")/../../lib/utils.sh"

# Windows is not supported for log cleanup (no concept of /var/log)
if is_windows; then
  die "cleanup_logs is not supported on Windows. Use WSL to target a Linux environment."
fi

DRY_RUN=false
VERBOSE=false

usage() {
  cat <<EOF
Usage: vex post-ex cleanup_logs [options]

Options:
  -n, --dry-run   Show what would be removed without deleting
  -v, --verbose   Verbose output
  -h, --help      Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=true;  shift ;;
    -v|--verbose) VERBOSE=true;  shift ;;
    -h|--help)    usage; exit 0 ;;
    *) warn "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# Platform-specific target paths
if is_linux; then
  TARGETS=(
    /var/log/auth.log
    /var/log/syslog
    /var/log/messages
    /var/log/secure
    /var/log/wtmp
    /var/log/btmp
    /root/.bash_history
    /home/*/.bash_history
  )
elif is_macos; then
  info "macOS detected — using macOS log paths."
  TARGETS=(
    /var/log/system.log
    /var/log/install.log
    /private/var/log/asl/*.asl
    /root/.bash_history
    /Users/*/.bash_history
    /Users/*/.zsh_history
  )
fi

info "Starting log cleanup (dry-run: ${DRY_RUN})…"

for target in "${TARGETS[@]}"; do
  # Expand globs
  for f in $target; do
    [[ -f "$f" ]] || continue
    if $VERBOSE; then info "Target: ${f}"; fi
    if $DRY_RUN; then
      echo "  [dry-run] Would truncate: ${f}"
    else
      truncate -s 0 "$f" 2>/dev/null || warn "Could not truncate: ${f}"
    fi
  done
done

success "Cleanup complete."
