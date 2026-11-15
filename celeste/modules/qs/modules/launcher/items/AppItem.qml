import QtQuick
import Quickshell
import Quickshell.Widgets
import Celeste.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services
import "../AppListHelpers.js" as AppListHelpers

Item {
    id: root

    required final property var modelData
    required final property ScreenState screenState

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        objectName: "rowClick"

        radius: Tokens.rounding.large
        onClicked: {
            Apps.launch(root.modelData);
            root.screenState.launcher = false;
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        IconImage {
            id: icon

            asynchronous: true
            source: Quickshell.iconPath(AppListHelpers.stringField(root.modelData, "icon"), "image-missing")
            implicitSize: parent.height * 0.8

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width - favouriteIcon.width
            implicitHeight: name.implicitHeight + comment.implicitHeight

            StyledText {
                id: name

                text: AppListHelpers.stringField(root.modelData, "name")
                font: Tokens.font.body.medium
            }

            StyledText {
                id: comment

                text: AppListHelpers.stringField(root.modelData, "comment") || AppListHelpers.stringField(root.modelData, "genericName") || AppListHelpers.stringField(root.modelData, "name")
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - favouriteIcon.width - Tokens.rounding.extraLargeIncreased

                anchors.top: name.bottom
            }
        }

        Loader {
            id: favouriteIcon

            asynchronous: true
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            active: AppListHelpers.isFavourite(root.modelData, GlobalConfig.launcher.favouriteApps, Strings)

            sourceComponent: MaterialIcon {
                text: "favorite"
                fill: 1
                color: Colours.palette.m3primary
            }
        }
    }
}
