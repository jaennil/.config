#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ORDER_HELPER="$SCRIPT_DIR/session-order.sh"

tmux_cmd=(tmux)

if [[ -n "${TMUX_SOCKET_NAME:-}" ]]; then
    tmux_cmd+=(-L "$TMUX_SOCKET_NAME")
fi

if [[ -n "${TMUX_SOCKET_PATH:-}" ]]; then
    tmux_cmd+=(-S "$TMUX_SOCKET_PATH")
fi

tm() {
    "${tmux_cmd[@]}" "$@"
}

current_session_name() {
    tm display-message -p '#S' 2>/dev/null || true
}

current_session_position() {
    local current_session index=1 session

    current_session=$(current_session_name)

    if [[ -z "$current_session" ]]; then
        echo 1
        return
    fi

    while IFS= read -r session; do
        if [[ "$session" == "$current_session" ]]; then
            echo "$index"
            return
        fi
        index=$((index + 1))
    done < <("$ORDER_HELPER" list)

    echo 1
}

current_session_position_from_file() {
    local list_file=$1
    local current_session

    current_session=$(current_session_name)

    if [[ -z "$current_session" ]]; then
        echo 1
        return
    fi

    awk -F '\t' -v current="$current_session" '
        $2 == current { print NR; found=1; exit }
        END { if (!found) print 1 }
    ' "$list_file"
}

list_entries() {
    local session index=1 marker current_session
    local -A windows_by_session=()
    local -A clients_by_session=()

    current_session=$(current_session_name)

    while IFS=$'\t' read -r session windows clients; do
        windows_by_session["$session"]=$windows
        clients_by_session["$session"]=$clients
    done < <(tm list-sessions -F '#{session_name}'$'\t''#{session_windows}'$'\t''#{session_attached}')

    while IFS= read -r session; do
        marker=
        if [[ "$session" == "$current_session" ]]; then
            marker=current
        fi

        printf '%02d\t%s\t%s windows\t%s clients\t%s\n' \
            "$index" \
            "$session" \
            "${windows_by_session[$session]:-?}" \
            "${clients_by_session[$session]:-?}" \
            "$marker"
        index=$((index + 1))
    done < <("$ORDER_HELPER" list)
}

preview_session() {
    local session=$1

    tm display-message -p -t "$session" 'session: #{session_name}' || exit 1
    tm display-message -p -t "$session" 'windows: #{session_windows}  attached clients: #{session_attached}'
    printf '\n'
    tm list-windows -t "$session" -F '#I:#W#{?window_active, [active],} (#{window_panes} panes)'
    printf '\n'
    tm list-panes -t "$session" -F '  #I.#P #{?pane_active,[active],} #{pane_current_command}  #{pane_current_path}'
}

switch_session() {
    local session=$1
    tm switch-client -t "$session"
}

kill_session() {
    local session=$1
    local current

    current=$(tm display-message -p '#S')
    if [[ "$session" == "$current" ]]; then
        tm display-message 'Refusing to kill the current session from the picker'
        return 1
    fi

    tm kill-session -t "$session"
    "$ORDER_HELPER" sync >/dev/null
}

prompt_rename() {
    local session=$1
    local command

    printf -v command "run-shell \"%q rename %q \\\"%%\\\"\"" "$ORDER_HELPER" "$session"
    tm command-prompt -I "$session" -p 'Rename session' "$command"
}

run_fzf() {
    local input_file=$1
    local current_pos=${2:-1}

    fzf <"$input_file" \
        --ansi \
        --no-sort \
        --track \
        --layout=reverse \
        --height=100% \
        --border=none \
        --delimiter=$'\t' \
        --with-nth=1,2,3,4,5 \
        --header=$'enter switch | del kill | alt-k move up | alt-j move down | ctrl-r rename | / search | ctrl-s nav' \
        --prompt='session> ' \
        --preview="$0 preview {2}" \
        --preview-window='right,55%,border-left,wrap' \
        --bind "load:pos($current_pos)+unbind(load)" \
        --bind "j:down,k:up,g:first,G:last" \
        --bind "/:change-prompt(search> )+unbind(j,k,g,G,/)+enable-search" \
        --bind "ctrl-s:change-prompt(session> )+clear-query+disable-search+rebind(j,k,g,G,/)" \
        --bind "enter:become($0 switch {2})" \
        --bind "del:execute-silent($0 kill {2})+reload($0 list)" \
        --bind "alt-k:execute-silent($ORDER_HELPER up {2})+reload($0 list)" \
        --bind "alt-j:execute-silent($ORDER_HELPER down {2})+reload($0 list)" \
        --bind "ctrl-r:execute-silent($0 prompt-rename {2})+abort"
}

open_picker() {
    local list_file
    local current_pos

    list_file=$(mktemp "${TMPDIR:-/tmp}/tmux-session-picker.XXXXXX")
    trap 'rm -f "$list_file"' EXIT

    list_entries >"$list_file"
    current_pos=$(current_session_position_from_file "$list_file")

    run_fzf "$list_file" "$current_pos"
}

popup_picker() {
    local list_file
    local current_pos
    local command

    list_file=$(mktemp "${TMPDIR:-/tmp}/tmux-session-picker.XXXXXX")
    list_entries >"$list_file"
    current_pos=$(current_session_position_from_file "$list_file")

    printf -v command '%q open-cached %q %q' "$0" "$list_file" "$current_pos"
    tm display-popup -E -w 92% -h 88% "$command"
}

main() {
    case "${1:-open}" in
        popup)
            popup_picker
            ;;
        open)
            open_picker
            ;;
        open-cached)
            [[ $# -eq 3 ]] || {
                echo "usage: $0 open-cached <list-file> <current-pos>" >&2
                exit 1
            }
            trap 'rm -f "$2"' EXIT
            run_fzf "$2" "$3"
            ;;
        list)
            list_entries
            ;;
        preview)
            preview_session "${2:?missing session name}"
            ;;
        switch)
            switch_session "${2:?missing session name}"
            ;;
        kill)
            kill_session "${2:?missing session name}"
            ;;
        prompt-rename)
            prompt_rename "${2:?missing session name}"
            ;;
        *)
            echo "unknown subcommand: $1" >&2
            exit 1
            ;;
    esac
}

main "$@"
