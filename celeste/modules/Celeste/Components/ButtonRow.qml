import QtQuick
import "ButtonRowHelpers.js" as ButtonRowHelpers

// Port of celeste's C++ ButtonRow: lays children out in a row, shares the height, and gives
// children with `fillWidth` the remaining width. Children may expose `shapeMorphExpansion`
// (a pressed button grows and pushes its neighbours). `signature` reads every input the layout
// depends on, so a change in a child's implicitWidth, implicitHeight, visible, fillWidth or
// shapeMorphExpansion, or in this item's width or spacing, schedules one relayout (like polish).
Item {
    id: root

    final property real spacing: 0

    readonly final property string signature: ButtonRowHelpers.signature(width, spacing, children)

    onSignatureChanged: Qt.callLater(relayout)
    Component.onCompleted: Qt.callLater(relayout)

    function isRepeater(item: Item): bool {
        return ButtonRowHelpers.isRepeater(item);
    }

    function morph(item: Item): real {
        return ButtonRowHelpers.morph(item);
    }

    function relayout(): void {
        ButtonRowHelpers.relayout(root);
    }
}
