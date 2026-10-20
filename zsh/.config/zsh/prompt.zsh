# Минималистичный промпт на цветах wallust.
# Подключается из ~/.config/zsh/wallust.zsh после загрузки палитры.
# PROMPT собирается заново перед каждой командой, поэтому смена обоев
# подхватывается без перезапуска shell: путь, git-ветка, статус ошибки.

autoload -Uz vcs_info
autoload -Uz add-zsh-hook

# Ветка git: [main] (или [main|rebase] во время операции).
zstyle ':vcs_info:git:*' formats       ' [%b]'
zstyle ':vcs_info:git:*' actionformats ' [%b|%a]'

_wallust_prompt_precmd() {
    local last=$?
    local err=""
    local c_path="${WALLUST_COLOR7:-#BFD5E8}"
    local c_git="${WALLUST_COLOR6:-#5F89AD}"
    local c_arrow="${WALLUST_COLOR4:-#5E6F83}"
    local c_err="${WALLUST_COLOR15:-#BFD5E8}"

    vcs_info
    (( last )) && err=" %B%F{${c_err}}✗ ${last}%f%b"

    PROMPT="%F{${c_path}}%~%f%F{${c_git}}${vcs_info_msg_0_}%f${err} %F{${c_arrow}}❯%f "
    RPROMPT=""
}

add-zsh-hook precmd _wallust_prompt_precmd
