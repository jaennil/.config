#!/usr/bin/env bash

set -euo pipefail

tmux_cmd=(tmux)

if [[ -n "${TMUX_SOCKET_NAME:-}" ]]; then
    tmux_cmd+=(-L "$TMUX_SOCKET_NAME")
fi

if [[ -n "${TMUX_SOCKET_PATH:-}" ]]; then
    tmux_cmd+=(-S "$TMUX_SOCKET_PATH")
fi

ORDER_FILE="${TMUX_SESSION_ORDER_FILE:-$HOME/.config/tmux/session-order}"

tm() {
    "${tmux_cmd[@]}" "$@"
}

usage() {
    cat <<'EOF' >&2
usage:
  session-order.sh sync
  session-order.sh list
  session-order.sh up [session-name]
  session-order.sh down [session-name]
  session-order.sh rename <old-name> <new-name>

Examples:
  session-order.sh sync
  session-order.sh list
  session-order.sh up
  session-order.sh down config
  session-order.sh rename config dotfiles
EOF
    exit 1
}

display_notice() {
    local message=$1

    if [[ -n "${TMUX:-}" ]]; then
        tm display-message -- "$message"
    else
        printf '%s\n' "$message"
    fi
}

require_sessions() {
    if ! tm list-sessions >/dev/null 2>&1; then
        echo "tmux server is not running" >&2
        exit 1
    fi
}

sorted_sessions() {
    tm list-sessions -F '#{session_name}' | sort
}

contains_name() {
    local needle=$1
    shift
    local item

    for item in "$@"; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done

    return 1
}

write_order() {
    local sessions=("$@")
    local dir

    dir=$(dirname -- "$ORDER_FILE")
    mkdir -p "$dir"
    printf '%s\n' "${sessions[@]}" >"$ORDER_FILE"
}

sync_order() {
    local sessions=()
    local ordered=()
    local line

    mapfile -t sessions < <(sorted_sessions)

    if (( ${#sessions[@]} == 0 )); then
        echo "no tmux sessions found" >&2
        exit 1
    fi

    if [[ -f "$ORDER_FILE" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue

            if contains_name "$line" "${sessions[@]}" && ! contains_name "$line" "${ordered[@]:-}"; then
                ordered+=("$line")
            fi
        done <"$ORDER_FILE"
    fi

    for line in "${sessions[@]}"; do
        if ! contains_name "$line" "${ordered[@]:-}"; then
            ordered+=("$line")
        fi
    done

    write_order "${ordered[@]}"
}

ordered_sessions() {
    sync_order
    cat "$ORDER_FILE"
}

resolve_target() {
    local target=${1:-}
    local resolved_target

    if [[ -n "$target" ]]; then
        resolved_target=$(tm display-message -p -t "$target" '#{session_name}' 2>/dev/null || true)
        if [[ -n "$resolved_target" ]]; then
            printf '%s\n' "$resolved_target"
        else
            printf '%s\n' "$target"
        fi
        return
    fi

    if [[ -z "${TMUX:-}" ]]; then
        echo "session name is required when running outside tmux" >&2
        exit 1
    fi

    tm display-message -p '#S'
}

move_session() {
    local direction=$1
    local target
    local sessions=()
    local index target_index other_index

    target=$(resolve_target "${2:-}")
    mapfile -t sessions < <(ordered_sessions)

    target_index=-1
    for index in "${!sessions[@]}"; do
        if [[ "${sessions[$index]}" == "$target" ]]; then
            target_index=$index
            break
        fi
    done

    if (( target_index < 0 )); then
        echo "session not found: $target" >&2
        exit 1
    fi

    case "$direction" in
        up)
            if (( target_index == 0 )); then
                display_notice "Session is already first"
                return
            fi
            other_index=$((target_index - 1))
            ;;
        down)
            if (( target_index == ${#sessions[@]} - 1 )); then
                display_notice "Session is already last"
                return
            fi
            other_index=$((target_index + 1))
            ;;
        *)
            usage
            ;;
    esac

    sessions[$target_index]="${sessions[$other_index]}"
    sessions[$other_index]="$target"
    write_order "${sessions[@]}"
    display_notice "Moved $target $direction"
}

rename_session() {
    local old_name=$1
    local new_name=$2
    local sessions=()
    local index found=0

    if [[ -z "$new_name" ]]; then
        echo "new session name must not be empty" >&2
        exit 1
    fi

    mapfile -t sessions < <(ordered_sessions)

    tm rename-session -t "$old_name" "$new_name"

    for index in "${!sessions[@]}"; do
        if [[ "${sessions[$index]}" == "$old_name" ]]; then
            sessions[$index]="$new_name"
            found=1
            break
        fi
    done

    if (( found == 0 )); then
        sessions+=("$new_name")
    fi

    write_order "${sessions[@]}"
    display_notice "Renamed $old_name to $new_name"
}

main() {
    require_sessions

    case "${1:-}" in
        sync)
            sync_order
            ;;
        list)
            ordered_sessions
            ;;
        up)
            move_session up "${2:-}"
            ;;
        down)
            move_session down "${2:-}"
            ;;
        rename)
            [[ $# -eq 3 ]] || usage
            rename_session "$2" "$3"
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
