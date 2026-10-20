-- Основные настройки: отступы, рамки, размытие, ввод, раскладки.

-- Цвета рамок: из палитры обоев (wallust генерит modules/colors.lua).
-- Если сгенерированного файла ещё нет — дефолтный градиент.
local border_colors = {
    active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
    inactive_border = "rgba(595959aa)",
}

local ok, generated = pcall(require, "modules.colors")
if ok and type(generated) == "table" and generated.active_border then
    border_colors = generated
end

hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 8,

        border_size = 2,

        col = {
            active_border   = border_colors.active_border,
            inactive_border = border_colors.inactive_border,
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    scrolling = {
        fullscreen_on_one_column = true,
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = true,
    },

    input = {
        kb_layout  = "us,ru",
        kb_variant = "",
        kb_model   = "",
        kb_options = "grp:alt_shift_toggle",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Свайп тремя пальцами переключает workspace.
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
