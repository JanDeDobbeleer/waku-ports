import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Celeste.Config
import qs.components
import qs.services
import qs.utils
import "ActiveWindowHelpers.js" as ActiveWindowHelpers

Item {
    id: root

    required final property PopoutState popouts

    // The window the bar list points at, else the focused one.
    readonly final property HyprToplevel shown: Hypr.hoverToplevel ?? Hypr.activeToplevel

    implicitWidth: shown ? child.implicitWidth : -Tokens.padding.extraLargeIncreased
    implicitHeight: child.implicitHeight

    Column {
        id: child

        anchors.centerIn: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            id: detailsRow

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Tokens.spacing.medium

            IconImage {
                id: icon

                asynchronous: true
                Layout.alignment: Qt.AlignVCenter
                implicitSize: details.implicitHeight
                source: ActiveWindowHelpers.iconPath(root.shown, Icons)
            }

            ColumnLayout {
                id: details

                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: ActiveWindowHelpers.title(root.shown)
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: ActiveWindowHelpers.appClass(root.shown)
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }
            }
        }
    }
}
