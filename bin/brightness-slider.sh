#!/bin/bash

set -u

notify_error() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical "Brightness" "$1"
    fi
    printf 'brightness-slider: %s\n' "$1" >&2
}

if ! command -v yad >/dev/null 2>&1; then
    notify_error "Missing dependency: yad"
    exit 1
fi

backlight_dir=$(find /sys/class/backlight \( -mindepth 1 -maxdepth 1 \) \( -type l -o -type d \) 2>/dev/null | sort | head -1)
if [ -z "$backlight_dir" ]; then
    notify_error "No backlight device found"
    exit 1
fi

brightness_file="$backlight_dir/brightness"
max_file="$backlight_dir/max_brightness"

if [ ! -r "$brightness_file" ] || [ ! -r "$max_file" ]; then
    notify_error "Cannot read backlight brightness"
    exit 1
fi

current=$(cat "$brightness_file" 2>/dev/null)
max=$(cat "$max_file" 2>/dev/null)

case "$current:$max" in
    *[!0-9:]*|":"|*:0)
        notify_error "Invalid backlight values"
        exit 1
        ;;
esac

percent=$((current * 100 / max))
[ "$percent" -lt 1 ] && percent=1
[ "$percent" -gt 100 ] && percent=100

pidfile="/tmp/i3-brightness-slider.pid"
if [ -f "$pidfile" ]; then
    old_pid=$(cat "$pidfile" 2>/dev/null || true)
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
        kill "$old_pid" 2>/dev/null || true
        sleep 0.1
    fi
fi
printf '%s\n' "$$" > "$pidfile"
trap 'rm -f "$pidfile"' EXIT

set_brightness() {
    local value="$1"
    case "$value" in
        ''|*[!0-9]*)
            return
            ;;
    esac

    [ "$value" -lt 1 ] && value=1
    [ "$value" -gt 100 ] && value=100

    local raw=$((value * max / 100))
    [ "$raw" -lt 1 ] && raw=1
    [ "$raw" -gt "$max" ] && raw="$max"

    if command -v brightnessctl >/dev/null 2>&1; then
        if brightnessctl set "${value}%" >/dev/null 2>&1; then
            return
        fi
    fi

    if ! printf '%s\n' "$raw" > "$brightness_file" 2>/dev/null; then
        notify_error "Cannot write $brightness_file"
        exit 1
    fi
}

yad \
    --scale \
    --title="Brightness" \
    --class="BrightnessSlider" \
    --text="Brightness" \
    --min-value=1 \
    --max-value=100 \
    --step=1 \
    --value="$percent" \
    --print-partial \
    --no-buttons \
    --on-top \
    --close-on-unfocus \
    --skip-taskbar \
    --mouse \
    --fixed \
    --geometry=320x80 \
    2>/dev/null |
while IFS= read -r value; do
    set_brightness "$value"
done
