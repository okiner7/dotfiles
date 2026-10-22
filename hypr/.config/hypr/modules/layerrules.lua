-- Правила для layer-поверхностей (бары, лаунчеры, обои).

-- Лаунчер Quickshell: размытие фона под карточкой.
-- background-блюр делает сам Hyprland — в QML достаточно полупрозрачной заливки,
-- участки с малым alpha (края и волоски) остаются резкими.
hl.layer_rule({
    name = "quickshell-launcher-glass",
    match = { namespace = "quickshell-launcher" },

    blur = true,
    ignore_alpha = 0.08,
})

-- Дальше сюда добавятся правила для бара, OSD и уведомлений Quickshell.
