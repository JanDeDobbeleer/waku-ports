import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Port: the flyout of an application with several windows (the apps list in the bar). One row per
// window: icon, title, the workspace it is on; the focused window is highlighted. A click jumps to
// the window with the same flow as a click on a single icon (`Hypr.activateToplevel`).
Item {
    id: root

    required property PopoutState popouts

    readonly property var group: Hypr.appGroups.find(g => g.key === Hypr.hoverGroupKey) ?? null

    implicitWidth: group ? Tokens.px(300) : 0
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col

        width: root.width
        spacing: Tokens.spacing.extraSmall

        Repeater {
            model: root.group?.windows ?? []

            delegate: Item {
                id: row

                required property var modelData
                required property int index

                readonly property bool focused: modelData.address === Hypr.focusedHwnd

                Layout.fillWidth: true
                implicitHeight: line.implicitHeight + Tokens.padding.small * 2

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.small
                    color: row.focused ? Colours.palette.m3secondaryContainer : (hover.containsMouse ? Colours.layer(Colours.palette.m3surfaceContainer, 2) : "transparent")
                }

                RowLayout {
                    id: line

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    spacing: Tokens.spacing.medium

                    Image {
                        Layout.preferredWidth: Tokens.px(20)
                        Layout.preferredHeight: Tokens.px(20)
                        source: row.modelData.icon ?? ""
                        sourceSize: Qt.size(width * 2, height * 2)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.title
                        elide: Text.ElideRight
                        color: row.focused ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    }

                    StyledText {
                        text: Hypr.workspaceLabel(row.modelData)
                        color: row.focused ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                    }
                }

                MouseArea {
                    id: hover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hypr.activateToplevel(row.modelData)
                }
            }
        }
    }
}
