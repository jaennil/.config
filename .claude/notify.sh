#!/bin/bash
# Claude Code notification helper
# Usage: notify.sh show|close (reads JSON from stdin)
# Left click: dismiss
# Middle click: focus tmux session
# Right click: context menu (snooze 5s)

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
      "interface='org.freedesktop.Notifications',member='ActionInvoked'" 2>/dev/null \
    | while IFS= read -r line; do
        if echo "$line" | grep -q "member=ActionInvoked"; then
          read -r id_line
          FIRED_NID=$(echo "$id_line" | grep -oP '(?<=uint32 )\d+')
          read -r action_line
          MAP="/tmp/claude-notify-nid-$FIRED_NID"
          [ -f "$MAP" ] || continue
          INFO=$(cat "$MAP")
          TMUX_SESSION=$(echo "$INFO" | cut -d: -f1)
          CLIENT=$(echo "$INFO" | cut -d: -f2)
          NOTIFY_SID=$(echo "$INFO" | cut -d: -f3)

          if echo "$action_line" | grep -q "string \"default\""; then
            [ -n "$CLIENT" ] && [ -n "$TMUX_SESSION" ] && \
              tmux switch-client -c "$CLIENT" -t "$TMUX_SESSION" 2>/dev/null

          elif echo "$action_line" | grep -q "string \"snooze\""; then
            # Close current notification
            gdbus call --session \
              --dest org.freedesktop.Notifications \
              --object-path /org/freedesktop/Notifications \
              --method org.freedesktop.Notifications.CloseNotification \
              "$FIRED_NID" >/dev/null 2>&1
            rm -f "$MAP"
            # Re-create after 5s
            (
              sleep 5
              NEW_NID=$(gdbus call --session \
                --dest org.freedesktop.Notifications \
                --object-path /org/freedesktop/Notifications \
                --method org.freedesktop.Notifications.Notify \
                CC 0 '' "$TMUX_SESSION" "snoozed — needs attention" \
                '["default", "Focus", "snooze", "Snooze 5s"]' "{'urgency': <byte 2>}" 0 \
                | grep -oP '(?<=uint32 )\d+')
              echo "$TMUX_SESSION:$CLIENT:$NOTIFY_SID" > "/tmp/claude-notify-nid-$NEW_NID"
              [ -n "$NOTIFY_SID" ] && echo "$NEW_NID" > "/tmp/claude-notify-$NOTIFY_SID"
            ) &
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
      CC 0 '' "$TITLE" "$MSG" '["default", "Focus", "snooze", "Snooze 5s"]' "{'urgency': <byte 2>}" 0 \
      | grep -oP '(?<=uint32 )\d+')

    echo "$NID" > "$MARKER"
    echo "$TMUX_SESSION:$CLIENT:$SID" > "/tmp/claude-notify-nid-$NID"

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
