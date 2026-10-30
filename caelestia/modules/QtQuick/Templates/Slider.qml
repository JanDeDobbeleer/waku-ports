import QtQuick

// Stand-in for QtQuick.Templates.Slider. The handle positions itself (the caller binds its x or
// y from visualPosition); the slider maps mouse input behind the contentItem.
Control {
    id: slider

    enum SnapMode {
        NoSnap,
        SnapAlways,
        SnapOnRelease
    }

    property real from: 0
    property real to: 1
    property real value: 0
    property real stepSize: 0
    property int snapMode: Slider.NoSnap
    property int orientation: Qt.Horizontal
    property bool live: true
    property Item handle
    readonly property bool horizontal: orientation === Qt.Horizontal
    readonly property bool vertical: orientation === Qt.Vertical
    readonly property real position: to !== from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0
    readonly property real visualPosition: vertical ? 1 - position : (mirrored ? 1 - position : position)
    readonly property bool pressed: area.pressed

    signal moved

    function valueAt(pos: real): real {
        let v = from + (to - from) * pos;
        if (stepSize > 0)
            v = Math.round((v - from) / stepSize) * stepSize + from;
        return Math.max(Math.min(from, to), Math.min(Math.max(from, to), v));
    }

    function increase(): void {
        value = valueAt(position + (stepSize > 0 ? stepSize / (to - from) : 0.1));
    }

    function decrease(): void {
        value = valueAt(position - (stepSize > 0 ? stepSize / (to - from) : 0.1));
    }

    function setFromMouse(mx: real, my: real): void {
        const hs = handle ? (horizontal ? handle.width : handle.height) : 0;
        let pos;
        if (horizontal)
            pos = (mx - leftPadding - hs / 2) / Math.max(1, availableWidth - hs);
        else
            pos = 1 - (my - topPadding - hs / 2) / Math.max(1, availableHeight - hs);
        pos = Math.max(0, Math.min(1, pos));
        if (mirrored && horizontal)
            pos = 1 - pos;
        const v = valueAt(pos);
        if (v !== value) {
            value = v;
            moved();
        }
    }

    onHandleChanged: {
        if (handle)
            handle.parent = slider;
    }

    MouseArea {
        id: area

        anchors.fill: parent
        z: -0.5
        enabled: slider.enabled
        onPressed: e => slider.setFromMouse(e.x, e.y)
        onPositionChanged: e => slider.setFromMouse(e.x, e.y)
    }
}
