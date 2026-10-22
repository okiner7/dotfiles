import QtQuick
import Quickshell
import Quickshell.Io

// Палитра из wallust. Пока colors.json нет — используем нейтральный fallback.
Item {
    id: theme
    visible: false
    width: 0
    height: 0

    property var palette: ({
        background: "#14161a",
        foreground: "#e6e6e6",
        cursor: "#7aa2f7",
        color0: "#14161a",
        color1: "#f7768e",
        color2: "#9ece6a",
        color3: "#e0af68",
        color4: "#7aa2f7",
        color5: "#bb9af7",
        color6: "#7dcfff",
        color7: "#c0caf5",
        color8: "#414868",
        color9: "#f7768e",
        color10: "#9ece6a",
        color11: "#e0af68",
        color12: "#7aa2f7",
        color13: "#bb9af7",
        color14: "#7dcfff",
        color15: "#c0caf5"
    })

    function pick(name, fallback) {
        const value = palette ? palette[name] : ""
        return value && value.length > 0 ? value : fallback
    }

    function parse(raw) {
        if (!raw) return
        try {
            const data = JSON.parse(raw)
            if (data && data.background && data.foreground) palette = data
        } catch (e) {
            // Файл может быть недописан в момент смены обоев — оставляем старую палитру.
        }
    }

    readonly property color background: pick("background", "#14161a")
    readonly property color foreground: pick("foreground", "#e6e6e6")
    readonly property color accent: pick("cursor", pick("color4", "#7aa2f7"))
    readonly property color surface: Qt.rgba(background.r, background.g, background.b, 0.93)
    readonly property color surfaceHigh: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.08)
    readonly property color selection: Qt.rgba(accent.r, accent.g, accent.b, 0.20)
    readonly property color border: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.16)
    readonly property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.55)

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: theme.parse(text())
    }
}
