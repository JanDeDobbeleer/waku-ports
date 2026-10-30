pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.bar

StyledWindow {
    id: root

    readonly property alias bar: bar
    readonly property alias interactionWrapper: interactions

    readonly property ScreenState screenState: ShellState.forScreen(screen)

    readonly property var monitor: Hypr.monitorFor(screen)
    readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject.specialWorkspace?.name.length ?? 0) > 0
    readonly property bool hasFullscreenOnNormalWs: monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false
    readonly property bool hasFullscreen: {
        if (hasSpecialWorkspace) {
            const specialName = monitor?.lastIpcObject.specialWorkspace?.name;
            if (!specialName)
                return false;
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
        }
        return hasFullscreenOnNormalWs;
    }

    property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly property real sdfBorderOffset: 2 * fsTransitionProg // SDFs joins are not exact, so offset by 2px to ensure nothing shows
    readonly property real borderThickness: Config.border.thickness * (1 - fsTransitionProg)
    readonly property real borderRounding: Config.border.rounding * (1 - fsTransitionProg)
    readonly property real shadowOpacity: 0.7 * (1 - fsTransitionProg)
    readonly property real borderLayoutThickness: hasFullscreen ? 0 : Config.border.thickness

    property color surfaceColour: Colours.tPalette.m3surface

    readonly property int dragMaskPadding: {
        if (focusGrab.active || panels.popouts.isDetached)
            return 0;

        if (monitor?.lastIpcObject.specialWorkspace?.name || monitor?.activeWorkspace?.toplevels.values.length > 0)
            return 0;

        const thresholds = [];
        for (const panel of ["dashboard", "launcher", "session", "sidebar"])
            if (contentItem.Config[panel].enabled)
                thresholds.push(contentItem.Config[panel].dragThreshold);
        return Math.max(...thresholds);
    }

    onHasFullscreenChanged: {
        screenState.launcher = false;
        screenState.session = false;
        screenState.dashboard = false;
        panels.popouts.close();
    }

    name: "drawers"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: (fsTransitionProg > 0 && Config.general.showOverFullscreen) || (hasSpecialWorkspace && hasFullscreenOnNormalWs) ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: screenState.launcher || screenState.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: hasFullscreen ? emptyRegion : regions

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Behavior on fsTransitionProg {
        Anim {}
    }

    Behavior on surfaceColour {
        CAnim {}
    }

    Region {
        id: emptyRegion

        x: panels.notifications.x + bar.implicitWidth
        y: panels.notifications.y + root.borderThickness
        width: panels.notifications.width
        height: panels.notifications.height

        Region {
            // Port: x reads w_, not width (wabar's Region has one change signal for its geometry).
            readonly property real w_: panels.osdWrapper.width * (1 - panels.osd.offsetScale) + root.borderThickness

            x: root.width - w_
            y: panels.osdWrapper.y + root.borderThickness
            width: w_
            height: panels.osd.height
        }
    }

    Regions {
        id: regions

        bar: bar
        panels: panels
        win: root
    }

    HyprlandFocusGrab {
        id: focusGrab

        active: {
            const s = root.screenState;
            const conf = root.contentItem.Config;
            if ((s.launcher && conf.launcher.enabled) || (s.session && conf.session.enabled) || (s.sidebar && conf.sidebar.enabled))
                return true;
            if (!conf.dashboard.showOnHover && s.dashboard && conf.dashboard.enabled)
                return true;
            if (panels.popouts.currentName.startsWith("traymenu") && (panels.popouts.current as StackView)?.depth > 1)
                return true;
            return false;
        }
        windows: [root]
        onCleared: {
            root.screenState.launcher = false;
            root.screenState.session = false;
            root.screenState.sidebar = false;
            root.screenState.dashboard = false;
            panels.popouts.hasCurrent = false;
            bar.closeTray();
        }
    }

    StyledRect {
        anchors.fill: parent
        opacity: (root.screenState.session && Config.session.enabled) || panels.popouts.detachedMode !== "" ? 0.5 : 0
        color: Colours.palette.m3scrim

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.surfaceColour.a
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, Math.max(0, root.shadowOpacity))
        }

        BlobGroup {
            id: blobGroup

            color: root.surfaceColour
            smoothing: root.Config.border.smoothing
        }

        BlobInvertedRect {
            anchors.fill: parent
            anchors.margins: -50 // Make border thicker to smooth out bulge from closed drawers
            group: blobGroup
            radius: root.borderRounding
            borderLeft: bar.implicitWidth - anchors.margins - root.sdfBorderOffset
            borderRight: root.borderThickness - anchors.margins - root.sdfBorderOffset
            borderTop: root.borderThickness - anchors.margins - root.sdfBorderOffset
            borderBottom: root.borderThickness - anchors.margins - root.sdfBorderOffset
        }

        PanelBg {
            id: dashBg

            attachTop: true
            panel: panels.dashboard
            deformAmount: 0.1
        }

        PanelBg {
            id: launcherBg

            attachBottom: true
            panel: panels.launcher
            deformAmount: 0.1
        }

        PanelBg {
            id: sessionBg

            attachRight: true
            panel: panels.sessionWrapper
            deformAmount: 0.2
            x: panels.sessionWrapper.x + panels.session.x + bar.implicitWidth
            implicitWidth: panels.session.width
        }

        PanelBg {
            id: sidebarBg

            attachRight: true
            panel: panels.sidebar
            deformAmount: 0.03
            implicitHeight: panel.height * (1 / rawDeformMatrix.m22) + 2
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [utilsBg]
            bottomLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
        }

        PanelBg {
            id: osdBg

            attachRight: true
            panel: panels.osdWrapper
            deformAmount: 0.25
            x: panels.osdWrapper.x + panels.osd.x + bar.implicitWidth
            implicitWidth: panels.osd.width
        }

        PanelBg {
            id: notifsBg

            attachTop: true
            attachRight: true
            panel: panels.notifications
        }

        PanelBg {
            id: utilsBg

            attachBottom: true
            attachRight: true
            panel: panels.utilities
            deformAmount: panels.sidebar.visible ? 0.1 : 0.15
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [sidebarBg]
            topLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
        }

        PanelBg {
            id: popoutBg

            attachLeft: !panels.popouts.isDetached
            // Extra width to prevent vertical movement deformation partially detaching panel from bar
            property real extraWidth: panels.popouts.isDetached ? 0 : 0.2

            panel: panels.popoutsWrapper
            deformAmount: panels.popouts.isDetached ? 0.05 : panels.popouts.hasCurrent ? 0.15 : 0.1
            x: panels.popoutsWrapper.x + panels.popouts.x + bar.implicitWidth - panels.popouts.width * extraWidth
            implicitWidth: panels.popouts.width * (1 + extraWidth)

            Behavior on extraWidth {
                Anim {}
            }
        }
    }

    Interactions {
        id: interactions

        screen: root.screen
        popouts: panels.popouts
        screenState: root.screenState
        panels: panels
        bar: bar
        borderThickness: root.borderLayoutThickness
        fullscreen: root.hasFullscreen

        Panels {
            id: panels

            screen: root.screen
            screenState: root.screenState
            bar: bar
            borderThickness: root.borderThickness

            utilities.horizontalStretch: (sidebarBg.rawDeformMatrix.m11 - 1) / 2 + 1
            utilities.deformMatrix: utilsBg.rawDeformMatrix

            dashboard.transform: Matrix4x4 {
                matrix: dashBg.deformMatrix
            }
            launcher.transform: Matrix4x4 {
                matrix: launcherBg.deformMatrix
            }
            session.transform: Matrix4x4 {
                matrix: sessionBg.deformMatrix
            }
            sidebar.transform: Matrix4x4 {
                matrix: sidebarBg.deformMatrix
            }
            osd.transform: Matrix4x4 {
                matrix: osdBg.deformMatrix
            }
            notifications.transform: Matrix4x4 {
                matrix: notifsBg.deformMatrix
            }
            utilities.transform: Matrix4x4 {
                matrix: utilsBg.deformMatrix
            }
            popouts.transform: Matrix4x4 {
                matrix: popoutBg.deformMatrix
            }
        }

        BarWrapper {
            id: bar

            anchors.top: parent.top
            anchors.bottom: parent.bottom

            screen: root.screen
            screenState: root.screenState
            popouts: panels.popouts

            fullscreen: root.hasFullscreen
        }
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "rootWindow"
        component: root
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "interactionWrapper"
        component: interactions
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "bar"
        component: bar
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "panels"
        component: panels
    }

    component PanelBg: BlobRect {
        required property Item panel
        property real deformAmount: 0.15
        // Port: edges the panel is flush with. The wabar blob stub does not fuse shapes, so a
        // flush edge is square and overlaps the frame instead of leaving a seam and a wedge.
        property bool attachTop: false
        property bool attachRight: false
        property bool attachBottom: false
        property bool attachLeft: false

        // Port: concave junction fillets. Upstream fuses a flush panel with the frame by a circular
        // smooth-min whose blend arc has radius `smoothing`; the stub draws separate shapes, so each
        // end of an attached edge gets a fillet piece (the square minus a quarter circle) in the
        // group colour. The radius is the frame's own, in logical px, not scaled by the UI scale.
        // Fillets lie in free space beside the panel, outside the open-panel mask regions.
        readonly property real filletMax: root.Config.border.smoothing * (1 - root.fsTransitionProg)
        // Inner edges of the frame in this item's coordinates.
        readonly property real frameL: bar.implicitWidth - x
        readonly property real frameR: root.width - root.borderThickness - x
        readonly property real frameT: root.borderThickness - y
        readonly property real frameB: root.height - root.borderThickness - y
        // How far the panel reaches out of each frame edge; the radius grows with it as it slides.
        readonly property real filletRight: Math.max(0, Math.min(filletMax, frameR, height / 2))
        readonly property real filletLeft: Math.max(0, Math.min(filletMax, width - frameL, height / 2))
        readonly property real filletTop: Math.max(0, Math.min(filletMax, height - frameT, width / 2))
        readonly property real filletBottom: Math.max(0, Math.min(filletMax, frameB, width / 2))

        // Right edge: ends at the top and bottom of the panel (a top or bottom attachment is the frame).
        // The junction is the panel's own right edge, which is the neighbouring panel's left edge
        // for session and osd when the sidebar is open, and the frame otherwise.
        Fillet {
            r: parent.filletRight
            active: parent.attachRight && !parent.attachTop
            px: parent.width; py: 0; ax: 0; ay: -1; bx: -1; by: 0
        }
        Fillet {
            r: parent.filletRight
            active: parent.attachRight && !parent.attachBottom
            px: parent.width; py: parent.height; ax: 0; ay: 1; bx: -1; by: 0
        }
        Fillet {
            r: parent.filletLeft
            active: parent.attachLeft
            px: parent.frameL; py: 0; ax: 0; ay: -1; bx: 1; by: 0
        }
        Fillet {
            r: parent.filletLeft
            active: parent.attachLeft
            px: parent.frameL; py: parent.height; ax: 0; ay: 1; bx: 1; by: 0
        }
        Fillet {
            r: parent.filletTop
            active: parent.attachTop && !parent.attachLeft
            px: 0; py: parent.frameT; ax: -1; ay: 0; bx: 0; by: 1
        }
        Fillet {
            r: parent.filletTop
            active: parent.attachTop && !parent.attachRight
            px: parent.width; py: parent.frameT; ax: 1; ay: 0; bx: 0; by: 1
        }
        Fillet {
            r: parent.filletBottom
            active: parent.attachBottom && !parent.attachLeft
            px: 0; py: parent.frameB; ax: -1; ay: 0; bx: 0; by: -1
        }
        Fillet {
            r: parent.filletBottom
            active: parent.attachBottom && !parent.attachRight
            px: parent.width; py: parent.frameB; ax: 1; ay: 0; bx: 0; by: -1
        }

        group: blobGroup
        x: panel.x + bar.implicitWidth
        y: panel.y + root.borderThickness
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Tokens.rounding.extraLarge
        topLeftRadius: attachTop ? 0 : radius
        topRightRadius: attachTop || attachRight ? 0 : radius
        bottomRightRadius: attachBottom || attachRight ? 0 : radius
        bleedTop: attachTop ? root.borderThickness : 0
        bleedRight: attachRight ? root.borderThickness : 0
        bleedBottom: attachBottom ? root.borderThickness : 0
        deformScale: (deformAmount * Config.appearance.deformScale) / 10000
    }

    // A concave fillet at the junction point (px, py) of a panel edge and a frame edge. (ax, ay)
    // runs along the frame edge into free space, (bx, by) along the panel edge into free space.
    // The piece is the square of side r at the junction minus the quarter circle centred on the
    // square's far corner.
    component Fillet: Shape {
        property real r: 0
        property real px: 0
        property real py: 0
        property real ax: 0
        property real ay: 0
        property real bx: 0
        property real by: 0

        readonly property int sweep: (bx * ay - by * ax) > 0 ? 1 : 0

        property bool active: true

        visible: active && r > 0.5
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Qt.rgba(blobGroup.color.r, blobGroup.color.g, blobGroup.color.b, 1)
            // A thin edge in the same colour overdraws the anti-aliased seam against the frame and
            // the panel, so no hairline of background shows through at the join.
            strokeColor: fillColor
            strokeWidth: 1.5

            PathSvg {
                path: `M${px},${py} L${px + ax * r},${py + ay * r}`
                    + ` A${r},${r} 0 0 ${sweep} ${px + bx * r},${py + by * r} Z`
            }
        }
    }
}
