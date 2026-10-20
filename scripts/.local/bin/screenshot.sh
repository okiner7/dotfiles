#!/usr/bin/env bash
# Скриншоты: region — выделение области (slurp), full — весь экран.
# Файл сохраняется в ~/Pictures/Screenshots и копируется в буфер.
set -u

HOME_DIR="${HOME:?HOME не задан}"
SHOT_DIR="${SCREENSHOT_DIR:-$HOME_DIR/Pictures/Screenshots}"
MODE="${1:-region}"

notify() {
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl notify 1 1500 0 "$*" >/dev/null 2>&1 || true
    elif command -v notify-send >/dev/null 2>&1; then
        notify-send -a screenshot "$*" >/dev/null 2>&1 || true
    fi
}

command -v grim >/dev/null 2>&1 || { notify "grim не установлен"; exit 1; }

mkdir -p "$SHOT_DIR"
file="$SHOT_DIR/$(date '+%Y-%m-%d_%H-%M-%S').png"

case "$MODE" in
    region)
        command -v slurp >/dev/null 2>&1 || { notify "slurp не установлен"; exit 1; }
        geometry="$(slurp)" || exit 0
        [[ -n "$geometry" ]] || exit 0
        grim -g "$geometry" "$file" || { notify "grim не смог снять область"; exit 1; }
        ;;
    full)
        grim "$file" || { notify "grim не смог снять экран"; exit 1; }
        ;;
    *)
        printf 'usage: %s [region|full]\n' "$0" >&2
        exit 2
        ;;
esac

if command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "$file" >/dev/null 2>&1 || true
    notify "Скрин в буфере: $(basename "$file")"
else
    notify "Скрин: $file"
fi
exit 0
