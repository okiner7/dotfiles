import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

// Громкость основного выхода PipeWire. Клик — mute, колесо — ±2%.
Item {
    id: root

    required property var theme

    readonly property var audio: Pipewire.defaultAudioSink
        ? Pipewire.defaultAudioSink.audio
        : null
    readonly property real level: audio ? audio.volume : 0
    readonly property bool muted: audio ? audio.muted : false

    implicitWidth: row.implicitWidth
    implicitHeight: 20

    // PipeWire связывает узлы лениво: без трекера громкость читается как 0.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    function iconName() {
        if (root.muted || root.level <= 0.001) return "audio-volume-muted-symbolic"
        if (root.level < 0.34) return "audio-volume-low-symbolic"
        if (root.level < 0.67) return "audio-volume-medium-symbolic"
        return "audio-volume-high-symbolic"
    }

    function step(delta) {
        if (!root.audio) return
        if (root.audio.muted) root.audio.muted = false
        root.audio.volume = Math.max(0, Math.min(1, root.audio.volume + delta))
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: 5

        Icon {
            Layout.alignment: Qt.AlignVCenter
            source: Quickshell.iconPath(root.iconName())
            color: root.theme.foreground
            size: 16
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: Math.round(root.level * 100) + "%"
            color: root.theme.foreground
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.audio) root.audio.muted = !root.audio.muted
        }
        onWheel: (event) => {
            root.step(event.angleDelta.y > 0 ? 0.02 : -0.02)
        }
    }
}
