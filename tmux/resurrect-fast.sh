#!/usr/bin/env bash
# Batched restore for tmux-resurrect.
#
# The plugin's restore.sh spawns a separate tmux client for every step: ~5 per
# pane (exists checks, create, title) and 3 per window (layout, rename,
# automatic-rename), plus a switch-client dance per window at the end. With 200+
# sessions that is a few thousand process round trips at ~3.4ms each.
#
# This does the same work, but hands the commands to the server in batches of
# argv-separated commands, so the cost collapses to a handful of round trips.
# Saved state is read-only here; nothing is written back.
#
#   RESURRECT_FILE=<path>   restore a specific save file (default: .../last)
#   RESTORE_TMUX="tmux -L x" talk to another server (used by the benchmark)
#   RESTORE_BATCH=<n>       commands per tmux invocation (default 200)
#   RESTORE_PROCESSES=0|1   relaunch pane processes (default: plugin's setting)

set -uo pipefail

RESURRECT_DIR="${HOME}/.local/share/tmux/resurrect"
FILE="${RESURRECT_FILE:-$(readlink -f "$RESURRECT_DIR/last" 2>/dev/null)}"
BATCH="${RESTORE_BATCH:-200}"

read -ra TMUX_BIN <<< "${RESTORE_TMUX:-tmux}"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "resurrect-fast: no saved session at ${FILE:-$RESURRECT_DIR/last}" >&2
    exit 1
fi

# ---------------------------------------------------------------- batching ---

cmds=()
batches=0
failed=0

flush() {
    (( ${#cmds[@]} )) || return 0
    if ! "${TMUX_BIN[@]}" "${cmds[@]}" 2>/dev/null; then
        # A failing command aborts the rest of its batch, so replay it one by
        # one: a single bad window target must not cost us the other 199.
        local single=()
        for arg in "${cmds[@]}"; do
            if [ "$arg" = ";" ]; then
                (( ${#single[@]} )) && { "${TMUX_BIN[@]}" "${single[@]}" 2>/dev/null || ((failed++)); }
                single=()
            else
                single+=("$arg")
            fi
        done
        (( ${#single[@]} )) && { "${TMUX_BIN[@]}" "${single[@]}" 2>/dev/null || ((failed++)); }
    fi
    ((batches++))
    cmds=()
}

add() {
    (( ${#cmds[@]} )) && cmds+=(";")
    cmds+=("$@")
    (( ${#cmds[@]} >= BATCH )) && flush
}

strip_colon() { printf '%s' "${1#:}"; }

# ------------------------------------------------------ sessions and panes ---

declare -A session_seen=() window_seen=()
first_session=""
panes=0 windows=0 sessions=0

while IFS=$'\t' read -r type session window win_active win_flags pane_index \
                       pane_title dir pane_active pane_command pane_full; do
    [ "$type" = "pane" ] || continue

    dir="$(strip_colon "$dir")"
    dir="${dir/#\~/$HOME}"
    [ -d "$dir" ] || dir="$HOME"
    wkey="$session:$window"

    if [ -z "${session_seen[$session]:-}" ]; then
        add new-session -d -s "$session" -c "$dir"
        session_seen[$session]=1
        [ -n "$first_session" ] || first_session="$session"
        window_seen[$wkey]=1
        # new-session lands on base-index; move it if the save says otherwise
        [ "$window" != "1" ] && add move-window -s "$session:1" -t "$session:$window"
        ((sessions++, windows++))
    elif [ -z "${window_seen[$wkey]:-}" ]; then
        add new-window -d -t "$wkey" -c "$dir"
        window_seen[$wkey]=1
        ((windows++))
    else
        add split-window -t "$wkey" -c "$dir"
        add resize-pane -t "$wkey" -U 999   # shrink so more panes fit
    fi

    [ "$pane_title" != "~" ] && add select-pane -t "$wkey.$pane_index" -T "$pane_title"
    ((panes++))
done < <(grep '^pane' "$FILE")

# ---------------------------------------------------- layout, names, flags ---

while IFS=$'\t' read -r type session window wname win_active win_flags layout autorename; do
    [ "$type" = "window" ] || continue
    add select-layout -t "$session:$window" "$layout"
    add rename-window -t "$session:$window" "$(strip_colon "$wname")"
    if [ "$autorename" = ":" ]; then
        add set-option -u -t "$session:$window" automatic-rename
    else
        add set-option -t "$session:$window" automatic-rename "$(strip_colon "$autorename")"
    fi
done < <(grep '^window' "$FILE")

# --------------------------------------------- active pane / window / zoom ---

# The plugin switch-clients to each window before selecting its pane; a fully
# qualified target does the same without dragging the client around.
while IFS=$'\t' read -r session window pane flags; do
    add select-pane -t "$session:$window.$pane"
    [[ "$flags" == *Z* ]] && add resize-pane -t "$session:$window" -Z
done < <(awk 'BEGIN{FS=OFS="\t"} /^pane/ && $9 == 1 { print $2, $3, $6, $5 }' "$FILE")

while IFS=$'\t' read -r session window; do
    add select-window -t "$session:$window"
done < <(awk 'BEGIN{FS=OFS="\t"} /^window/ && $6 ~ /\*/ { print $2, $3 }' "$FILE" | sort -u)

flush

# ------------------------------------------------------------- processes ----

restore_processes() {
    local enabled="${RESTORE_PROCESSES:-}"
    if [ -z "$enabled" ]; then
        local opt
        opt="$("${TMUX_BIN[@]}" show-option -gqv @resurrect-processes 2>/dev/null)"
        [ "$opt" = "false" ] && return 0
        enabled=1
    fi
    [ "$enabled" = "0" ] && return 0

    local default_programs="vi vim nvim emacs man less more tail top htop irssi weechat mutt"
    local programs="$default_programs"
    local opt
    opt="$("${TMUX_BIN[@]}" show-option -gqv @resurrect-processes 2>/dev/null)"
    case "$opt" in
        ""|"false") ;;
        "~"*) programs="$default_programs ${opt#\~}" ;;
        *) programs="$opt" ;;
    esac

    while IFS=$'\t' read -r session window pane dir full; do
        full="$(strip_colon "$full")"
        dir="$(strip_colon "$dir")"
        local first="${full%% *}"
        first="${first##*/}"
        [[ " $programs " == *" $first "* ]] || continue
        add send-keys -t "$session:$window.$pane" "cd '${dir//\'/\'\\\'\'}'; $full" C-m
    done < <(awk 'BEGIN{FS=OFS="\t"} /^pane/ && $11 !~ "^:$" { print $2, $3, $6, $8, $11 }' "$FILE")
    flush
}

restore_processes

# Restore the invoking client's saved session before removing the temporary
# session created by a fresh tmux server.
while IFS=$'\t' read -r type client_session client_last; do
    [ "$type" = "state" ] || continue
    "${TMUX_BIN[@]}" switch-client -t "$client_last" 2>/dev/null
    "${TMUX_BIN[@]}" switch-client -t "$client_session" 2>/dev/null
done < <(grep '^state' "$FILE")

# The server creates session "0" for us when it starts empty; drop it unless it
# was part of the save. Explicitly move any clients still attached to it first;
# killing an attached session would terminate the user's tmux client.
if [ -z "${session_seen[0]:-}" ] && [ -n "$first_session" ] && \
   "${TMUX_BIN[@]}" has-session -t "=0" 2>/dev/null; then
    while IFS=$'\t' read -r client client_session; do
        [ "$client_session" = "0" ] || continue
        "${TMUX_BIN[@]}" switch-client -c "$client" -t "=$first_session" 2>/dev/null
    done < <("${TMUX_BIN[@]}" list-clients -F $'#{client_name}\t#{session_name}' 2>/dev/null)

    if ! "${TMUX_BIN[@]}" list-clients -F '#{session_name}' 2>/dev/null | grep -qx '0'; then
        "${TMUX_BIN[@]}" kill-session -t "=0" 2>/dev/null
    fi
fi
