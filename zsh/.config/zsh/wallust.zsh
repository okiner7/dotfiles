# Wallust: динамические цвета из обоев.
# Подключение в ~/.zshrc:
#   [[ -r "$HOME/.config/zsh/wallust.zsh" ]] && source "$HOME/.config/zsh/wallust.zsh"
# Цвета обновляются после каждого precmd (файл перезаписывает wal-set.sh).

if [[ -r "$HOME/.config/zsh/wallust-colors.zsh" ]]; then
    source "$HOME/.config/zsh/wallust-colors.zsh"
fi

_wallust_reload_colors() {
    [[ -r "$HOME/.config/zsh/wallust-colors.zsh" ]] && source "$HOME/.config/zsh/wallust-colors.zsh"
}

if command -v add-zsh-hook >/dev/null 2>&1; then
    add-zsh-hook precmd _wallust_reload_colors
fi
