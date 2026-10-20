#!/usr/bin/env bash
# Видео-обои через mpvpaper + палитра wallust для kitty, zsh, GTK и рамок Hyprland.
#
# Куда кидать обои:
#   ~/Pictures/Wallpapers (mp4 / webm / mkv / mov / gif / png / jpg / jpeg / webp).
#
# Режимы выбора (аргумент):
#   --next    следующий файл по имени, по кругу (бинт SUPER+SHIFT+W)
#   --random  случайный файл, не совпадающий с текущим
#   --last    продолжить с последнего выбранного (по умолчанию, автозапуск)
#   --newest  самый свежий файл по mtime (старое поведение)
# Выбранный файл запоминается в ~/.cache/wal-set/last.
#
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
STATE_FILE="$CACHE_DIR/last"
PICK_MODE="last"

# Режим выбора обоев: аргумент командной строки (по умолчанию — last).
case "${1:-}" in
    --next|next)     PICK_MODE="next" ;;
    --random|random) PICK_MODE="random" ;;
    --newest|newest) PICK_MODE="newest" ;;
    --last|last|"")  PICK_MODE="last" ;;
    *)
        printf 'Неизвестный аргумент: %s\n' "$1" >&2
        printf 'Использование: %s [--next|--random|--last|--newest]\n' "$0" >&2
        exit 2
        ;;
esac

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

# Все подходящие файлы обоев (без сортировки).
list_media() {
    local dirs=("$WALLPAPER_DIR")
    [[ -d "$HOME_DIR/Videos" ]] && dirs+=("$HOME_DIR/Videos")

    find "${dirs[@]}" -maxdepth 2 -type f \
        \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' -o -iname '*.gif' \
        -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
        -print 2>/dev/null
}

# Самый свежий файл; при равном времени видео приоритетнее картинки.
find_media_newest() {
    local path stamp key best="" best_key=""
    while IFS= read -r path; do
        [[ -n "$path" ]] || continue
        stamp="$(stat -c '%Y' "$path" 2>/dev/null || echo 0)"
        case "${path,,}" in
            *.mp4|*.webm|*.mkv|*.mov|*.gif) key="$stamp 1" ;;
            *) key="$stamp 0" ;;
        esac
        if [[ -z "$best_key" || "$key" > "$best_key" ]]; then
            best_key="$key"
            best="$path"
        fi
    done < <(list_media)
    [[ -n "$best" ]] && printf '%s\n' "$best"
}

# Последний выбранный файл (если он ещё существует).
read_state() {
    [[ -f "$STATE_FILE" ]] || return 1
    local f
    IFS= read -r f < "$STATE_FILE" || return 1
    [[ -n "$f" && -f "$f" ]] || return 1
    printf '%s\n' "$f"
}

# Выбрать обои согласно режиму (см. шапку скрипта).
pick_media() {
    local f
    for f in "${WALLPAPER_FILE:-}" "${WALLPAPER_VIDEO:-}"; do
        if [[ -n "$f" && -f "$f" ]]; then
            printf '%s\n' "$f"
            return 0
        fi
    done

    local last
    last="$(read_state || true)"

    case "$PICK_MODE" in
        newest)
            find_media_newest
            return
            ;;
        last)
            if [[ -n "$last" ]]; then
                printf '%s\n' "$last"
                return 0
            fi
            find_media_newest
            return
            ;;
        next)
            local list=() path i idx=0
            while IFS= read -r path; do
                [[ -n "$path" ]] && list+=("$path")
            done < <(list_media | LC_ALL=C sort)
            ((${#list[@]})) || return 1

            if [[ -n "$last" ]]; then
                for i in "${!list[@]}"; do
                    if [[ "${list[$i]}" == "$last" ]]; then
                        idx=$(( (i + 1) % ${#list[@]} ))
                        break
                    fi
                done
            fi
            printf '%s\n' "${list[$idx]}"
            return 0
            ;;
        random)
            local list=() path pick="" tries=0
            while IFS= read -r path; do
                [[ -n "$path" ]] && list+=("$path")
            done < <(list_media | LC_ALL=C sort)
            ((${#list[@]})) || return 1

            if ((${#list[@]} == 1)); then
                printf '%s\n' "${list[0]}"
                return 0
            fi

            while ((tries < 20)); do
                if command -v shuf >/dev/null 2>&1; then
                    pick="$(printf '%s\n' "${list[@]}" | shuf -n 1)"
                else
                    pick="${list[RANDOM % ${#list[@]}]}"
                fi
                [[ "$pick" != "$last" ]] && break
                tries=$((tries + 1))
            done
            if [[ -z "$pick" || "$pick" == "$last" ]]; then
                for path in "${list[@]}"; do
                    [[ "$path" != "$last" ]] && { pick="$path"; break; }
                done
            fi
            printf '%s\n' "$pick"
            return 0
            ;;
    esac

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

media="$(pick_media || true)"

if [[ -z "$media" ]]; then
    log "обои не найдены — кинь файл в $WALLPAPER_DIR"
    log "готово"
    exit 0
fi

log "режим: $PICK_MODE, обои: $media"
printf '%s\n' "$media" > "$STATE_FILE.tmp" && mv -f "$STATE_FILE.tmp" "$STATE_FILE"

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
