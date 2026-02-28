#!/usr/bin/env bash
# lib/utils.sh — Shared helper functions for V.E.X. modules
# Source this file at the top of any module script:
#   source "$(dirname "$0")/../../lib/utils.sh"

# ---------------------------------------------------------------------------
# Colour codes (disabled automatically when not a TTY)
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
info()    { printf "${CYAN}[*]${RESET} %s\n"  "$*"; }
success() { printf "${GREEN}[+]${RESET} %s\n" "$*"; }
warn()    { printf "${YELLOW}[!]${RESET} %s\n" "$*" >&2; }
error()   { printf "${RED}[-]${RESET} %s\n"  "$*" >&2; }
die()     { error "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Dependency check — verify required tools are present
# Usage: require_tools nmap python3 curl
# ---------------------------------------------------------------------------
require_tools() {
  local missing=()
  for tool in "$@"; do
    command -v "$tool" &>/dev/null || missing+=("$tool")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    die "Missing required tool(s): ${missing[*]}"
  fi
}

# ---------------------------------------------------------------------------
# Root / privilege check
# ---------------------------------------------------------------------------
require_root() {
  [[ $EUID -eq 0 ]] || die "This module must be run as root."
}

# ---------------------------------------------------------------------------
# Loot directory helper — returns (and creates) a timestamped results path
# Usage: output_dir=$(loot_dir "module_name")
# ---------------------------------------------------------------------------
loot_dir() {
  local name="${1:-output}"
  local base
  base="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local dir="${base}/loot/${name}_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$dir"
  echo "$dir"
}
