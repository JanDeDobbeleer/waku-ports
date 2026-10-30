pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// Port: the running-applications list. It replaces upstream's rotated active-window label (the
// bar entry keeps the id "activeWindow", so the layout and the config stay as they were) and
// shows one icon per window komorebi manages, on every workspace, plus floating ones: the
// `Hypr.toplevels` join. The focused window sits on a rounded primary pill, like the active
// workspace. A window of another workspace is dimmed. A click raises the window
// (`Hypr.activateToplevel`), switching to its workspace first when needed. Hovering an icon
// opens upstream's "activewindow" popout for that window (`Hypr.hoverToplevel`).
//
// Long lists: the cell shrinks from the full bar width to 70% of it. Beyond that, the list shows
// as many windows as fit (the focused one always among them) and a "+N" cell for the rest. It
// never scrolls: the bar's wheel already controls the volume and the brightness.
Item {
    id: root

    required property var bar

    readonly property var all: Hypr.toplevels.values.filter(t => !!t.address)
    readonly property string focusedAddress: Hypr.focusedHwnd

    readonly property real fullCell: Tokens.sizes.bar.innerWidth
    readonly property real minCell: Math.round(fullCell * 0.7)
    readonly property real gap: Tokens.spacing.extraSmall

    // Height left for this entry: the bar minus the other entries, their spacing and some room
    // for the two spacers.
    readonly property real avail: {
        const others = bar.children.filter(c => c.entryId && c.entryId !== "activeWindow" && c.entryId !== "spacer");
        const otherHeight = others.reduce((acc, curr) => acc + (curr.item?.nonAnimHeight ?? curr.height), 0);
        return Math.max(0, bar.height - otherHeight - bar.spacing * (bar.children.length - 1) - bar.vPadding * 2 - fullCell * 2);
    }
    readonly property int count: all.length
    readonly property real cell: count > 0 ? Math.max(minCell, Math.min(fullCell, (avail + gap) / count - gap)) : fullCell
    readonly property int capacity: Math.max(1, Math.floor((avail + gap) / (cell + gap)))
    readonly property bool overflow: count > capacity
    readonly property var shown: {
        if (!overflow)
            return all;
        const keep = Math.max(1, capacity - 1);
        const out = all.slice(0, keep);
        const f = all.find(t => t.address === focusedAddress);
        if (f && !out.includes(f))
            out[keep - 1] = f;
        return out;
    }

    // The click handler of every icon (the test IPC calls it too). Returns what happened.
    function clickApp(i: int): string {
        const t = shown[i];
        return t ? Hypr.activateToplevel(t) : "none";
    }

    // Index in `shown` of the focused window, or -1.
    function focusedIndex(): int {
        return shown.findIndex(t => t.address === focusedAddress);
    }

    // The icon under local y, or null.
    function appAt(y: real): var {
        const c = column.childAt(width / 2, y);
        return c?.isApp ? c : null;
    }

    Component.onCompleted: Hypr.barWindow = Window.window

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: column.implicitHeight

    Column {
        id: column

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.gap

        Repeater {
            model: ScriptModel {
                values: root.shown
            }

            delegate: Item {
                id: app

                required property var modelData
                required property int index

                readonly property bool isApp: true
                readonly property bool focused: modelData.address === root.focusedAddress
                readonly property bool onActiveWs: modelData.wsActive !== false
                readonly property bool hasImage: image.source.toString() !== "" && image.status !== Image.Error

                width: root.fullCell
                height: root.cell
                opacity: onActiveWs || focused ? 1 : 0.55

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.full
                    color: app.focused ? Colours.palette.m3primary : "transparent"
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: !app.hasImage
                    grade: 0
                    text: Icons.getAppCategoryIcon(app.modelData.lastIpcObject.class, "desktop_windows")
                    color: app.focused ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                }

                Image {
                    id: image

                    anchors.centerIn: parent
                    width: Math.round(root.cell * 0.6)
                    height: width
                    visible: app.hasImage
                    source: app.modelData.icon ?? ""
                    sourceSize: Qt.size(width * 2, height * 2)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clickApp(app.index)
                }
            }
        }

        // "+N": the windows that do not fit.
        Item {
            readonly property bool isApp: false

            visible: root.overflow
            width: root.fullCell
            height: visible ? root.cell : 0

            StyledText {
                anchors.centerIn: parent
                text: "+" + (root.count - root.shown.length)
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
