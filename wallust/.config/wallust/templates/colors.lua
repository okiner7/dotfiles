-- Сгенерировано wallust из текущих обоев.
-- Не редактировать вручную — файл перезаписывается при смене обоев.
-- wallust отдаёт цвет с '#', а Hyprland ждёт rgba(RRGGBBaa) без решётки.
local function hex(value)
    return (value:gsub("^#", ""))
end

return {
    active_border   = { colors = { "rgba(" .. hex("{{color4}}") .. "ee)", "rgba(" .. hex("{{color2}}") .. "ee)" }, angle = 45 },
    inactive_border = "rgba(" .. hex("{{color8}}") .. "aa)",
}
