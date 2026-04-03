#!/usr/bin/env bash
input=$(cat)

# Fish-style path shortening: abbreviate each parent dir to its first letter,
# show the last component in full, and replace $HOME prefix with ~
fish_pwd() {
  local cwd="$1"
  local home="$HOME"

  # Replace home prefix with ~
  if [[ "$cwd" == "$home" ]]; then
    echo "~"
    return
  fi
  if [[ "$cwd" == "$home/"* ]]; then
    cwd="~${cwd#$home}"
  fi

  # Split path into components
  local IFS='/'
  read -ra parts <<< "$cwd"

  local result=""
  local count=${#parts[@]}

  for (( i = 0; i < count - 1; i++ )); do
    local part="${parts[$i]}"
    if [ -z "$part" ]; then
      # Root slash
      result="/"
    elif [[ "$part" == "~" ]]; then
      result="~"
    else
      # Abbreviate to first character
      result="${result}/${part:0:1}"
    fi
  done

  # Append last component in full
  local last="${parts[$((count-1))]}"
  if [ -z "$result" ]; then
    result="/$last"
  elif [[ "$result" == "/" ]]; then
    result="/$last"
  else
    result="${result}/${last}"
  fi

  echo "$result"
}

cwd=$(echo "$input" | jq -r '.cwd')
short_pwd=$(fish_pwd "$cwd")

model=$(echo "$input" | jq -r '.model.display_name')

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  ctx_info=" | ctx: $(printf '%.0f' "$used")%"
else
  ctx_info=""
fi

session_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
session_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# ANSI colors
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
RESET=$'\033[0m'

usage_info=""
if [ -n "$session_pct" ] && [ -n "$session_resets_at" ]; then
  now=$(date +%s)

  # Window start = resets_at - 5 hours
  window_start=$(( session_resets_at - 5 * 3600 ))
  elapsed_seconds=$(( now - window_start ))

  # Clamp elapsed to [0, 5h]
  if [ "$elapsed_seconds" -lt 0 ]; then
    elapsed_seconds=0
  fi
  if [ "$elapsed_seconds" -gt 18000 ]; then
    elapsed_seconds=18000
  fi

  # Expected usage: 20% per hour = 20/3600 per second
  expected_pct=$(echo "$elapsed_seconds" | awk '{printf "%.1f", $1 * 20 / 3600}')

  # Compare actual vs expected to pick color
  diff_val=$(awk -v actual="$session_pct" -v expected="$expected_pct" 'BEGIN { print actual - expected }')
  if awk -v d="$diff_val" 'BEGIN { exit !(d <= 5) }'; then
    color="$GREEN"
  elif awk -v d="$diff_val" 'BEGIN { exit !(d <= 15) }'; then
    color="$YELLOW"
  else
    color="$RED"
  fi

  resets_time=$(date -d "@$session_resets_at" +%H:%M 2>/dev/null || date -r "$session_resets_at" +%H:%M)

  usage_info=" | ${color}session: $(printf '%.0f' "$session_pct")%${RESET} (resets $resets_time)"
fi

printf "%s | %s%s%s\n" "$short_pwd" "$model" "$ctx_info" "$usage_info"
