import QtQuick
import Celeste.Components

Item {
    id: root

    final property real radius
    final property real topLeftRadius: radius
    final property real topRightRadius: radius
    final property real bottomRightRadius: radius
    final property real bottomLeftRadius: radius
    final property color color: "transparent"
    default property alias contentData: contentItem.data

    Item {
        id: contentItem

        anchors.fill: parent
    }

    ShaderEffectSource {
        id: sourceItem

        hideSource: true
        sourceItem: contentItem
    }

    RoundedMask {
        anchors.fill: parent
        source: sourceItem
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomRightRadius: root.bottomRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        color: root.color
    }

    Behavior on color {
        CAnim {}
    }
}
