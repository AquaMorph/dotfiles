#!/bin/bash
# Show the remaining ChatGPT Codex rate limits for the current OpenAI login.

set -o pipefail

usage_url="${OPENAI_USAGE_URL:-https://chatgpt.com/backend-api/wham/usage}"
auth_file="${OPENAI_AUTH_FILE:-}"
output_format="text"
watch_interval=""

function usage {
  cat <<'EOF'
Usage: openai-usage [--json] [--watch [SECONDS]]

Show the remaining Codex allowance for the OpenAI account logged into OpenCode
or the Codex CLI. The default watch interval is 60 seconds.

Environment:
  OPENAI_AUTH_FILE  Override the OAuth credential file
  OPENAI_USAGE_URL  Override the ChatGPT usage endpoint
EOF
}

function fail {
  printf 'openai-usage: %s\n' "$1" >&2
  exit 1
}

function require_command {
  command -v "$1" &>/dev/null || fail "required command not found: $1"
}

function find_auth_file {
  local opencode_auth
  local codex_auth

  if [[ -n "$auth_file" ]]; then
    [[ -r "$auth_file" ]] || fail "cannot read auth file: $auth_file"
    return
  fi

  opencode_auth="${XDG_DATA_HOME:-$HOME/.local/share}/opencode/auth.json"
  codex_auth="${CODEX_HOME:-$HOME/.codex}/auth.json"

  if [[ -r "$opencode_auth" ]]; then
    auth_file="$opencode_auth"
  elif [[ -r "$codex_auth" ]]; then
    auth_file="$codex_auth"
  else
    fail "no OpenCode or Codex login found; run 'opencode auth login' first"
  fi
}

function human_duration {
  local total_seconds=$1
  local days hours minutes

  (( total_seconds < 0 )) && total_seconds=0
  days=$((total_seconds / 86400))
  hours=$(((total_seconds % 86400) / 3600))
  minutes=$(((total_seconds % 3600) / 60))

  if (( days > 0 )); then
    printf '%dd %dh' "$days" "$hours"
  elif (( hours > 0 )); then
    printf '%dh %dm' "$hours" "$minutes"
  else
    printf '%dm' "$minutes"
  fi
}

function format_reset_time {
  local reset_at=$1

  if date --date="@$reset_at" '+%a %b %-d, %-I:%M %p' 2>/dev/null; then
    return
  fi

  # BSD date fallback.
  date -r "$reset_at" '+%a %b %e, %l:%M %p' 2>/dev/null || printf '%s' "$reset_at"
}

function print_window {
  local label=$1
  local window=$2
  local used_percent reset_after reset_at remaining

  used_percent=$(jq -r '.used_percent // 0' <<<"$window")
  reset_after=$(jq -r '.reset_after_seconds // 0 | floor' <<<"$window")
  reset_at=$(jq -r '.reset_at // 0 | floor' <<<"$window")
  remaining=$(jq -nr --argjson used "$used_percent" '100 - $used | if . < 0 then 0 else . end')

  printf '%-8s %6g%% left  resets in %-8s  (%s)\n' \
    "$label:" "$remaining" "$(human_duration "$reset_after")" "$(format_reset_time "$reset_at")"
}

function fetch_usage {
  local access_token account_id raw_response status body

  access_token=$(jq -r \
    '.openai.access // .tokens.access_token // .access_token // empty' \
    "$auth_file") || fail "invalid JSON in auth file: $auth_file"
  account_id=$(jq -r \
    '.openai.accountId // .tokens.account_id // .account_id // empty' \
    "$auth_file") || fail "invalid JSON in auth file: $auth_file"

  [[ -n "$access_token" ]] || fail "no OpenAI OAuth token found in $auth_file"

  raw_response=$(curl --silent --show-error \
    --header "Authorization: Bearer $access_token" \
    --header "ChatGPT-Account-Id: $account_id" \
    --header 'Accept: application/json' \
    --write-out $'\n%{http_code}' \
    "$usage_url") || fail "could not contact OpenAI"

  status=${raw_response##*$'\n'}
  body=${raw_response%$'\n'*}

  case "$status" in
    200) ;;
    401|403) fail "OpenAI login expired; run 'opencode auth login' again" ;;
    *) fail "OpenAI returned HTTP $status" ;;
  esac

  jq -e '.rate_limit' <<<"$body" >/dev/null || fail "unexpected response from OpenAI"
  printf '%s\n' "$body"
}

function print_usage {
  local response=$1
  local plan primary secondary

  if [[ "$output_format" == "json" ]]; then
    jq '{
      plan: .plan_type,
      allowed: .rate_limit.allowed,
      limit_reached: .rate_limit.limit_reached,
      five_hour: (.rate_limit.primary_window | . + {
        remaining_percent: ([100 - .used_percent, 0] | max)
      }),
      weekly: (.rate_limit.secondary_window | . + {
        remaining_percent: ([100 - .used_percent, 0] | max)
      })
    }' <<<"$response"
    return
  fi

  plan=$(jq -r '.plan_type // "unknown"' <<<"$response")
  primary=$(jq -c '.rate_limit.primary_window' <<<"$response")
  secondary=$(jq -c '.rate_limit.secondary_window' <<<"$response")

  printf 'OpenAI Codex usage (%s)\n' "$plan"
  print_window '5-hour' "$primary"
  print_window 'Weekly' "$secondary"
}

while (( $# > 0 )); do
  case "$1" in
    --json)
      output_format="json"
      shift
      ;;
    --watch)
      watch_interval=60
      if [[ ${2:-} =~ ^[1-9][0-9]*$ ]]; then
        watch_interval=$2
        shift
      fi
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      fail "unknown argument: $1"
      ;;
  esac
done

require_command curl
require_command jq
find_auth_file

while true; do
  response=$(fetch_usage)
  print_usage "$response"

  [[ -n "$watch_interval" ]] || break
  sleep "$watch_interval"
done
