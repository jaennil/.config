#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
HELPER="$SCRIPT_DIR/session-order.sh"
SOCKET_BASE="session-order-test-$$"
SOCKET="$SOCKET_BASE"
ORDER_FILE="/tmp/${SOCKET_BASE}.pins"

tm() {
    tmux -L "$SOCKET" "$@"
}

run_helper() {
    TMUX_SOCKET_NAME="$SOCKET" TMUX_SESSION_ORDER_FILE="$ORDER_FILE" "$HELPER" "$@"
}

cleanup() {
    tm kill-server >/dev/null 2>&1 || true
    rm -f "$ORDER_FILE"
}

reset_server() {
    cleanup
    SOCKET="${SOCKET_BASE}-${RANDOM}"
    ORDER_FILE="/tmp/${SOCKET}.pins"
}

assert_eq() {
    local expected=$1
    local actual=$2
    local context=$3

    if [[ "$expected" != "$actual" ]]; then
        printf 'assertion failed: %s\nexpected: %s\nactual:   %s\n' "$context" "$expected" "$actual" >&2
        exit 1
    fi
}

assert_success() {
    local context=$1
    shift

    if ! "$@"; then
        printf 'command failed unexpectedly: %s\n' "$context" >&2
        exit 1
    fi
}

assert_failure() {
    local context=$1
    shift

    if "$@" >/tmp/session-order-test.out 2>/tmp/session-order-test.err; then
        printf 'command succeeded unexpectedly: %s\n' "$context" >&2
        exit 1
    fi
}

session_list() {
    TMUX_SESSION_ORDER_FILE="$ORDER_FILE" TMUX_SOCKET_NAME="$SOCKET" "$HELPER" list | paste -sd',' -
}

new_sessions() {
    local name

    for name in "$@"; do
        tm new-session -d -s "$name"
    done
}

test_sync_keeps_only_existing_pins() {
    reset_server
    new_sessions dashboard config doc

    printf 'dashboard\nconfig\n' >"$ORDER_FILE"
    assert_success "sync should succeed" run_helper sync
    assert_eq \
        "dashboard,config" \
        "$(session_list)" \
        "sync should keep only pinned sessions that still exist"
}

test_move_down_and_up() {
    reset_server
    new_sessions dashboard config doc
    printf 'dashboard\nconfig\n' >"$ORDER_FILE"
    run_helper sync >/dev/null

    assert_success "move down by session name" run_helper down config >/dev/null
    assert_eq \
        "dashboard,config" \
        "$(session_list)" \
        "down should keep the last pinned session in place"

    assert_success "move up by session name" run_helper up config >/dev/null
    assert_eq \
        "config,dashboard" \
        "$(session_list)" \
        "up should swap pinned sessions"
}

test_move_respects_boundaries() {
    reset_server
    new_sessions dashboard config doc
    printf 'config\ndashboard\n' >"$ORDER_FILE"
    run_helper sync >/dev/null

    assert_success "first session up is a no-op" run_helper up config >/dev/null
    assert_eq \
        "config,dashboard" \
        "$(session_list)" \
        "moving the first pinned session up should keep order unchanged"

    assert_success "last pinned session down is a no-op" run_helper down dashboard >/dev/null
    assert_eq \
        "config,dashboard" \
        "$(session_list)" \
        "moving the last pinned session down should keep order unchanged"
}

test_rename_preserves_position() {
    reset_server
    new_sessions dashboard config doc
    printf 'dashboard\nconfig\n' >"$ORDER_FILE"
    run_helper sync >/dev/null

    assert_success "rename should succeed" run_helper rename dashboard dotfiles >/dev/null
    assert_eq \
        "dotfiles,config" \
        "$(session_list)" \
        "rename should keep the pinned session in place"
}

test_move_unpinned_session_is_noop() {
    reset_server
    new_sessions dashboard config doc
    printf 'dashboard\nconfig\n' >"$ORDER_FILE"
    run_helper sync >/dev/null

    assert_success "moving an unpinned session should be a no-op" run_helper up doc >/dev/null
    assert_eq \
        "dashboard,config" \
        "$(session_list)" \
        "moving an unpinned session should not change pinned order"
}

main() {
    trap cleanup EXIT

    test_sync_keeps_only_existing_pins
    test_move_down_and_up
    test_move_respects_boundaries
    test_rename_preserves_position
    test_move_unpinned_session_is_noop

    printf 'session-order tests passed\n'
}

main "$@"
