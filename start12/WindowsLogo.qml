import QtQuick

// The Windows 11 logo: four panes.
Item {
    id: root

    property int size: 20
    property color lightColor: "#5cc8ff"
    property color deepColor: "#1485f0"
    readonly property int panes: 4
    readonly property real pane: (size - 2) / 2

    implicitWidth: size
    implicitHeight: size

    Repeater {
        model: root.panes

        Rectangle {
            required property int index
            x: (index % 2) * (root.pane + 2)
            y: Math.floor(index / 2) * (root.pane + 2)
            width: root.pane
            height: root.pane
            radius: 1
            gradient: Gradient {
                GradientStop { position: 0; color: root.lightColor }
                GradientStop { position: 1; color: root.deepColor }
            }
        }
    }
}
