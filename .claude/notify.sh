#!/bin/bash
# Claude Code notification helper
# Usage: notify.sh show|close (reads JSON from stdin)

ACTION="$1"
INPUT=$(cat)

extract() {
  echo "$INPUT" | grep -oP "\"$1\"\s*:\s*\"\K[^\"]*"
}

SID=$(extract session_id)

case "$ACTION" in
  show)
    MSG=$(extract message)
    CWD=$(extract cwd)
    CWD="${CWD##*/}"
    TITLE=$(tmux display-message -p '#S' 2>/dev/null) || TITLE="$CWD"
    NID=$(gdbus call --session \
      --dest org.freedesktop.Notifications \
      --object-path /org/freedesktop/Notifications \
      --method org.freedesktop.Notifications.Notify \
      CC 0 '' "$TITLE" "$MSG" '[]' "{'urgency': <byte 2>}" 0 \
      | grep -oP '(?<=uint32 )\d+')
    echo "$NID" > "/tmp/claude-notify-$SID"
    ;;
  close)
    MARKER="/tmp/claude-notify-$SID"
    [ -f "$MARKER" ] || exit 0
    NID=$(cat "$MARKER")
    rm -f "$MARKER"
    gdbus call --session \
      --dest org.freedesktop.Notifications \
      --object-path /org/freedesktop/Notifications \
      --method org.freedesktop.Notifications.CloseNotification \
      "$NID" >/dev/null 2>&1
    ;;
esac
