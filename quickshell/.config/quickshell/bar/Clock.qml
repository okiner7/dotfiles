import QtQuick
import QtQuick.Layouts
import Quickshell

// Время и дата. Локаль ru_RU, поэтому дни недели и месяцы русские.
Item {
    id: root

    required property var theme

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string time: String(clock.hours).padStart(2, "0") + ":"
        + String(clock.minutes).padStart(2, "0")
    readonly property string day: clock.date.toLocaleDateString(Qt.locale("ru_RU"), "ddd, d MMM")

    implicitWidth: row.implicitWidth
    implicitHeight: 20

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: 7

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.time
            color: root.theme.foreground
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: "·"
            color: root.theme.muted
            font.pixelSize: 12
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.day
            color: root.theme.muted
            font.pixelSize: 12
        }
    }
}
