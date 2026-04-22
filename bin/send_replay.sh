#!/usr/bin/env bash

set -euo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/send_replay.env"
LOG_FILE="${HOME}/send_replay.log"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG_FILE"
}

if [[ ! -f "$CONFIG_FILE" ]]; then
    log "Config file not found: $CONFIG_FILE"
    exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

TOKEN="${TELEGRAM_BOT_TOKEN:-}"
CHAT_ID="${TELEGRAM_CHAT_ID:-}"
API_BASE="${TELEGRAM_API_BASE:-http://127.0.0.1:8082}"
FILE="${1:-}"

if [[ -z "$TOKEN" || -z "$CHAT_ID" ]]; then
    log "Missing TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID in $CONFIG_FILE"
    exit 1
fi

if [[ -z "$FILE" ]]; then
    log "No file path provided"
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    log "File not found: $FILE"
    exit 1
fi

FILE_SIZE=$(stat -c '%s' "$FILE")
log "Uploading via ${API_BASE}: $FILE (${FILE_SIZE} bytes)"

response=$(
    /usr/bin/curl --silent --show-error --fail-with-body \
        -F chat_id="$CHAT_ID" \
        -F document=@"$FILE" \
        "${API_BASE}/bot$TOKEN/sendDocument"
)

if ! printf '%s\n' "$response" | grep -Eq '"ok":[[:space:]]*true'; then
    log "Upload returned non-ok response: $response"
    printf '%s\n' "$response"
    exit 1
fi

log "Upload successful: $response"

rm -f -- "$FILE"
log "Deleted local file: $FILE"

printf '%s\n' "$response"
