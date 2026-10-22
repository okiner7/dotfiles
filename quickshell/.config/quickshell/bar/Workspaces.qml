import QtQuick
import Quickshell
import Quickshell.Hyprland

// Воркспейсы 1..10. Активный — акцентная пилюля, занятые — яркая цифра,
// пустые — приглушённая. Клик переключает, колесо листает соседние.
Row {
    id: root

    required property var theme

    spacing: 4

    // Сведения о воркспейсе по номеру или null, если его ещё нет.
    function workspaceById(id) {
        const list = Hyprland.workspaces.values
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === id) return list[i]
        }
        return null
    }

    function isFocused(id) {
        const ws = Hyprland.focusedWorkspace
        return ws !== null && ws !== undefined && ws.id === id
    }

    function switchTo(id) {
        // Конфиг Hyprland на Lua, поэтому диспатчим Lua-выражение.
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })")
    }

    Repeater {
        model: 10

        delegate: Rectangle {
            id: pill

            required property int index

            // Номера 1..10, десятый подписан нулём — как на клавише.
            readonly property int wsId: index + 1
            readonly property bool active: root.isFocused(wsId)
            readonly property bool occupied: root.workspaceById(wsId) !== null

            width: 24
            height: 24
            radius: 12

            color: active
                ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.90)
                : hover.hovered
                    ? Qt.rgba(root.theme.foreground.r, root.theme.foreground.g,
                              root.theme.foreground.b, 0.10)
                    : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            Text {
                anchors.centerIn: parent
                text: pill.wsId === 10 ? "0" : String(pill.wsId)
                color: pill.active
                    ? root.theme.background
                    : Qt.rgba(root.theme.foreground.r, root.theme.foreground.g,
                              root.theme.foreground.b, pill.occupied ? 0.90 : 0.35)
                font.pixelSize: 12
                font.weight: pill.active ? Font.DemiBold : Font.Medium
            }

            HoverHandler {
                id: hover
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onClicked: root.switchTo(pill.wsId)
                onWheel: (event) => {
                    // r+1/r-1 — соседний по номеру воркспейс (e+1 скачет
                    // к следующему пустому и путает порядок).
                    Hyprland.dispatch(event.angleDelta.y > 0
                        ? "hl.dsp.focus({ workspace = \"r+1\" })"
                        : "hl.dsp.focus({ workspace = \"r-1\" })")
                }
            }
        }
    }
}
