import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

// Состояние сети: иконка типа подключения или «нет сети».
RowLayout {
    id: root

    required property var theme

    readonly property var device: {
        const list = Networking.devices.values
        for (let i = 0; i < list.length; i++) {
            if (list[i].connected) return list[i]
        }
        return null
    }

    readonly property string iconName: {
        if (!root.device) return "network-offline-symbolic"
        if (root.device.type === DeviceType.Wifi) return "network-wireless-symbolic"
        if (root.device.type === DeviceType.Wired) return "network-wired-symbolic"
        return "network-wired-symbolic"
    }

    spacing: 0

    Icon {
        Layout.alignment: Qt.AlignVCenter
        source: Quickshell.iconPath(root.iconName)
        color: root.device ? root.theme.foreground : root.theme.muted
        size: 16
    }
}
