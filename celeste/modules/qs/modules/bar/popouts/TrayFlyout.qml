pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Celeste.Config
import Celeste.I18n
import qs.components
import qs.modules.bar.components
import qs.services

// Port: all tray icons in a grid, with the name of the one under the cursor below. Clicks go to
// the item: left activates, middle secondary-activates, right shows the item's own menu.
ColumnLayout {
    id: root

    readonly final property int columns: 4
    readonly final property int cell: Tokens.font.body.small.pointSize * 3
    final property string hovered: ""

    spacing: Tokens.spacing.small

    StyledText {
        Layout.topMargin: Tokens.padding.medium
        text: Tr.tr("Tray")
        font: Tokens.styled("body", "medium", { weight: Font.Medium })
    }

    Grid {
        Layout.alignment: Qt.AlignHCenter
        columns: Math.min(root.columns, Math.max(1, TrayItems.count))
        spacing: Tokens.spacing.small

        Repeater {
            model: TrayItems.items

            Item {
                id: slot

                required final property var modelData

                implicitWidth: root.cell
                implicitHeight: root.cell

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.small
                    color: Qt.alpha(Colours.palette.m3onSurface, icon.containsMouse ? 0.1 : 0)
                }

                TrayItem {
                    id: icon

                    anchors.centerIn: parent
                    modelData: slot.modelData
                    onContainsMouseChanged: {
                        if (containsMouse)
                            root.hovered = name;
                        else if (root.hovered === name)
                            root.hovered = "";
                    }
                }
            }
        }
    }

    // Port: the name of the icon under the cursor, empty otherwise (the bar button's badge already
    // shows the count). The height is kept, so the flyout does not jump when a name appears.
    StyledText {
        id: caption

        Layout.fillWidth: true
        Layout.preferredWidth: root.columns * root.cell + (root.columns - 1) * Tokens.spacing.small
        Layout.preferredHeight: captionMetrics.height
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.hovered
        color: Colours.palette.m3onSurfaceVariant

        TextMetrics {
            id: captionMetrics

            font: caption.font
            text: "X"
        }
    }
}
