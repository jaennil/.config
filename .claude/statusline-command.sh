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
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

usage_info=""
if [ -n "$session_pct" ]; then
  usage_info=" | session: $(printf '%.0f' "$session_pct")%"
fi
if [ -n "$week_pct" ]; then
  usage_info="$usage_info | week: $(printf '%.0f' "$week_pct")%"
fi

printf "%s | %s%s%s" "$short_pwd" "$model" "$ctx_info" "$usage_info"
