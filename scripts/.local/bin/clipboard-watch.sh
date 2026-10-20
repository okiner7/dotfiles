#!/usr/bin/env bash
# Запускает watcher cliphist для текста или изображений.
# Если такой watcher уже запущен (например, QuickShell), второй не создаётся.
set -u

kind="${1:-text}"

case "$kind" in
    text|image) ;;
    *) printf 'usage: %s {text|image}\n' "$0" >&2; exit 2 ;;
esac

command -v wl-paste >/dev/null 2>&1 || exit 1
command -v cliphist >/dev/null 2>&1 || exit 1

# [w] защищает от совпадения с собственной командной строкой pgrep.
pattern="[w]l-paste --type ${kind} --watch cliphist store"

if pgrep -f "$pattern" >/dev/null 2>&1; then
    exit 0
fi

exec wl-paste --type "$kind" --watch cliphist store
