import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// Port: one button below the workspace dots that shows the komorebi layout of the active
// workspace. Click: next layout. Wheel (see Bar.handleWheel): previous or next. Each workspace
// keeps its own layout, so this changes the layout of the desktop that is active now.
Item {
    id: root

    readonly property var info: ({
            "BSP": {"icon": "view_quilt", "mirror": false},
            "Columns": {"icon": "view_column", "mirror": false},
            "Rows": {"icon": "table_rows", "mirror": false},
            "VerticalStack": {"icon": "view_sidebar", "mirror": false},
            "HorizontalStack": {"icon": "view_agenda", "mirror": false},
            "UltrawideVerticalStack": {"icon": "view_week", "mirror": false},
            "Grid": {"icon": "grid_view", "mirror": false},
            "RightMainVerticalStack": {"icon": "view_sidebar", "mirror": true}
        })

    readonly property var workspace: Hypr.focusedWorkspace
    readonly property int wsId: workspace?.id ?? -1
    readonly property string stateLayout: workspace?.layoutName ?? ""
    // The click shows its layout at once; komorebi's state replaces it (or a timeout does).
    property string optimistic: ""
    property int optimisticWs: -1
    readonly property string layoutName: optimistic !== "" && optimisticWs === wsId ? optimistic : stateLayout
    readonly property bool active: Hypr.komorebi && wsId >= 0 && stateLayout !== ""
    readonly property string glyph: info[layoutName]?.icon ?? "dashboard"

    // Runs a step of the layout cycle: "next" or "previous". `dry` logs the command only.
    function cycle(direction: string, dry = Paths.dryRun): string {
        if (!active)
            return "none";
        const names = Hypr.layoutNames;
        const idx = names.indexOf(layoutName);
        if (!Hypr.cycleLayout(direction, dry))
            return "none";
        if (idx >= 0) {
            optimistic = names[(idx + (direction === "next" ? 1 : names.length - 1)) % names.length];
            optimisticWs = wsId;
            resetTimer.restart();
        }
        return "cycle-layout " + direction;
    }

    function click(dry = Paths.dryRun): string {
        return cycle("next", dry);
    }

    // For the test IPC: glyph, active workspace, layout and visibility.
    function debugState(): string {
        return "glyph=" + glyph + " ws=" + wsId + " layout=" + layoutName + " state=" + stateLayout + " visible=" + active;
    }

    implicitWidth: active ? icon.implicitHeight + Tokens.padding.small : 0
    implicitHeight: active ? icon.implicitHeight : 0
    opacity: active ? 1 : 0

    onStateLayoutChanged: optimistic = ""

    Timer {
        id: resetTimer

        interval: 1500
        onTriggered: root.optimistic = ""
    }

    StyledRect {
        anchors.centerIn: parent
        implicitWidth: icon.implicitHeight + Tokens.padding.small
        implicitHeight: implicitWidth
        radius: Tokens.rounding.full
        color: Colours.tPalette.m3surfaceContainer
    }

    StateLayer {
        // Same trick as the power button: larger than the parent.
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full
        color: Colours.palette.m3onSurface
        onClicked: root.click()
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        text: root.glyph
        fill: 1
        grade: 25
        color: Colours.palette.m3onSurface
        transform: Scale {
            origin.x: icon.width / 2
            xScale: root.info[root.layoutName]?.mirror ? -1 : 1
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
