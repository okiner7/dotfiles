#!/usr/bin/env bash
# Видео-обои через mpvpaper + палитра wallust для kitty, zsh, GTK и рамок Hyprland.
#
# Куда кидать обои:
#   ~/Pictures/Wallpapers — берётся самый свежий файл
#   (mp4 / webm / mkv / mov / gif / png / jpg / jpeg / webp).
# Переопределения:
#   WALLPAPER_FILE — конкретный файл (приоритет над папкой).
#   WALLPAPER_DIR  — другая папка обоев.
# Скрипт извлекает кадр (для видео), гоняет wallust и запускает mpvpaper.
set -u

HOME_DIR="${HOME:?HOME не задан}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME_DIR/.cache}/wal-set"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME_DIR/.config}"
LOG_FILE="$CACHE_DIR/wal-set.log"
LOCK_FILE="$CACHE_DIR/wal-set.lock"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME_DIR/Pictures/Wallpapers}"
FRAME="$CACHE_DIR/frame.png"

mkdir -p "$CACHE_DIR" "$CONFIG_DIR/kitty" "$CONFIG_DIR/zsh"

log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$LOG_FILE"
    printf '[wal-set] %s\n' "$*" >&2
}

exec 9>"$LOCK_FILE"
flock -n 9 || { log "уже запущен, выходим"; exit 0; }

kill_backends() {
    pkill -x mpvpaper    >/dev/null 2>&1 || true
    pkill -x swww-daemon >/dev/null 2>&1 || true
    pkill -x swww        >/dev/null 2>&1 || true
    pkill -x hyprpaper   >/dev/null 2>&1 || true
    pkill -x swaybg      >/dev/null 2>&1 || true
}

is_image() {
    case "${1,,}" in
        *.png|*.jpg|*.jpeg|*.webp) return 0 ;;
        *) return 1 ;;
    esac
}

# Самый свежий файл; при равном времени видео приоритетнее картинки.
find_media() {
    local f
    for f in "${WALLPAPER_FILE:-}" "${WALLPAPER_VIDEO:-}"; do
        if [[ -n "$f" && -f "$f" ]]; then
            printf '%s\n' "$f"
            return 0
        fi
    done

    local dirs=("$WALLPAPER_DIR")
    [[ -d "$HOME_DIR/Videos" ]] && dirs+=("$HOME_DIR/Videos")

    local found
    found="$(find "${dirs[@]}" -maxdepth 2 -type f \
        \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' -o -iname '*.gif' \
        -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
        -printf '%T@ %p\n' 2>/dev/null | python3 -c '
import sys
best = None
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line:
        continue
    stamp, _, path = line.partition(" ")
    try:
        stamp = float(stamp)
    except ValueError:
        continue
    low = path.lower()
    pri = 1 if low.endswith((".mp4", ".webm", ".mkv", ".mov", ".gif")) else 0
    key = (stamp, pri)
    if best is None or key > best[0]:
        best = (key, path)
if best:
    print(best[1])
')"
    if [[ -n "$found" ]]; then
        printf '%s\n' "$found"
        return 0
    fi
    return 1
}

make_frame() {
    local video="$1"
    command -v ffmpeg >/dev/null 2>&1 || return 1
    if ffmpeg -hide_banner -loglevel error -y -ss 1 -i "$video" -frames:v 1 -vf "scale=1920:-2" "$FRAME" 2>/dev/null; then
        return 0
    fi
    if ffmpeg -hide_banner -loglevel error -y -i "$video" -frames:v 1 -vf "scale=1920:-2" "$FRAME" 2>/dev/null; then
        return 0
    fi
    return 1
}

run_wallust() {
    local image="$1"
    command -v wallust >/dev/null 2>&1 || { log "wallust не найден"; return 1; }
    if wallust -s run -w "$image" >/dev/null 2>&1; then
        return 0
    fi
    if wallust run -w -s "$image" >/dev/null 2>&1; then
        return 0
    fi
    log "wallust завершился с ошибкой"
    return 1
}

reload_kitty() {
    pkill -SIGUSR1 -x kitty >/dev/null 2>&1 || true
}

reload_hypr() {
    command -v hyprctl >/dev/null 2>&1 || return 0
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || return 0
    hyprctl reload >/dev/null 2>&1 || true
}

start_static_fallback() {
    local image="$1"
    if command -v swww >/dev/null 2>&1; then
        if ! pgrep -x swww-daemon >/dev/null 2>&1; then
            nohup swww-daemon >/dev/null 2>&1 9>&- &
            sleep 0.5
        fi
        if swww img "$image" >/dev/null 2>&1; then
            log "статические обои: swww $image"
            return 0
        fi
    fi
    if command -v swaybg >/dev/null 2>&1; then
        nohup swaybg -i "$image" -m fill >/dev/null 2>&1 9>&- &
        log "статические обои: swaybg $image"
        return 0
    fi
    return 1
}

start_mpvpaper() {
    local media="$1"
    command -v mpvpaper >/dev/null 2>&1 || return 1
    # 9>&- — не отдавать фоновому процессу файл-блокировку
    # (иначе mpvpaper держит flock и следующий запуск wal-set.sh не пройдёт).
    mpvpaper -f -p -a FULL \
        -o "no-audio loop-file=inf image-display-duration=inf hwdec=auto no-config" \
        ALL "$media" >/dev/null 2>&1 9>&-
}

kill_backends

media="$(find_media || true)"

if [[ -z "$media" ]]; then
    log "обои не найдены — кинь файл в $WALLPAPER_DIR"
    log "готово"
    exit 0
fi

log "обои: $media"

palette_source=""
if is_image "$media"; then
    palette_source="$media"
else
    if make_frame "$media"; then
        palette_source="$FRAME"
    else
        log "не удалось извлечь кадр, wallust пропущен"
    fi
fi

if [[ -n "$palette_source" ]]; then
    if run_wallust "$palette_source"; then
        # Применяем цвета на лету: kitty — SIGUSR1, Hyprland — reload.
        # GTK (Thunar) подхватит gtk.css при следующем открытии окна.
        reload_kitty
        reload_hypr
    fi
fi

if start_mpvpaper "$media"; then
    log "mpvpaper запущен: $media"
else
    log "mpvpaper не установлен или не запустился"
    fallback="$media"
    is_image "$media" || fallback="$FRAME"
    if [[ -f "$fallback" ]]; then
        start_static_fallback "$fallback" || log "нет статического бэкенда (swww/swaybg) — обои не поставлены"
    fi
fi

log "готово"
exit 0
