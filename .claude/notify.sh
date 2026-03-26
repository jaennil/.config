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
LISTENER_PID_FILE="/tmp/claude-notify-listener.pid"

start_listener() {
  [ -f "$LISTENER_PID_FILE" ] && kill -0 "$(cat "$LISTENER_PID_FILE")" 2>/dev/null && return

  (
    dbus-monitor --session \
      "interface='org.freedesktop.Notifications',member='ActionInvoked'" \
      "interface='org.freedesktop.Notifications',member='NotificationClosed'" 2>/dev/null \
    | while IFS= read -r line; do
        if echo "$line" | grep -q "member=ActionInvoked"; then
          read -r id_line
          FIRED_NID=$(echo "$id_line" | grep -oP '(?<=uint32 )\d+')
          read -r action_line
          if echo "$action_line" | grep -q "string \"focus\""; then
            MAP="/tmp/claude-notify-nid-$FIRED_NID"
            if [ -f "$MAP" ]; then
              TMUX_SESSION=$(cut -d: -f1 < "$MAP")
              CLIENT=$(cut -d: -f2 < "$MAP")
              [ -n "$CLIENT" ] && [ -n "$TMUX_SESSION" ] && \
                tmux switch-client -c "$CLIENT" -t "$TMUX_SESSION" 2>/dev/null
            fi
          fi
        fi
      done
  ) &
  echo "$!" > "$LISTENER_PID_FILE"
}

case "$ACTION" in
  show)
    MSG=$(extract message)
    CWD=$(extract cwd)
    CWD="${CWD##*/}"
    TMUX_SESSION=$(tmux display-message -p '#S' 2>/dev/null) || TMUX_SESSION=""
    TITLE="${TMUX_SESSION:-$CWD}"
    CLIENT=$(tmux list-clients -F '#{client_tty}' 2>/dev/null | head -1)

    # Close previous notification for this session
    if [ -f "$MARKER" ]; then
      OLD_NID=$(cat "$MARKER")
      rm -f "$MARKER" "/tmp/claude-notify-nid-$OLD_NID"
      gdbus call --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.CloseNotification \
        "$OLD_NID" >/dev/null 2>&1
    fi

    NID=$(gdbus call --session \
      --dest org.freedesktop.Notifications \
      --object-path /org/freedesktop/Notifications \
      --method org.freedesktop.Notifications.Notify \
      CC 0 '' "$TITLE" "$MSG" '["focus", "Focus"]' "{'urgency': <byte 2>}" 0 \
      | grep -oP '(?<=uint32 )\d+')

    echo "$NID" > "$MARKER"
    echo "$TMUX_SESSION:$CLIENT" > "/tmp/claude-notify-nid-$NID"

    start_listener
    ;;
  close)
    [ -f "$MARKER" ] || exit 0
    NID=$(cat "$MARKER")
    rm -f "$MARKER" "/tmp/claude-notify-nid-$NID"
    gdbus call --session \
      --dest org.freedesktop.Notifications \
      --object-path /org/freedesktop/Notifications \
      --method org.freedesktop.Notifications.CloseNotification \
      "$NID" >/dev/null 2>&1
    ;;
esac
