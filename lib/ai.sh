#!/usr/bin/env bash
# lib/ai.sh — AI-Assist integration stub for V.E.X.
#
# When VEX_AI_KEY is set, calls the configured LLM endpoint with the
# script context. Extend this file with a real provider implementation.
#
# Supported environment variables:
#   VEX_AI_KEY      — API key for the LLM provider
#   VEX_AI_ENDPOINT — Full API endpoint URL (default: OpenAI-compatible)
#   VEX_AI_MODEL    — Model name (default: gpt-4o)

VEX_AI_ENDPOINT="${VEX_AI_ENDPOINT:-https://api.openai.com/v1/chat/completions}"
VEX_AI_MODEL="${VEX_AI_MODEL:-gpt-4o}"

# Source shared helpers for require_tools, logging, etc.
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${_LIB_DIR}/utils.sh" ]] && source "${_LIB_DIR}/utils.sh"

# ---------------------------------------------------------------------------
# ai_query <prompt>
#   Posts <prompt> to the configured LLM and prints the response.
#   Returns 1 (gracefully) if VEX_AI_KEY is not set.
# ---------------------------------------------------------------------------
ai_query() {
  local prompt="$1"

  if [[ -z "${VEX_AI_KEY:-}" ]]; then
    echo "[AI] VEX_AI_KEY is not set — skipping live AI query." >&2
    return 1
  fi

  require_tools curl jq

  local payload
  payload="$(jq -n \
    --arg model  "$VEX_AI_MODEL" \
    --arg prompt "$prompt" \
    '{model: $model, messages: [{role: "user", content: $prompt}]}')"

  curl -fsSL \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${VEX_AI_KEY}" \
    -d "$payload" \
    "${VEX_AI_ENDPOINT}" \
    | jq -r '.choices[0].message.content // "No response."'
}
