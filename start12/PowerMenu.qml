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

    readonly property var actions: [
        { id: "lock", glyph: "", label: "Lock", confirm: "" },
        { id: "sleep", glyph: "", label: "Sleep", confirm: "" },
        { id: "signOut", glyph: "", label: "Sign out", confirm: "Click again to sign out" },
        { id: "restart", glyph: "", label: "Restart", confirm: "Click again to restart" },
        { id: "shutdown", glyph: "", label: "Shut down", confirm: "Click again to shut down" }
    ]

    onVisibleChanged: if (!visible)
        S.ControlCenter.cancelAction()

    Column {
        id: col
        x: 4
        y: 4

        Repeater {
            model: root.actions

            Rectangle {
                id: row
                required property var modelData
                readonly property bool pending: S.ControlCenter.pendingAction === modelData.id

                width: root.width - 8
                height: 36
                radius: 4
                color: pending ? "#40ff9d3b" : m.containsMouse ? Style.hover : "transparent"

                Glyph {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    text: row.modelData.glyph
                    size: 15
                }
                Text {
                    x: 40
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.pending ? row.modelData.confirm : row.modelData.label
                    color: Style.text
                    font.family: Style.font
                    font.pixelSize: Style.fontSize
                }
                MouseArea {
                    id: m
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (S.ControlCenter.requestAction(row.modelData.id))
                            root.done();
                    }
                }
            }
        }
    }
}
