import QtQuick

// Stand-in for QtQuick.Templates.DoubleSpinBox (Qt 6.11+). The down indicator sits at the left
// edge and the up indicator at the right edge. The contentItem is the editor; the caller wires
// `text` from textFromValue and calls increase/decrease.
Control {
    id: box

    property real from: 0
    property real to: 99
    property real value: 0
    property real stepSize: 1
    property int decimals: 2
    property bool editable: false
    property bool wrap: false
    property var validator: DoubleValidator {
        bottom: Math.min(box.from, box.to)
        top: Math.max(box.from, box.to)
        decimals: box.decimals
    }
    readonly property SpinButton up: SpinButton {}
    readonly property SpinButton down: SpinButton {}

    signal valueModified

    function textFromValue(v: real, loc: var): string {
        return Number(v).toLocaleString(loc ?? locale, "f", decimals);
    }

    function valueFromText(text: string, loc: var): real {
        const v = Number.fromLocaleString(loc ?? locale, text);
        return isNaN(v) ? value : v;
    }

    function increase(): void {
        value = Math.min(to, value + stepSize);
        valueModified();
    }

    function decrease(): void {
        value = Math.max(from, value - stepSize);
        valueModified();
    }

    function placeIndicators(): void {
        const d = down.indicator;
        if (d) {
            d.parent = box;
            d.x = 0;
            d.y = (height - d.height) / 2;
        }
        const u = up.indicator;
        if (u) {
            u.parent = box;
            u.x = width - u.width;
            u.y = (height - u.height) / 2;
        }
    }

    Connections {
        target: box.up
        function onIndicatorChanged(): void {
            box.placeIndicators();
        }
    }

    Connections {
        target: box.down
        function onIndicatorChanged(): void {
            box.placeIndicators();
        }
    }

    onWidthChanged: placeIndicators()
    onHeightChanged: placeIndicators()
}
