-- Система разрешений Hyprland (screencopy / plugin).
-- Выключена: при enforce_permissions=true каждый запрос захвата экрана
-- (grim) показывал диалог подтверждения, и grim зависал, ожидая ответа.
-- Включать только вместе с рестартом Hyprland — на reload права не применяются.

hl.config({
    ecosystem = {
        enforce_permissions = false,
    },
})

-- Правила для случая, если enforcement снова включат:
-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")
