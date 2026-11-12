pragma ComponentBehavior: Bound

import QtQuick
import Celeste.Config
import qs.components
import qs.services
import qs.utils
import "AppsData.js" as AD

// Port: the running-applications list. It replaces upstream's rotated active-window label (the
// bar entry keeps the id "activeWindow", so the layout and the config stay as they were) and
// shows one icon per application (`Hypr.appGroups`: the windows of every virtual desktop,
// grouped by executable, in first-seen order). The application
// with the focused window sits on a rounded primary pill, like the active workspace. An
// application with several windows has a count badge. An application with windows on other
// workspaces only is dimmed, and so is one whose windows are all minimized (with a dash below the
// icon). A click
// raises the window, restoring a minimized one (`Hypr.clickGroup`: for a group the
// focused window's next sibling, else the last focused one), switching to its workspace first
// when needed. Hovering an icon opens upstream's "activewindow" popout for a single window
// (`Hypr.hoverToplevel`), or the "appgroup" popout that lists the windows of a group.
//
// Long lists: the cell shrinks from the full bar width to 70% of it. Beyond that, the list shows
// as many windows as fit (the focused one always among them) and a "+N" cell for the rest. It
// never scrolls: the bar's wheel already controls the volume and the brightness.
Item {
    id: root

    required final property var bar

    readonly final property var all: Hypr.appGroups
    readonly final property string focusedAddress: Hypr.focusedHwnd

    readonly final property real fullCell: Tokens.sizes.bar.innerWidth
    readonly final property real minCell: Math.round(fullCell * 0.7)
    readonly final property real gap: Tokens.spacing.extraSmall

    // Height left for this entry: the bar minus the other entries, their spacing and some room
    // for the two spacers.
    readonly final property real avail: {
        return AD.avail(bar, fullCell);
    }
    readonly final property int count: all.length
    readonly final property real cell: count > 0 ? Math.max(minCell, Math.min(fullCell, (avail + gap) / count - gap)) : fullCell
    readonly final property int capacity: Math.max(1, Math.floor((avail + gap) / (cell + gap)))
    readonly final property bool overflow: count > capacity
    readonly final property var shown: AD.shown(all, overflow, capacity, focusedAddress)

    // The click handler of every icon (the test IPC calls it too). Returns what happened.
    function clickApp(i: int): string {
        const g = groupAt(i);
        return g ? Hypr.clickGroup(g) : "none";
    }

    // Index in `shown` of the group with the focused window, or -1.
    function focusedIndex(): int {
        return AD.focusedIndex(shown, focusedAddress);
    }

    // The icon of the group with this key, or null.
    function groupAt(i: int): HyprGroup {
        return AD.groupAt(shown, i);
    }

    function appForKey(key: string): Item {
        return AD.appForKey(column.children, key);
    }

    // The icon under local y, or null.
    function appAt(y: real): Item {
        return AD.appAt(column, width / 2, y);
    }
    Component.onCompleted: Hypr.barWindow = Window.window

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: column.implicitHeight

    Column {
        id: column

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.gap

        Repeater {
            model: root.shown.length

            delegate: Item {
                id: app

                required final property int index
                readonly final property HyprGroup modelData: root.groupAt(index)

                readonly final property bool isApp: true
                readonly final property int windowCount: AD.windowCount(modelData)
                readonly final property bool focused: AD.winFocused(modelData, root.focusedAddress)
                readonly final property bool onActiveWs: AD.onActiveWs(modelData)
                // Every window of the application is minimized: dimmed, with a dash below the icon.
                readonly final property bool allMinimized: AD.allMinimized(modelData)
                readonly final property bool hasImage: image.source.toString() !== "" && image.status !== Image.Error
                readonly final property string progressState: modelData.progressState
                readonly final property real progress: modelData.progress
                readonly final property bool hasProgress: progressState !== "none"
                readonly final property bool busy: AD.busy(modelData)

                width: root.fullCell
                height: root.cell
                opacity: hasProgress || busy || ((onActiveWs || focused) && !allMinimized) ? 1 : 0.55

                // A second card behind the icon marks a group.
                StyledRect {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.px(3)
                    anchors.rightMargin: -Tokens.px(3)
                    visible: app.windowCount > 1 && !app.focused
                    radius: Tokens.rounding.full
                    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                    opacity: 0.6
                }

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.full
                    color: app.focused ? Colours.palette.m3primary : "transparent"
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: !app.hasImage
                    grade: 0
                    text: Icons.getAppCategoryIcon(app.modelData.exe, "desktop_windows")
                    color: app.focused ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                }

                Image {
                    id: image

                    anchors.centerIn: parent
                    width: Math.round(root.cell * 0.6)
                    height: width
                    visible: app.hasImage
                    source: app.modelData.icon
                    sourceSize: Qt.size(width * 2, height * 2)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    mipmap: true
                }

                // The minimized mark: a short dash below the icon.
                StyledRect {
                    visible: app.allMinimized && !app.focused && !app.hasProgress && !app.busy
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.round(root.cell * 0.06)
                    implicitWidth: Math.round(root.cell * 0.3)
                    implicitHeight: Math.max(2, Tokens.px(3))
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3onSurface
                }

                // The progress mark: a dot below the icon that pulses while the app is working.
                Rectangle {
                    id: progressDot

                    readonly final property bool steady: app.progressState === "error" || app.progressState === "paused"

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.round(root.cell * 0.06)
                    width: Math.max(4, Tokens.px(5))
                    height: width
                    radius: width / 2
                    visible: app.hasProgress || app.busy
                    color: app.progressState === "error" ? Colours.palette.m3error : app.progressState === "paused" ? Colours.palette.m3tertiary : app.focused ? Colours.palette.m3onPrimary : Colours.palette.m3primary

                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: progressDot.visible && !progressDot.steady
                        onRunningChanged: {
                            if (!running) {
                                progressDot.scale = 1;
                                progressDot.opacity = 1;
                            }
                        }

                        ParallelAnimation {
                            NumberAnimation {
                                target: progressDot
                                property: "scale"
                                from: 1
                                to: 1.6
                                duration: 700
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                target: progressDot
                                property: "opacity"
                                from: 1
                                to: 0.45
                                duration: 700
                                easing.type: Easing.InOutSine
                            }
                        }

                        ParallelAnimation {
                            NumberAnimation {
                                target: progressDot
                                property: "scale"
                                from: 1.6
                                to: 1
                                duration: 700
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                target: progressDot
                                property: "opacity"
                                from: 0.45
                                to: 1
                                duration: 700
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }

                // The count of windows, at the icon's top-right corner.
                StyledRect {
                    visible: app.windowCount > 1
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: -Tokens.px(2)
                    implicitWidth: Math.max(implicitHeight, badge.implicitWidth + Tokens.px(6))
                    implicitHeight: badge.implicitHeight + Tokens.px(2)
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3tertiary

                    StyledText {
                        id: badge

                        anchors.centerIn: parent
                        text: app.windowCount
                        color: Colours.palette.m3onTertiary
                        font: Tokens.font.label.small
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // The hover flyout has done its job once an app is chosen. Switching to
                        // a window on another desktop can swallow the hover exit that would
                        // otherwise close it.
                        AD.closePopout(root.bar);
                        root.clickApp(app.index);
                    }
                }
            }
        }

        // "+N": the windows that do not fit.
        Item {
            readonly final property bool isApp: false

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
