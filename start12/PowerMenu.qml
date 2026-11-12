pragma ComponentBehavior: Bound

import QtQuick
import waku.services as S

// The power menu. Lock and Sleep run at once. Sign out, Restart and Shut down ask for a second click
// (the engine holds the request for four seconds), so one stray click does not end the session.
Rectangle {
    id: root

    signal done

    width: 200
    height: col.implicitHeight + 8
    radius: 8
    color: "#fa1b273b"
    border.color: Style.menuBorder
    border.width: 1

    ListModel {
        id: actions
        ListElement { action: "lock"; glyph: ""; label: "Lock"; confirm: "" }
        ListElement { action: "sleep"; glyph: ""; label: "Sleep"; confirm: "" }
        ListElement { action: "signOut"; glyph: ""; label: "Sign out"; confirm: "Click again to sign out" }
        ListElement { action: "restart"; glyph: ""; label: "Restart"; confirm: "Click again to restart" }
        ListElement { action: "shutdown"; glyph: ""; label: "Shut down"; confirm: "Click again to shut down" }
    }

    onVisibleChanged: if (!visible)
        S.ControlCenter.cancelAction()

    Column {
        id: col
        x: 4
        y: 4

        Repeater {
            model: actions

            Rectangle {
                id: row
                required property string action
                required property string glyph
                required property string label
                required property string confirm
                readonly property bool pending: S.ControlCenter.pendingAction === action

                width: root.width - 8
                height: 36
                radius: 4
                color: pending ? "#40ff9d3b" : m.containsMouse ? Style.hover : "transparent"

                Glyph {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    text: row.glyph
                    size: 15
                }
                Text {
                    x: 40
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.pending ? row.confirm : row.label
                    color: Style.text
                    font.family: Style.font
                    font.pixelSize: Style.fontSize
                }
                MouseArea {
                    id: m
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (S.ControlCenter.requestAction(row.action))
                            root.done();
                    }
                }
            }
        }
    }
}
