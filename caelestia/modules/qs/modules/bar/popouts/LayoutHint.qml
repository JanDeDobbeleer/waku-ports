import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Port: the hint of the layout glyph under the active workspace dot.
Item {
    id: root

    readonly property string layoutName: Hypr.focusedWorkspace?.layoutName ?? ""

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col

        anchors.centerIn: parent
        spacing: 0

        StyledText {
            text: root.layoutName.replace(/([a-z])([A-Z])/g, "$1 $2")
            font: Tokens.font.body.medium
        }

        StyledText {
            text: "Click or scroll to change"
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }
    }
}
