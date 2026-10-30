import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia
import Caelestia.Services
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.launcher as Launcher
import qs.modules.osd as Osd
import qs.modules.session as Session

// WP6 harness: hosts the launcher, OSD and session wrappers the way upstream's Panels.qml does,
// in one 900x700 centred PanelWindow (no exclusive zone). The drawers shell (WP5) is not merged
// yet, so the blob backgrounds are plain rounded rectangles. Shortcuts: launcher, osd, session.
// Environment, for a test run that cannot type:
//   WP6_OPEN    launcher, osd or session: opens it 7 s after the start (no shortcut needed).
//   WP6_SEARCH  text put into the launcher search field 0.7 s after the launcher opens.
ShellRoot {
    id: root

    readonly property var scr: Quickshell.screens[0]

    ScreenState {
        id: ss

        modelData: root.scr
    }

    // Stand-in for the other Panels members the launcher reads.
    QtObject {
        id: otherPanels

        readonly property QtObject bar: QtObject {
            readonly property real implicitWidth: 0
        }
        readonly property QtObject popouts: QtObject {
            readonly property bool hasCurrent: false
            readonly property real currentCenter: 0
            readonly property real nonAnimHeight: 0
            readonly property real nonAnimWidth: 0
        }
        readonly property QtObject utilities: QtObject {
            readonly property real implicitWidth: 0
        }
        readonly property QtObject dashboard: QtObject {
            readonly property real nonAnimHeight: 0
        }
    }

    GlobalShortcut {
        name: "launcher"
        onPressed: ss.launcher = !ss.launcher
    }

    GlobalShortcut {
        name: "osd"
        onPressed: osd.show()
    }

    GlobalShortcut {
        name: "session"
        onPressed: ss.session = !ss.session
    }

    PanelWindow {
        id: win

        screen: root.scr
        anchors.top: true
        anchors.left: true
        margins.left: Math.max(0, ((root.scr?.width ?? 1920) / (root.scr?.devicePixelRatio ?? 1) - 900) / 2)
        margins.top: Math.max(0, ((root.scr?.height ?? 1080) / (root.scr?.devicePixelRatio ?? 1) - 700) / 2)
        implicitWidth: 900
        implicitHeight: 700
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.keyboardFocus: ss.launcher || ss.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Qt.rgba(0, 0, 0, 0.35)
            border.color: Colours.palette.m3outlineVariant
        }

        Item {
            id: panels

            readonly property alias bar: otherPanels.bar
            readonly property alias popouts: otherPanels.popouts
            readonly property alias utilities: otherPanels.utilities
            readonly property alias dashboard: otherPanels.dashboard

            anchors.fill: parent
            anchors.margins: Config.border.thickness

            // Backgrounds (blobs upstream).
            Rectangle {
                x: launcher.x
                y: launcher.y
                width: launcher.width
                height: launcher.height
                visible: launcher.visible
                opacity: launcher.opacity
                radius: Tokens.rounding.large
                color: Colours.tPalette.m3surface
            }

            Rectangle {
                x: sessionWrapper.x + session.x
                y: sessionWrapper.y + session.y
                width: session.width
                height: session.height
                visible: session.visible
                opacity: session.opacity
                radius: Tokens.rounding.large
                color: Colours.tPalette.m3surface
            }

            Rectangle {
                x: osdWrapper.x + osd.x
                y: osdWrapper.y + osd.y
                width: osd.width
                height: osd.height
                visible: osd.visible
                opacity: osd.opacity
                radius: Tokens.rounding.large
                color: Colours.tPalette.m3surface
            }

            Item {
                id: osdWrapper

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: sessionWrapper.anchors.rightMargin + session.width * (1 - session.offsetScale)
                clip: session.visible

                implicitWidth: osd.implicitWidth * (1 - osd.offsetScale)
                implicitHeight: osd.implicitHeight

                Osd.Wrapper {
                    id: osd

                    screen: root.scr
                    screenState: ss
                    sidebarOrSessionVisible: session.visible

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                }
            }

            Item {
                id: sessionWrapper

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right

                implicitWidth: session.implicitWidth * (1 - session.offsetScale)
                implicitHeight: session.implicitHeight

                Session.Wrapper {
                    id: session

                    screenState: ss
                    sidebarVisible: false

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                }
            }

            Launcher.Wrapper {
                id: launcher

                screen: root.scr
                screenState: ss
                panels: panels

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
            }
        }
    }

    // Debug: type into the search field once, since the harness cannot send keys.
    Timer {
        interval: 700
        running: ss.launcher && !!Quickshell.env("WP6_SEARCH")
        onTriggered: {
            const field = CUtils.findChild(launcher, "launcherSearch");
            console.log("WP6: search field", field, "text ->", Quickshell.env("WP6_SEARCH"));
            if (field)
                field.text = Quickshell.env("WP6_SEARCH");
        }
    }

    Timer {
        interval: 7000
        running: !!Quickshell.env("WP6_OPEN")
        onTriggered: {
            const what = Quickshell.env("WP6_OPEN");
            console.log("WP6: open", what);
            if (what === "osd")
                osd.show();
            else if (what === "session")
                ss.session = true;
            else
                ss.launcher = true;
            console.log("WP6: states", ss.launcher, ss.osd, ss.session);
        }
    }

    Connections {
        function onLauncherChanged() {
            console.log("WP6: launcher ->", ss.launcher);
        }

        target: ss
    }

    // Debug summary after the launcher opened.
    // The harness config home has no assets folder; point the session gif at the port's.
    Component.onCompleted: {
        GlobalConfig.paths.sessionGif = Qt.resolvedUrl("../../assets/kurukuru.gif").toString().replace("file:///", "");
        console.log("WP6: screen", root.scr.width, root.scr.height, root.scr.devicePixelRatio, "window", win.width, win.height);
    }

    Timer {
        interval: 3000
        running: ss.launcher
        onTriggered: {
            const list = CUtils.findChild(launcher, "launcherAppList");
            console.log("WP6: wallpapers", WallpaperService.list.length, WallpaperService.entries.length, WallpaperService.query("").length);
            const wl = CUtils.findChild(launcher, "launcherWallpaperList");
            if (wl)
                console.log("WP6: wallpaper list", wl.count, wl.numItems, wl.pathItemCount, wl.implicitWidth, wl.model.values.length, JSON.stringify(wl.itemWidth));
            // Gate check: only runs while the gate is closed, and the call only logs.
            if (!SessionManager.allowed)
                console.log("WP6: gate", SessionManager.exec(["poweroff"]), SessionManager.lastBlocked, SessionManager.exec(["notepad"]));
            console.log("WP6: DesktopEntries", DesktopEntries.applications.values.length, "list count", list?.count);
        }
    }
}
