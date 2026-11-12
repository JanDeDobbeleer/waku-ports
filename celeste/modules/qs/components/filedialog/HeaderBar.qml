pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Celeste.Config
import qs.components
import qs.services
import "HeaderBarHelpers.js" as HeaderBarHelpers

StyledRect {
    id: root

    required final property var dialog

    implicitWidth: inner.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.small

        Item {
            implicitWidth: implicitHeight
            implicitHeight: upIcon.implicitHeight + Tokens.padding.small

            StateLayer {
                radius: Tokens.rounding.medium
                disabled: HeaderBarHelpers.isRoot(root.dialog)
                onClicked: HeaderBarHelpers.goUp(root.dialog)
            }

            MaterialIcon {
                id: upIcon

                anchors.centerIn: parent
                text: "drive_folder_upload"
                color: HeaderBarHelpers.isRoot(root.dialog) ? Colours.palette.m3outline : Colours.palette.m3onSurface
                grade: 200
            }
        }

        StyledRect {
            Layout.fillWidth: true

            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainerHigh

            implicitHeight: pathComponents.implicitHeight + pathComponents.anchors.margins * 2

            RowLayout {
                id: pathComponents

                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall / 2
                anchors.leftMargin: 0

                spacing: Tokens.spacing.small

                Repeater {
                    model: HeaderBarHelpers.cwd(root.dialog)

                    RowLayout {
                        id: folder

                        required final property string modelData
                        required final property int index

                        spacing: 0

                        Loader {
                            asynchronous: true
                            Layout.rightMargin: Tokens.spacing.small
                            active: folder.index > 0
                            sourceComponent: StyledText {
                                text: "/"
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.styled("body", "small", { weight: Font.Bold })
                            }
                        }

                        Item {
                            implicitWidth: homeIcon.implicitWidth + (homeIcon.active ? Tokens.padding.extraSmall : 0) + folderName.implicitWidth + Tokens.padding.medium * 2
                            implicitHeight: folderName.implicitHeight + Tokens.padding.small

                            Loader {
                                asynchronous: true
                                anchors.fill: parent
                                active: !HeaderBarHelpers.isLast(root.dialog, folder.index)
                                sourceComponent: StateLayer {
                                    onClicked: {
                                        HeaderBarHelpers.navigate(root.dialog, folder.index);
                                    }

                                    radius: Tokens.rounding.medium
                                }
                            }

                            Loader {
                                id: homeIcon

                                asynchronous: true

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Tokens.padding.medium

                                active: HeaderBarHelpers.isHome(folder.index, folder.modelData)
                                sourceComponent: MaterialIcon {
                                    text: "home"
                                    color: HeaderBarHelpers.isRoot(root.dialog) ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                                    fill: 1
                                }
                            }

                            StyledText {
                                id: folderName

                                anchors.left: homeIcon.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: homeIcon.active ? Tokens.padding.extraSmall : 0

                                text: folder.modelData
                                color: !HeaderBarHelpers.isLast(root.dialog, folder.index) ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
                                font: Tokens.styled("body", "small", { weight: Font.Bold })
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
