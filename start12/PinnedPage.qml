import QtQuick
import waku.services as S

// "Pinned": the apps you pinned, five to a row, and the "All apps" button.
Item {
    id: root

    signal launch(var entry)
    signal context(var entry, var point)
    signal showAll

    // Re-evaluated when the pin list or the catalogue changes.
    readonly property var entries: {
        S.AppsService.count;
        return Pins.ids.map(id => S.AppsService.byId(id)).filter(e => e);
    }

    Text {
        text: "Pinned"
        color: Style.text
        font.family: Style.font
        font.pixelSize: Style.smallSize
        font.weight: Font.DemiBold
    }

    Rectangle {
        anchors.right: parent.right
        width: allText.implicitWidth + chev.width + 20
        height: 24
        radius: 4
        color: allMouse.containsMouse ? Style.hover : "#1affffff"

        Row {
            anchors.centerIn: parent
            spacing: 6
            Text {
                id: allText
                text: "All apps"
                color: Style.text
                font.family: Style.font
                font.pixelSize: Style.smallSize
            }
            Glyph {
                id: chev
                width: 8
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                size: 8
            }
        }
        MouseArea {
            id: allMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.showAll()
        }
    }

    Text {
        visible: root.entries.length === 0
        anchors.centerIn: parent
        text: S.AppsService.ready ? "Nothing is pinned. Pin an app from All apps." : "Loading apps…"
        color: Style.dim
        font.family: Style.font
        font.pixelSize: Style.fontSize
    }

    GridView {
        id: grid
        y: 36
        width: parent.width
        height: parent.height - 36
        clip: true
        cellWidth: Math.floor(width / 5)
        cellHeight: 92
        model: root.entries

        delegate: Item {
            id: cell
            required property var modelData
            width: grid.cellWidth
            height: grid.cellHeight

            AppTile {
                anchors.horizontalCenter: parent.horizontalCenter
                entry: cell.modelData
                onActivated: root.launch(cell.modelData)
                onContextRequested: point => root.context(cell.modelData, point)
            }
        }
    }
}
