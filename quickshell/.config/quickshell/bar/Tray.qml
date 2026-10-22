import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// Иконки фоновых приложений. ЛКМ — активация, СКМ — вторичное действие,
// ПКМ — собственное меню приложения (платформенное, средствами Qt).
Row {
    id: root

    spacing: 6

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: slot

            required property var modelData

            width: 18
            height: 20

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: {
                    const ic = slot.modelData.icon
                    if (!ic) return ""
                    if (ic.indexOf("/") === 0) return "file://" + ic
                    return Quickshell.iconPath(ic, true)
                }
            }

            QsMenuAnchor {
                id: menu

                anchor.item: slot
                menu: slot.modelData.menu
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) slot.modelData.activate()
                    else if (mouse.button === Qt.MiddleButton) slot.modelData.secondaryActivate()
                    else if (slot.modelData.hasMenu) menu.open()
                }
            }
        }
    }
}
