import QtQuick
import QtQuick.Effects
import qs

// Стеклянная плита: размытие фона обеспечивает Hyprland по протоколу
// ext-background-effect-v1 (см. Region в launcher/Launcher.qml и bar/Bar.qml),
// здесь только геометрия, блик, обводка и тень.
//
// Все параметры по умолчанию берутся из глобальных настроек
// GlassConfig.qml — их можно переопределить у конкретного элемента.
Item {
    id: glass

    default property alias content: contentItem.data

    // Палитра: подмешивается из colors.json wallust.
    property color background: "#14161a"
    property color foreground: "#e6e6e6"
    property color accent: "#7aa2f7"

    // Геометрия.
    property int radius: GlassConfig.radius
    property int borderWidth: GlassConfig.borderWidth

    // Заливка.
    property real glassAlpha: GlassConfig.glassAlpha
    property real topAlpha: GlassConfig.topAlpha
    property real bodyAlpha: GlassConfig.bodyAlpha
    property real baseAlpha: GlassConfig.baseAlpha

    // Блик, рамка, акцент.
    property real specular: GlassConfig.specular
    property real borderAlpha: GlassConfig.borderAlpha
    property real accentAlpha: GlassConfig.accentAlpha

    // Тень.
    property real shadowOpacity: GlassConfig.shadowOpacity
    property real shadowBlur: GlassConfig.shadowBlur
    property real shadowOffset: GlassConfig.shadowOffset

    // Плоская заливка для тонких панелей (бар): вместо градиента карточки —
    // ровный цвет фона. Блик и рамка остаются.
    property bool flat: false

    // Цвет с прозрачностью и общим множителем glassAlpha.
    function tint(c, a) {
        return Qt.rgba(c.r, c.g, c.b, Math.max(0, a) * glass.glassAlpha)
    }

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
        radius: glass.radius
        // clip здесь давал только прямоугольную обрезку: декоративные слои
        // вылезали за скруглённый силуэт угла. Поэтому каждый слой ниже сам
        // скруглён и клиппить их не нужно.
        antialiasing: true

        // Стекло: сверху светлее, к низу уходит в цвет фона.
        // В плоском режиме все три остановки — цвет фона (бар).
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: glass.flat
                    ? glass.tint(glass.background, glass.baseAlpha)
                    : glass.tint(glass.foreground, glass.topAlpha)
            }
            GradientStop {
                position: 0.45
                color: glass.flat
                    ? glass.tint(glass.background, glass.baseAlpha)
                    : glass.tint(glass.foreground, glass.bodyAlpha)
            }
            GradientStop {
                position: 1.0
                color: glass.tint(glass.background, glass.baseAlpha)
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
                    color: glass.tint(glass.accent, 0)
                }
                GradientStop {
                    position: Math.max(0, (body.height - 70) / Math.max(1, body.height))
                    color: glass.tint(glass.accent, 0)
                }
                GradientStop {
                    position: 1.0
                    color: glass.tint(glass.accent, glass.accentAlpha * glass.specular)
                }
            }
        }

        // Волосковая рамка по контуру.
        Rectangle {
            anchors.fill: parent
            radius: body.radius
            color: "transparent"
            border.width: glass.borderWidth
            border.color: Qt.rgba(glass.foreground.r, glass.foreground.g, glass.foreground.b,
                                  glass.borderAlpha)
        }
    }

    Item {
        id: contentItem
        anchors.fill: parent
    }
}
