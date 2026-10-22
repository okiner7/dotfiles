import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Текущая раскладка клавиатуры: us / ru. Клик переключает следующую.
// Имя файла с приставкой Keyboard, чтобы не спорить с attached-типом Layout
// из QtQuick.Layouts.
Item {
    id: root

    required property var theme

    property string layout: "us"

    implicitWidth: label.implicitWidth
    implicitHeight: 20

    // Стартовое состояние: hyprctl devices -j.
    Process {
        id: devicesProc

        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parseDevices(text)
        }
    }

    // Переключение раскладки — это команда hyprctl, а не диспатчер.
    Process {
        id: switchProc

        command: ["hyprctl", "switchxkblayout", "active", "next"]
    }

    Component.onCompleted: devicesProc.running = true

    function shortName(name) {
        if (!name) return "??"
        if (/russ/i.test(name)) return "ru"
        if (/english|^us$/i.test(name)) return "us"
        return name.slice(0, 2).toLowerCase()
    }

    function parseDevices(raw) {
        try {
            const data = JSON.parse(raw)
            if (!data || !data.keyboards || data.keyboards.length === 0) return
            // Берём основную клавиатуру (main), а не первую попавшуюся:
            // в списке бывают клавиши мыши и power button.
            let kb = null
            for (let i = 0; i < data.keyboards.length; i++) {
                if (data.keyboards[i].main) {
                    kb = data.keyboards[i]
                    break
                }
            }
            if (!kb) kb = data.keyboards[0]
            if (kb && kb.active_keymap) root.layout = root.shortName(kb.active_keymap)
        } catch (e) {
            // hyprctl может быть недоступен в момент старта — оставляем как есть.
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "activelayout") return
            const comma = event.data.indexOf(",")
            if (comma === -1) return
            root.layout = root.shortName(event.data.slice(comma + 1))
        }
    }

    Text {
        id: label

        anchors.centerIn: parent
        text: root.layout
        color: root.theme.foreground
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: switchProc.running = true
    }
}
