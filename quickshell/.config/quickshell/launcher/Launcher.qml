import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs

// Лаунчер: полноэкранный прозрачный слой, по центру стеклянная карточка с поиском.
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

    // Размытие фона под карточкой. Композитор (Hyprland) размывает только
    // указанный регион, поэтому размытие не выходит за края плиты.
    BackgroundEffect.blurRegion: GlassConfig.blurEnabled ? cardBlurRegion : null

    Region {
        id: cardBlurRegion

        // Регион следует за карточкой: меняет размер вместе с ней.
        item: card
        radius: GlassConfig.blurRadius
    }

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
        visible = true
        query = ""
        refresh()

        // Появление: мягкое всплытие из центра.
        card.scale = 0.96
        card.opacity = 0
        openAnim.restart()
        Qt.callLater(() => search.forceActiveFocus())
    }

    function close(): void {
        if (!visible) return
        closeAnim.restart()
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

    ParallelAnimation {
        id: openAnim

        NumberAnimation {
            target: card
            property: "opacity"
            to: 1
            duration: 180
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: card
            property: "scale"
            to: 1
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: closeAnim

        NumberAnimation {
            target: card
            property: "opacity"
            to: 0
            duration: 130
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: card
            property: "scale"
            to: 0.97
            duration: 130
            easing.type: Easing.InCubic
        }
        onRunningChanged: {
            if (!running) {
                launcher.query = ""
                launcher.visible = false
            }
        }
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

    Glass {
        id: card

        anchors.centerIn: parent
        width: Math.min(launcher.width - 60, 700)
        // Высота подстраивается под число результатов, но не больше 8 строк.
        height: Math.min(
            launcher.height - 100,
            // margins 18*2 + pill 46 + spacing 12 + строки 48 + промежутки 6
            94 + Math.max(1, Math.min(launcher.entries.length, 8)) * 48
                + (Math.max(1, Math.min(launcher.entries.length, 8)) - 1) * 6
        )

        background: launcher.theme.background
        foreground: launcher.theme.foreground
        accent: launcher.theme.accent

        // Съедаем клики по самой карточке, чтобы не сработал MouseArea выше.
        MouseArea {
            anchors.fill: parent
        }

        // Плавная подгонка высоты под количество результатов.
        Behavior on height {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Поле поиска — внутренняя пилюля того же стекла.
            Rectangle {
                width: parent.width
                height: 46
                radius: 14
                color: search.activeFocus
                    ? Qt.rgba(launcher.theme.accent.r, launcher.theme.accent.g,
                              launcher.theme.accent.b, 0.12)
                    : Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: search.activeFocus
                    ? Qt.rgba(launcher.theme.accent.r, launcher.theme.accent.g,
                              launcher.theme.accent.b, 0.50)
                    : Qt.rgba(1, 1, 1, 0.10)

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                // Значок поиска слева: нарисован фигурами, чтобы не зависеть
                // от символьных иконок темы и не добавлять текст в поле.
                Item {
                    id: magnifier
                    width: 16
                    height: 16
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.55

                    // Кружок лупы.
                    Rectangle {
                        width: 11
                        height: 11
                        radius: 5.5
                        color: "transparent"
                        border.width: 1.4
                        border.color: launcher.theme.foreground
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.horizontalCenterOffset: -1.5
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -1.5
                    }

                    // Ручка лупы.
                    Rectangle {
                        width: 7
                        height: 1.5
                        radius: 0.75
                        color: launcher.theme.foreground
                        rotation: 45
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                    }
                }

                TextField {
                    id: search

                    anchors.fill: parent
                    anchors.margins: 2
                    placeholderText: ""
                    text: launcher.query
                    font.pixelSize: 17
                    color: launcher.theme.foreground
                    selectionColor: launcher.theme.accent
                    background: Item {}

                    // Отступы текста: слева запас под значок поиска.
                    leftPadding: 40
                    rightPadding: 14
                    topPadding: 0
                    bottomPadding: 0

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
            }

            ListView {
                id: list

                width: parent.width
                height: parent.height - search.height - parent.spacing
                clip: true
                spacing: 6
                model: launcher.entries
                currentIndex: launcher.selected

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    height: 48
                    radius: 12
                    color: index === launcher.selected
                        ? Qt.rgba(launcher.theme.accent.r, launcher.theme.accent.g,
                                  launcher.theme.accent.b, 0.18)
                        : Qt.rgba(1, 1, 1, 0.04)

                    Behavior on color {
                        ColorAnimation { duration: 110 }
                    }

                    // Акцентная риска слева у выбранной строки.
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 20
                        radius: 2
                        color: launcher.theme.accent
                        visible: index === launcher.selected
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26
                            height: 26
                            source: modelData.icon
                                ? Quickshell.iconPath(modelData.icon, true)
                                : Quickshell.iconPath("application-x-executable", true)
                            fillMode: Image.PreserveAspectFit
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: list.width - 90
                                text: modelData.name || modelData.id
                                color: launcher.theme.foreground
                                font.pixelSize: 15
                                elide: Text.ElideRight
                            }

                            Text {
                                width: list.width - 90
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
