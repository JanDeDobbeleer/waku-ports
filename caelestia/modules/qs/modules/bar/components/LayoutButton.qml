import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import waku.services as S

// Port: one button below the workspace dots that shows the layout of waku's tiler for the focused
// workspace (each desktop and monitor keeps its own). Click: next layout. Wheel (see
// Bar.handleWheel): previous or next. Hidden while the tiler is off.
Item {
    id: root

    readonly property var info: ({
            "mainStack": {"icon": "view_sidebar"},
            "mainStackTop": {"icon": "view_agenda"},
            "columns": {"icon": "view_column"},
            "rows": {"icon": "table_rows"},
            "bsp": {"icon": "view_quilt"},
            "grid": {"icon": "grid_view"},
            "centerMain": {"icon": "view_week"}
        })

    readonly property string layoutName: S.Tiling.currentLayout
    readonly property bool active: S.Tiling.active && layoutName !== ""
    readonly property string glyph: info[layoutName]?.icon ?? "dashboard"

    // Runs a step of the layout cycle: "next" or "previous". `dry` logs the command only.
    function cycle(direction: string, dry = Paths.dryRun): string {
        if (!active)
            return "none";
        if (dry) {
            console.log("dry run: tile layout " + direction);
            return "cycle-layout " + direction;
        }
        S.Tiling.cycleLayout(direction === "next" ? 1 : -1);
        return "cycle-layout " + direction;
    }

    function click(dry = Paths.dryRun): string {
        return cycle("next", dry);
    }

    // For the test IPC: glyph, layout and visibility.
    function debugState(): string {
        return "glyph=" + glyph + " layout=" + layoutName + " visible=" + active;
    }

    implicitWidth: active ? icon.implicitHeight + Tokens.padding.small : 0
    implicitHeight: active ? icon.implicitHeight : 0
    opacity: active ? 1 : 0

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
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
