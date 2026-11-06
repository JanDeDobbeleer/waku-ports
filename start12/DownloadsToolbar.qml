import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import waku

// The "Downloads" toolbar beside the Start button: a button that opens the newest items of your
// Downloads folder. A click on an item opens it.
Rectangle {
    id: root

    readonly property string dir: "file:///" + String(Quickshell.env("USERPROFILE")).replace(/\\/g, "/") + "/Downloads"

    implicitHeight: 40
    implicitWidth: label.implicitWidth + chevron.width + 36
    radius: 6
    color: mouse.containsMouse || popup.visible ? Style.hover : "transparent"

    Row {
        anchors.centerIn: parent
        spacing: 12
        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            text: "Downloads"
            color: Style.text
            font.family: Style.font
            font.pixelSize: Style.fontSize
        }
        Glyph {
            id: chevron
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            text: ""
            size: 10
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: popup.toggle()
    }

    FolderListModel {
        id: files
        folder: root.dir
        showDirs: true
        showDotAndDotDot: false
        sortField: FolderListModel.Time
        sortReversed: true
    }

    PopupWindow {
        id: popup
        anchor.item: root
        padding: 6

        // FolderListModel.count does not signal a change, so bind to the view's own count.
        Text {
            visible: list.count === 0
            text: "This folder is empty"
            color: Style.dim
            font.family: Style.font
            font.pixelSize: Style.fontSize
            padding: 8
        }

        ListView {
            id: list
            visible: count > 0
            width: 320
            height: Math.min(count, 10) * 34
            clip: true
            model: files
            interactive: count > 10

            delegate: Rectangle {
                id: row
                required property string fileName
                required property url fileUrl
                required property bool fileIsDir

                width: ListView.view.width
                height: 34
                radius: 6
                color: rowMouse.containsMouse ? Style.hover : "transparent"

                Glyph {
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    text: row.fileIsDir ? "" : ""
                    size: 15
                }
                Text {
                    x: 36
                    width: parent.width - 44
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.fileName
                    elide: Text.ElideMiddle
                    color: Style.text
                    font.family: Style.font
                    font.pixelSize: Style.fontSize
                }
                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        Qt.openUrlExternally(row.fileUrl);
                        popup.close();
                    }
                }
            }
        }

        Rectangle {
            width: 320
            height: 34
            radius: 6
            color: openMouse.containsMouse ? Style.hover : "transparent"
            Text {
                x: 36
                anchors.verticalCenter: parent.verticalCenter
                text: "Open Downloads folder"
                color: Style.accent
                font.family: Style.font
                font.pixelSize: Style.fontSize
            }
            MouseArea {
                id: openMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    Qt.openUrlExternally(root.dir);
                    popup.close();
                }
            }
        }
    }
}
