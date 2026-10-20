#!/usr/bin/env bash
# Установка rice: per-file симлинки конфигов и скриптов в $HOME (без stow).
# Повторный запуск безопасен: заменяет свои симлинки, живые файлы уводит в *.bak.<дата>.
#
# Использование: ./install.sh

set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date '+%Y%m%d-%H%M%S')"
PACKAGES=(hypr kitty wallust gtk zsh scripts quickshell)

# Эти файлы генерирует wallust: в ~ они должны быть обычными файлами, не симлинками.
SKIP_FILES=(
    "hypr/.config/hypr/modules/colors.lua"
    "kitty/.config/kitty/wallust.conf"
    "gtk/.config/gtk-3.0/gtk.css"
    "zsh/.config/zsh/wallust-colors.zsh"
    "quickshell/.config/quickshell/colors.json"
)

info() { printf '[install] %s\n' "$*"; }

should_skip() {
    local rel="$1" s
    for s in "${SKIP_FILES[@]}"; do
        [[ "$rel" == "$s" ]] && return 0
    done
    return 1
}

link_file() {
    local src="$1" rel dst
    rel="${src#"$REPO_DIR"/}"
    dst="$HOME/${rel#*/}"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        mv "$dst" "$dst.bak.$STAMP"
        info "бэкап: ~/${dst#"$HOME"/} -> .bak.$STAMP"
    fi
    ln -sfn "$src" "$dst"
    info "линк:  ~/${dst#"$HOME"/}"
}

for pkg in "${PACKAGES[@]}"; do
    [[ -d "$REPO_DIR/$pkg" ]] || continue
    while IFS= read -r -d '' src; do
        rel="${src#"$REPO_DIR"/}"
        if should_skip "$rel"; then
            info "пропуск (генерирует wallust): ~/${rel#*/}"
            continue
        fi
        link_file "$src"
    done < <(find "$REPO_DIR/$pkg" -type f -print0)
done

# zsh-плагины автодополнения: в custom/plugins, без пакетов и sudo.
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    OMZ_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    ZSH_PLUGINS=(
        "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
        "zsh-completions|https://github.com/zsh-users/zsh-completions"
    )
    for entry in "${ZSH_PLUGINS[@]}"; do
        name="${entry%%|*}"
        url="${entry#*|}"
        if [[ -d "$OMZ_CUSTOM/plugins/$name" ]]; then
            info "плагин уже есть: $name"
        elif git clone --depth=1 "$url" "$OMZ_CUSTOM/plugins/$name" >/dev/null 2>&1; then
            info "плагин установлен: $name"
        else
            info "не удалось установить плагин: $name (проверь сеть)"
        fi
    done
fi

find "$REPO_DIR/scripts" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true

printf '\n'
MISSING=()
for bin in Hyprland hyprctl kitty wallust mpvpaper mpv ffmpeg python3 wl-copy wl-paste cliphist grim slurp thunar qs; do
    command -v "$bin" >/dev/null 2>&1 || MISSING+=("$bin")
done
if ((${#MISSING[@]})); then
    info "не найдены команды: ${MISSING[*]}"
    info "поставь из репозиториев (mpvpaper и wallust могут быть в AUR):"
    info "  sudo pacman -S hyprland kitty mpv ffmpeg python wl-clipboard cliphist thunar grim slurp quickshell"
else
    info "все зависимости на месте"
fi

info "готово. Перезапусти Hyprland, чтобы конфиг подхватился наверняка."
