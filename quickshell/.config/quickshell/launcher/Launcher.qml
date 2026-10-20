import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

// Лаунчер: полноэкранный прозрачный слой, по центру карточка с поиском.
PanelWindow {
    id: launcher

    required property var theme

    visible: false
    color: "transparent"
    exclusiveZone: -1
    focusable: true
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    // Exclusive задаём постоянно: при показе слой сразу забирает клавиатуру.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property string query: ""
    property var entries: []
    property int selected: 0

    // keywords у DesktopEntry — список, поэтому приводим поле к строке аккуратно.
    function textOf(value) {
        if (value === undefined || value === null) return ""
        if (Array.isArray(value)) return value.join(" ")
        if (typeof value === "object" && value.length !== undefined) {
            let joined = ""
            for (let i = 0; i < value.length; i++) joined += " " + value[i]
            return joined
        }
        return String(value)
    }

    function matches(entry, q): bool {
        const fields = [entry.name, entry.genericName, entry.comment, entry.keywords]
        for (let i = 0; i < fields.length; i++) {
            if (textOf(fields[i]).toLowerCase().indexOf(q) !== -1) return true
        }
        return false
    }

    function refresh(): void {
        const q = query.trim().toLowerCase()
        let list = DesktopEntries.applications.values.filter(e => e && e.name && !e.noDisplay)
        if (q.length > 0) list = list.filter(e => matches(e, q))
        list.sort((a, b) => (a.name || "").localeCompare(b.name || ""))
        entries = list.slice(0, 12)
        selected = 0
    }

    function open(): void {
        query = ""
        refresh()
        visible = true
        Qt.callLater(() => search.forceActiveFocus())
    }

    function close(): void {
        visible = false
        query = ""
    }

    function toggle(): void {
        if (visible) close()
        else open()
    }

    function activate(index: int): void {
        if (index < 0 || index >= entries.length) return
        const entry = entries[index]
        close()
        if (!entry) return

        // execute() у Quickshell игнорирует Terminal=true и коды полей %f/%U.
        if (entry.runInTerminal && entry.command.length > 0) {
            const cmd = ["kitty", "-e"]
            for (let i = 0; i < entry.command.length; i++) {
                const arg = String(entry.command[i])
                if (/^%[fFuUick]$/.test(arg)) continue
                cmd.push(arg)
            }
            Quickshell.execDetached({ command: cmd, workingDirectory: entry.workingDirectory })
        } else {
            entry.execute()
        }
    }

    onSelectedChanged: {
        if (list.count > 0 && selected >= 0) list.positionViewAtIndex(selected, ListView.Contain)
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            launcher.refresh()
        }
    }

    // Клик вне карточки закрывает лаунчер.
    MouseArea {
        anchors.fill: parent
        onClicked: launcher.close()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 660)
        // Высота подстраивается под число результатов, но не больше 8 строк.
        height: Math.min(parent.height - 120, 98 + Math.max(1, Math.min(launcher.entries.length, 8)) * 52)
        radius: 14
        color: launcher.theme.surface
        border.width: 1
        border.color: launcher.theme.border

        // Съедаем клики по самой карточке, чтобы не сработал MouseArea выше.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            TextField {
                id: search
                width: parent.width
                height: 46
                placeholderText: ""
                text: launcher.query
                font.pixelSize: 18
                color: launcher.theme.foreground
                selectionColor: launcher.theme.accent

                background: Rectangle {
                    radius: 10
                    color: launcher.theme.surfaceHigh
                    border.width: 1
                    border.color: search.activeFocus ? launcher.theme.accent : launcher.theme.border

                    // Свой placeholder: у Basic-стиля он красился в чёрный.
                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: search.leftPadding + 2
                        verticalAlignment: Text.AlignVCenter
                        text: "Поиск приложений..."
                        font: search.font
                        color: launcher.theme.foreground
                        opacity: 0.5
                        visible: search.text.length === 0
                    }
                }

                onTextChanged: {
                    launcher.query = text
                    launcher.refresh()
                }

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Down) {
                        launcher.selected = Math.min(launcher.selected + 1, launcher.entries.length - 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        launcher.selected = Math.max(launcher.selected - 1, 0)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        launcher.activate(launcher.selected)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        launcher.close()
                        event.accepted = true
                    }
                }
            }

            ListView {
                id: list
                width: parent.width
                height: parent.height - search.height - parent.spacing
                clip: true
                spacing: 4
                model: launcher.entries
                currentIndex: launcher.selected

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    height: 48
                    radius: 8
                    color: index === launcher.selected ? launcher.theme.selection : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: 24
                            source: modelData.icon
                                ? Quickshell.iconPath(modelData.icon, true)
                                : Quickshell.iconPath("application-x-executable", true)
                            fillMode: Image.PreserveAspectFit
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: list.width - 80
                                text: modelData.name || modelData.id
                                color: launcher.theme.foreground
                                font.pixelSize: 15
                                elide: Text.ElideRight
                            }

                            Text {
                                width: list.width - 80
                                visible: text.length > 0
                                text: modelData.genericName || modelData.comment || ""
                                color: launcher.theme.muted
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: launcher.selected = index
                        onClicked: launcher.activate(index)
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: launcher.close()
    }
}
