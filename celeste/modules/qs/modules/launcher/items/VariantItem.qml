import QtQuick
import Celeste.Config
import qs.components
import qs.services
import qs.modules.launcher.services
import "LauncherItemHelpers.js" as LauncherItemHelpers

Item {
    id: root

    required final property var modelData
    required final property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        objectName: "rowClick"

        radius: Tokens.rounding.large
        onClicked: LauncherItemHelpers.invoke(root.modelData, root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        MaterialIcon {
            id: icon

            text: LauncherItemHelpers.field(root.modelData, "icon")
            fontStyle: Tokens.font.icon.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.large
            anchors.verticalCenter: icon.verticalCenter

            width: parent.width - icon.width - anchors.leftMargin - (current.active ? current.width + Tokens.spacing.medium : 0)
            spacing: 0

            StyledText {
                text: LauncherItemHelpers.field(root.modelData, "name")
                font: Tokens.font.body.medium
            }

            StyledText {
                text: LauncherItemHelpers.field(root.modelData, "description")
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        Loader {
            id: current

            asynchronous: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            active: LauncherItemHelpers.isCurrentVariant(root.modelData, Schemes.currentVariant)

            sourceComponent: MaterialIcon {
                text: "check"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.large
            }
        }
    }
}
