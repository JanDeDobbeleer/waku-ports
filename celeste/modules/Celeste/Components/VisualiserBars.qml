import QtQuick

// Visible stub for celeste's C++ VisualiserBars. Draws one rounded bar per value along the
// bottom, no per-frame smoothing. Nothing feeds `values` on Windows (the cava source is dropped).
// waku gap: no animation between value updates, no mirrored left/right layout.
Item {
    id: root

    property var values: []
    property color primaryColor: "white"
    property color secondaryColor: "gray"
    property real rounding: 0
    property real spacing: 0
    property int animationDuration: 0
    readonly property bool settled: true

    function advance(dt: real): void {
    }

    Row {
        anchors.fill: parent
        spacing: root.spacing

        Repeater {
            model: root.values

            Rectangle {
                required property var modelData
                required property int index

                readonly property real level: Math.max(0, Math.min(1, Number(modelData) || 0))

                width: Math.max(1, (root.width - root.spacing * (root.values.length - 1)) / Math.max(1, root.values.length))
                height: Math.max(1, level * root.height)
                y: root.height - height
                radius: root.rounding
                color: index % 2 === 0 ? root.primaryColor : root.secondaryColor
            }
        }
    }
}
