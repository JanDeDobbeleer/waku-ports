import QtQuick
import waku.services as S

// "All apps": every app in the Start Menu, A to Z, with a letter header.
Item {
    id: root

    signal launch(var entry)
    signal context(var entry, var point)
    signal back

    readonly property var rows: {
        S.AppsService.count;
        return S.AppsService.applications.values.filter(e => !e.noDisplay).map(e => {
            const c = e.name.charAt(0).toUpperCase();
            return { entry: e, letter: /[A-Z]/.test(c) ? c : "#" };
        });
    }

    Rectangle {
        id: backButton
        width: backText.implicitWidth + chev.width + 20
        height: 24
        radius: 4
        color: backMouse.containsMouse ? Style.hover : "#1affffff"

        Row {
            anchors.centerIn: parent
            spacing: 6
            Glyph {
                id: chev
                width: 8
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                size: 8
            }
            Text {
                id: backText
                text: "Back"
                color: Style.text
                font.family: Style.font
                font.pixelSize: Style.smallSize
            }
        }
        MouseArea {
            id: backMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.back()
        }
    }

    ListView {
        y: 36
        width: parent.width
        height: parent.height - 36
        clip: true
        model: root.rows
        section.property: "letter"
        section.delegate: Text {
            required property string section
            height: 28
            verticalAlignment: Text.AlignVCenter
            leftPadding: 12
            text: section
            color: Style.accent
            font.family: Style.font
            font.pixelSize: Style.fontSize
            font.weight: Font.DemiBold
        }

        delegate: AppRow {
            id: item
            required property var modelData
            width: ListView.view.width
            entry: modelData.entry
            onActivated: root.launch(modelData.entry)
            onContextRequested: point => root.context(modelData.entry, point)
        }
    }
}
