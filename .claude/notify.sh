#!/bin/bash
# Claude Code notification helper
# Usage: notify.sh show|close (reads JSON from stdin)
# Left click: dismiss
# Middle click: focus tmux session

ACTION="$1"
INPUT=$(cat)

extract() {
  echo "$INPUT" | grep -oP "\"$1\"\s*:\s*\"\K[^\"]*"
}

SID=$(extract session_id)
MARKER="/tmp/claude-notify-$SID"
PID_FILE="/tmp/claude-notify-pid-$SID"

case "$ACTION" in
  show)
    MSG=$(extract message)
    CWD=$(extract cwd)
    CWD="${CWD##*/}"
    TMUX_SESSION=$(tmux display-message -p '#S' 2>/dev/null) || TMUX_SESSION=""
    TITLE="${TMUX_SESSION:-$CWD}"
    CLIENT=$(tmux list-clients -F '#{client_tty}' 2>/dev/null | head -1)

    # Kill previous listener for this session
    if [ -f "$PID_FILE" ]; then
      kill "$(cat "$PID_FILE")" 2>/dev/null
    fi

    # Send notification with action via gdbus
    NID=$(gdbus call --session \
      --dest org.freedesktop.Notifications \
      --object-path /org/freedesktop/Notifications \
      --method org.freedesktop.Notifications.Notify \
      CC 0 '' "$TITLE" "$MSG" '["focus", "Focus"]' "{'urgency': <byte 2>}" 0 \
      | grep -oP '(?<=uint32 )\d+')
    echo "$NID" > "$MARKER"

    # Listen for action in background
    (
      LAST_NID=""
      dbus-monitor --session "interface='org.freedesktop.Notifications',member='ActionInvoked'" \
        "interface='org.freedesktop.Notifications',member='NotificationClosed'" 2>/dev/null \
      | while IFS= read -r line; do
          if echo "$line" | grep -q "uint32 $NID"; then
            LAST_NID="$NID"
          fi
          if [ "$LAST_NID" = "$NID" ] && echo "$line" | grep -q "string \"focus\""; then
            [ -n "$CLIENT" ] && [ -n "$TMUX_SESSION" ] && \
              tmux switch-client -c "$CLIENT" -t "$TMUX_SESSION" 2>/dev/null
            break
          fi
          if [ "$LAST_NID" = "$NID" ] && echo "$line" | grep -q "member=NotificationClosed"; then
            break
          fi
        done
      rm -f "$MARKER" "$PID_FILE"
    ) &
    echo "$!" > "$PID_FILE"
    ;;
  close)
    [ -f "$MARKER" ] || exit 0
    NID=$(cat "$MARKER")
    if [ -f "$PID_FILE" ]; then
      kill "$(cat "$PID_FILE")" 2>/dev/null
    fi
    gdbus call --session \
      --dest org.freedesktop.Notifications \
      --object-path /org/freedesktop/Notifications \
      --method org.freedesktop.Notifications.CloseNotification \
      "$NID" >/dev/null 2>&1
    rm -f "$MARKER" "$PID_FILE"
    ;;
esac
