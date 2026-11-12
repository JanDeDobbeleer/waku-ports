pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Celeste.Config
import Celeste.I18n
import qs.components
import qs.services

// Port: the Utilities tab. Buttons that open Windows' own windows, flyouts and settings pages
// (UtilitiesActions); a click launches the target and closes the dashboard.
Item {
    id: root

    required property ScreenState screenState

    readonly property int columns: 6
    readonly property real tileWidth: (implicitWidth - Tokens.spacing.small * (columns - 1)) / columns

    implicitWidth: Tokens.px(840)
    implicitHeight: layout.implicitHeight

    Component.onCompleted: UtilitiesActions.probe()

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.medium

        Repeater {
            model: UtilitiesActions.groups

            ColumnLayout {
                id: group

                required property var modelData
                readonly property var items: UtilitiesActions.inGroup(modelData.id)

                Layout.fillWidth: true
                visible: items.length > 0
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.leftMargin: Tokens.padding.medium
                    text: group.modelData.label
                    font: Tokens.styled("body", "medium", { weight: Font.DemiBold })
                    color: Colours.palette.m3onSurface
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: group.items

                        Tile {}
                    }
                }
            }
        }
    }

    component Tile: StyledRect {
        id: tile

        required property var modelData

        implicitWidth: root.tileWidth
        implicitHeight: Tokens.px(92)
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        StateLayer {
            radius: tile.radius
            color: Colours.palette.m3onSurface
            onClicked: {
                root.screenState.dashboard = false;
                UtilitiesActions.launch(tile.modelData.id);
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - Tokens.padding.medium * 2
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: tile.modelData.icon
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.large
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: tile.modelData.label
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
