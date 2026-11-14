pragma ComponentBehavior: Bound

import QtQuick

// A ring gauge: `value` is 0..1, `centerText` and `unit` sit inside, `caption` under it.
Item {
    id: root

    property real value: 0
    property color color: Style.accent
    property string centerText: ""
    property string unit: ""
    property string caption: ""

    implicitWidth: 56
    implicitHeight: 74

    onValueChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        width: 46
        height: 46
        anchors.horizontalCenter: parent.horizontalCenter
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.lineWidth = 3;
            ctx.lineCap = "round";
            const c = width / 2;
            const r = c - 3;
            ctx.strokeStyle = "rgba(255,255,255,0.22)";
            ctx.beginPath();
            ctx.arc(c, c, r, 0, Math.PI * 2);
            ctx.stroke();
            const v = Math.max(0, Math.min(1, root.value));
            if (v > 0) {
                ctx.strokeStyle = root.color;
                ctx.beginPath();
                ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * v);
                ctx.stroke();
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 1
            Text {
                text: root.centerText
                color: Style.text
                font.family: Style.font
                font.pixelSize: 14
            }
            Text {
                y: 3
                text: root.unit
                color: Style.dim
                font.family: Style.font
                font.pixelSize: 8
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: canvas.bottom
        anchors.topMargin: 2
        text: root.caption
        color: Style.dim
        font.family: Style.font
        font.pixelSize: 9
        font.weight: Font.DemiBold
    }
}
