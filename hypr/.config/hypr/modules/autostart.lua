-- Автозапуск при старте Hyprland.
-- Скрипты-обёртки защищают от дублей при reload.

hl.on("hyprland.start", function()
    -- История буфера обмена: текст и изображения.
    hl.exec_cmd("$HOME/.local/bin/clipboard-watch.sh text")
    hl.exec_cmd("$HOME/.local/bin/clipboard-watch.sh image")

    -- Видео-обои, палитра wallust, цвета GTK и рамок Hyprland.
    hl.exec_cmd("$HOME/.local/bin/wal-set.sh")
end)
