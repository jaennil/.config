#!/bin/sh

command -v xinput >/dev/null 2>&1 || exit 0

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

sleep 1

xinput list --name-only | while IFS= read -r device; do
    prop_id=$(xinput list-props "$device" 2>/dev/null \
        | sed -n 's/.*libinput Tapping Enabled (\([0-9][0-9]*\)).*/\1/p' \
        | head -n 1)

    [ -n "$prop_id" ] || continue

    xinput set-prop "$device" "$prop_id" 1 2>/dev/null || true
done
