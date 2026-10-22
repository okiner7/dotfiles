import QtQuick
import QtQuick.Effects

// Монохромная иконка из темы (Adwaita symbolic), перекрашенная в цвет текста.
// Нужна потому, что symbolic-иконки тёмные и на стекле не видны.
Item {
    id: root

    property string source: ""
    property color color: "#e6e6e6"
    property int size: 16

    implicitWidth: size
    implicitHeight: size

    Image {
        id: img

        anchors.fill: parent
        source: root.source
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false
    }

    MultiEffect {
        anchors.fill: img
        source: img
        // Исходник тёмный: без brightness цветизация не поднимает его до цвета.
        brightness: 1.0
        colorization: 1.0
        colorizationColor: root.color
    }
}
