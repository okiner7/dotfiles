import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Загрузка CPU и занятая память. /proc/stat читаем дважды и считаем дельту,
// /proc/meminfo даёт общий объём и доступную память.
RowLayout {
    id: root

    required property var theme

    property real cpu: 0
    property real ram: 0

    property real prevIdle: -1
    property real prevTotal: -1

    spacing: 5

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload()
            memFile.reload()
        }
    }

    FileView {
        id: statFile

        path: "/proc/stat"
        watchChanges: false
        printErrors: false
        onLoaded: root.parseStat(text())
    }

    FileView {
        id: memFile

        path: "/proc/meminfo"
        watchChanges: false
        printErrors: false
        onLoaded: root.parseMem(text())
    }

    function parseStat(raw) {
        const lines = raw.split("\n")
        if (lines.length === 0) return

        const parts = lines[0].trim().split(/\s+/)
        if (parts[0] !== "cpu") return

        // user nice system idle iowait irq softirq steal guest guest_nice
        let total = 0
        for (let i = 1; i < parts.length; i++) total += Number(parts[i])
        const idle = Number(parts[4]) + Number(parts[5])

        // Первый замер — только запоминаем, показывать ещё нечего.
        if (root.prevTotal >= 0 && total > root.prevTotal) {
            const dTotal = total - root.prevTotal
            const dIdle = idle - root.prevIdle
            root.cpu = Math.max(0, Math.min(100, 100 * (1 - dIdle / dTotal)))
        }

        root.prevTotal = total
        root.prevIdle = idle
    }

    function parseMem(raw) {
        const totalMatch = raw.match(/MemTotal:\s+(\d+)/)
        const availMatch = raw.match(/MemAvailable:\s+(\d+)/)
        if (!totalMatch || !availMatch) return

        const total = Number(totalMatch[1])
        const avail = Number(availMatch[1])
        root.ram = total > 0 ? Math.max(0, Math.min(100, 100 * (total - avail) / total)) : 0
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: "CPU"
        color: root.theme.muted
        font.pixelSize: 10
        font.weight: Font.Medium
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: Math.round(root.cpu) + "%"
        color: root.theme.foreground
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 4
        text: "RAM"
        color: root.theme.muted
        font.pixelSize: 10
        font.weight: Font.Medium
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: Math.round(root.ram) + "%"
        color: root.theme.foreground
        font.pixelSize: 12
        font.weight: Font.Medium
    }
}
