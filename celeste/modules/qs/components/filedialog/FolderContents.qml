pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Celeste.Config
import Celeste.I18n
import Celeste.Models
import Celeste.Multimedia
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.filedialog
import qs.services
import "FileDialogHelpers.js" as FileDialogHelpers
import qs.utils

Item {
    id: root

    required final property var dialog
    readonly final property FileEntry currentItem: view.currentItem as FileEntry

    StyledRect {
        anchors.fill: parent
        color: Colours.tPalette.m3surfaceContainer

        layer.enabled: true
        layer.effect: Mask {
            maskSource: mask
            maskInverted: true
        }
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            radius: Tokens.rounding.medium
        }
    }

    Loader {
        asynchronous: true
        anchors.centerIn: parent

        opacity: view.count === 0 ? 1 : 0
        active: opacity > 0

        sourceComponent: ColumnLayout {
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "scan_delete"
                color: Colours.palette.m3outline
                fontStyle: Tokens.styled("icon", "extraLarge", { scale: 2, weight: Font.Medium })
            }

            StyledText {
                text: Tr.tr("This folder is empty")
                color: Colours.palette.m3outline
                font: Tokens.styled("body", "large", { weight: Font.Medium })
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    GridView {
        id: view

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall + Tokens.padding.medium

        cellWidth: Sizes.itemWidth + Tokens.spacing.small
        cellHeight: Sizes.itemWidth + Tokens.spacing.large + Tokens.padding.medium * 2 + 1

        clip: true
        focus: true
        currentIndex: -1
        Keys.onEscapePressed: currentIndex = -1

        Keys.onReturnPressed: {
            FileDialogHelpers.acceptSelection(root.dialog, (currentItem as FileEntry).modelData);
        }
        Keys.onEnterPressed: {
            FileDialogHelpers.acceptSelection(root.dialog, (currentItem as FileEntry).modelData);
        }

        model: FileSystemModel {
            path: {
                return FileDialogHelpers.modelPath(root.dialog, Paths.home);
            }
            onPathChanged: view.currentIndex = -1
        }

        delegate: FileEntry {}

        add: Transition {
            Anim {
                properties: "opacity,scale"
                from: 0
                to: 1
            }
        }

        remove: Transition {
            Anim {
                type: Anim.DefaultEffects
                property: "opacity"
                to: 0
            }
            Anim {
                property: "scale"
                to: 0.5
            }
        }

        displaced: Transition {
            Anim {
                type: Anim.DefaultEffects
                properties: "opacity,scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }
    }

    // waku: the attached ScrollBar.vertical does not exist in pure QML; place the bar by hand.
    StyledScrollBar {
        flickable: view
        anchors.top: view.top
        anchors.bottom: view.bottom
        anchors.right: view.right
    }

    CurrentItem {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.extraSmall

        currentItem: view.currentItem
    }

    component FileEntry: StyledRect {
        id: item

        required final property int index
        required final property FileSystemEntry modelData

        readonly final property real nonAnimHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Tokens.padding.medium * 2

        implicitWidth: Sizes.itemWidth
        implicitHeight: nonAnimHeight

        radius: Tokens.rounding.large
        color: Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, GridView.isCurrentItem ? Colours.tPalette.m3surfaceContainerHighest.a : 0)
        z: GridView.isCurrentItem || implicitHeight !== nonAnimHeight ? 1 : 0
        clip: true

        StateLayer {
            onClicked: view.currentIndex = item.index
            onDoubleClicked: {
                FileDialogHelpers.openItem(root.dialog, item.modelData);
            }
        }

        Visual {
            id: icon

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Tokens.padding.medium

            implicitWidth: Sizes.itemWidth - Tokens.padding.medium * 2
            implicitHeight: implicitWidth
            fillMode: VisualSource.PreserveAspectFit

            // Port: only images are thumbnails. There is no freedesktop icon theme here, so
            // folders and other files get a Material icon instead (see glyph below).
            visible: item.modelData.isImage

            Component.onCompleted: {
                const file = item.modelData;
                if (file.isImage)
                    source = file.path.startsWith("file:") ? file.path : "file:///" + file.path.replace(/\\/g, "/").replace(/^\/+/, "");
            }
        }

        MaterialIcon {
            anchors.centerIn: icon
            visible: !item.modelData.isImage
            text: FileDialogHelpers.iconText(root.dialog, item.modelData)
            color: Colours.palette.m3primary
            fill: 1
            fontStyle: Tokens.styled("icon", "extraLarge", { scale: 1.6 })
        }

        StyledText {
            id: name

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: icon.bottom
            anchors.topMargin: Tokens.spacing.small
            anchors.margins: Tokens.padding.medium

            horizontalAlignment: Text.AlignHCenter
            elide: item.GridView.isCurrentItem ? Text.ElideNone : Text.ElideRight
            wrapMode: item.GridView.isCurrentItem ? Text.WrapAtWordBoundaryOrAnywhere : Text.NoWrap

            Component.onCompleted: text = item.modelData.name
        }

        Behavior on implicitHeight {
            Anim {}
        }
    }
}
