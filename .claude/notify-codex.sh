#!/bin/bash
# Codex notification helper
# Receives JSON payload from codex via stdin
# Reuses the same notification system as Claude Code

INPUT=$(cat)

# Extract fields from codex JSON
CWD=$(echo "$INPUT" | grep -oP '"cwd"\s*:\s*"\K[^"]*')
CWD="${CWD##*/}"
TMUX_SESSION=$(tmux display-message -p '#S' 2>/dev/null) || TMUX_SESSION=""
TITLE="${TMUX_SESSION:-$CWD}"
CLIENT=$(tmux list-clients -F '#{client_tty}' 2>/dev/null | head -1)

# Use a codex-specific marker
SESSION_ID=$(echo "$INPUT" | grep -oP '"session_id"\s*:\s*"\K[^"]*')
[ -z "$SESSION_ID" ] && SESSION_ID="codex-$$"
MARKER="/tmp/claude-notify-$SESSION_ID"
LISTENER_PID_FILE="/tmp/claude-notify-listener.pid"

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
  CC 0 '' "$TITLE" "Codex needs attention" \
  '["default", "Focus", "snooze", "Snooze 5s"]' "{'urgency': <byte 2>}" 0 \
  | grep -oP '(?<=uint32 )\d+')

echo "$NID" > "$MARKER"
echo "$TMUX_SESSION:$CLIENT:$SESSION_ID" > "/tmp/claude-notify-nid-$NID"

# Start shared listener if not running (same as Claude Code)
if ! [ -f "$LISTENER_PID_FILE" ] || ! kill -0 "$(cat "$LISTENER_PID_FILE")" 2>/dev/null; then
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
          T_SESSION=$(echo "$INFO" | cut -d: -f1)
          T_CLIENT=$(echo "$INFO" | cut -d: -f2)
          NOTIFY_SID=$(echo "$INFO" | cut -d: -f3)

          if echo "$action_line" | grep -q "string \"default\""; then
            [ -n "$T_CLIENT" ] && [ -n "$T_SESSION" ] && \
              tmux switch-client -c "$T_CLIENT" -t "$T_SESSION" 2>/dev/null
          elif echo "$action_line" | grep -q "string \"snooze\""; then
            gdbus call --session \
              --dest org.freedesktop.Notifications \
              --object-path /org/freedesktop/Notifications \
              --method org.freedesktop.Notifications.CloseNotification \
              "$FIRED_NID" >/dev/null 2>&1
            rm -f "$MAP"
            (
              sleep 5
              NEW_NID=$(gdbus call --session \
                --dest org.freedesktop.Notifications \
                --object-path /org/freedesktop/Notifications \
                --method org.freedesktop.Notifications.Notify \
                CC 0 '' "$T_SESSION" "snoozed — needs attention" \
                '["default", "Focus", "snooze", "Snooze 5s"]' "{'urgency': <byte 2>}" 0 \
                | grep -oP '(?<=uint32 )\d+')
              [ -n "$NOTIFY_SID" ] && echo "$NEW_NID" > "/tmp/claude-notify-$NOTIFY_SID"
              echo "$T_SESSION:$T_CLIENT:$NOTIFY_SID" > "/tmp/claude-notify-nid-$NEW_NID"
            ) &
          fi
        fi
      done
  ) &
  echo "$!" > "$LISTENER_PID_FILE"
fi
