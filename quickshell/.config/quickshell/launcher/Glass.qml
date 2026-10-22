import QtQuick
import QtQuick.Effects

// Стеклянная плита: backdrop-блюр обеспечивает Hyprland (layer_rule c blur),
// здесь только геометрия, блик, обводка и тень. Переиспользуется баром,
// OSD, уведомлениями и power menu.
Item {
    id: glass

    default property alias content: contentItem.data

    // Палитра: подмешивается из colors.json wallust.
    property color background: "#14161a"
    property color foreground: "#e6e6e6"
    property color accent: "#7aa2f7"

    // Параметры стекла, чтобы тюнить вид без правок логики.
    property alias radius: body.radius
    property real glassAlpha: 1.0     // общий множитель прозрачности заливки
    property real specular:   1.0     // сила верхнего блика
    property real shadowOpacity: 0.45 // насыщенность тени
    property real shadowBlur: 30      // радиус размытия тени
    property real shadowOffset: 10    // сдвиг тени вниз

    // Мягкая тень под стеклом.
    RectangularShadow {
        id: shadow

        anchors.centerIn: parent
        width: body.width
        height: body.height
        radius: body.radius
        blur: glass.shadowBlur
        spread: 2
        offset: Qt.vector2d(0, glass.shadowOffset)
        color: "#000000"
        cached: true
        opacity: glass.shadowOpacity
    }

    Rectangle {
        id: body

        anchors.fill: parent
        radius: 28
        // clip здесь давал только прямоугольную обрезку: декоративные слои
        // вылезали за скруглённый силуэт угла. Поэтому каждый слой ниже сам
        // скруглён и клиппить их не нужно.
        antialiasing: true

        // Стекло: сверху светлее, к низу уходит в цвет фона.
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(glass.foreground.r, glass.foreground.g, glass.foreground.b,
                               0.16 * glass.glassAlpha)
            }
            GradientStop {
                position: 0.45
                color: Qt.rgba(glass.foreground.r, glass.foreground.g, glass.foreground.b,
                               0.07 * glass.glassAlpha)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(glass.background.r, glass.background.g, glass.background.b,
                               0.50 * glass.glassAlpha)
            }
        }

        // Specular-блик: широкое пятно от верхней кромки.
        // Слой на весь размер карточки и со своим радиусом — так он повторяет
        // силуэт скругления, а не рисует прямой угол поверх дуги.
        Rectangle {
            anchors.fill: parent
            radius: body.radius
            antialiasing: true
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(1, 1, 1, 0.18 * glass.specular)
                }
                GradientStop {
                    position: 0.45
                    color: Qt.rgba(1, 1, 1, 0)
                }
            }
        }

        // Острая верхняя кромка — читаемая граница стекла.
        // Толщина кромки задаётся в пикселях, поэтому привязываемся к высоте.
        Rectangle {
            anchors.fill: parent
            radius: body.radius
            antialiasing: true
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(1, 1, 1, 0.40 * glass.specular)
                }
                GradientStop {
                    position: 2 / Math.max(1, body.height)
                    color: Qt.rgba(1, 1, 1, 0.12 * glass.specular)
                }
                GradientStop {
                    position: 4 / Math.max(1, body.height)
                    color: Qt.rgba(1, 1, 1, 0)
                }
            }
        }

        // Лёгкий акцентный подмес у нижней кромки — цвет едет вместе с обоями.
        Rectangle {
            anchors.fill: parent
            radius: body.radius
            antialiasing: true
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(glass.accent.r, glass.accent.g, glass.accent.b, 0)
                }
                GradientStop {
                    position: Math.max(0, (body.height - 70) / Math.max(1, body.height))
                    color: Qt.rgba(glass.accent.r, glass.accent.g, glass.accent.b, 0)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(glass.accent.r, glass.accent.g, glass.accent.b,
                                   0.10 * glass.specular)
                }
            }
        }

        // Волосковая рамка по контуру.
        Rectangle {
            anchors.fill: parent
            radius: body.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(glass.foreground.r, glass.foreground.g, glass.foreground.b, 0.16)
        }
    }

    Item {
        id: contentItem
        anchors.fill: parent
    }
}
