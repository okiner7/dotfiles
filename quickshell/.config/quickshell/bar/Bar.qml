import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

// Верхний бар: одна стеклянная полоса во всю ширину с отступами от краёв.
// Размытие, как и у лаунчера, рисует Hyprland по точному региону плиты.
PanelWindow {
    id: bar

    required property var theme

    color: "transparent"
    implicitHeight: GlassConfig.barHeight

    // Резервируем высоту полосы: отступ сверху Hyprland прибавляет сам,
    // поэтому суммарно под бар уходит 8 + 40 = 48 px.
    exclusiveZone: GlassConfig.barHeight
    exclusionMode: ExclusionMode.Normal

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: GlassConfig.barMargin
        left: 10
        right: 10
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"

    BackgroundEffect.blurRegion: GlassConfig.blurEnabled ? barBlurRegion : null

    Region {
        id: barBlurRegion

        // Регион повторяет пилюлю, поэтому размытие не выходит за её края.
        item: pill
        radius: GlassConfig.barRadius
    }

    Glass {
        id: pill

        anchors.fill: parent

        radius: GlassConfig.barRadius
        flat: true
        baseAlpha: GlassConfig.barAlpha
        accentAlpha: 0
        specular: 0.7

        background: bar.theme.background
        foreground: bar.theme.foreground
        accent: bar.theme.accent

        // Тень всё равно обрезалась бы границами окна высотой с полосу.
        shadowOpacity: 0

        Workspaces {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            theme: bar.theme
        }

        Clock {
            anchors.centerIn: parent
            theme: bar.theme
        }

        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 11

            CpuRam {
                theme: bar.theme
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter
                color: Qt.rgba(bar.theme.foreground.r, bar.theme.foreground.g,
                               bar.theme.foreground.b, 0.14)
            }

            KeyboardLayout {
                theme: bar.theme
                Layout.alignment: Qt.AlignVCenter
            }

            Volume {
                theme: bar.theme
                Layout.alignment: Qt.AlignVCenter
            }

            Network {
                theme: bar.theme
                Layout.alignment: Qt.AlignVCenter
            }

            Tray {
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
