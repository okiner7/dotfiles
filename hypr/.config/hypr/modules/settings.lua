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
        gaps_in  = 5,
        gaps_out = 10,

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
        rounding       = 12,
        rounding_power = 2.4,

        active_opacity   = 1.0,
        inactive_opacity = 0.94,
        dim_inactive     = true,
        dim_strength     = 0.08,

        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            offset       = { 0, 4 },
            color        = 0xcc0a0a0a,
        },

        blur = {
            enabled  = true,
            size     = 6,
            passes   = 2,
            vibrancy = 0.18,
            popups   = true,
            xray     = false,
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
