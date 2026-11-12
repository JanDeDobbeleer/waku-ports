pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Celeste.Blobs
import Celeste.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.bar

StyledWindow {
    id: root

    readonly property alias bar: barItem
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

    // Port: the panels that close when the user presses Escape, clicks outside them, switches to
    // another window, or toggles them again. Upstream gets the click and focus part from
    // HyprlandFocusGrab; waku's shim of it ends for good after its first clear (it writes `active`,
    // which removes this binding), so the window does it itself.
    readonly property bool lightDismissOpen: {
        const s = screenState;
        const conf = contentItem.Config;
        if ((s.launcher && conf.launcher.enabled) || (s.session && conf.session.enabled) || (s.sidebar && conf.sidebar.enabled))
            return true;
        // Port: with hover on, a dashboard opened by hovering closes when the pointer leaves; one
        // opened by a click or shortcut (Interactions.dashboardShortcutActive) stays until a click
        // elsewhere dismisses it.
        if ((!conf.dashboard.showOnHover || interactions.dashboardShortcutActive) && s.dashboard && conf.dashboard.enabled)
            return true;
        if (panelsItem.popouts.currentName.startsWith("traymenu") && (panelsItem.popouts.current?.depth ?? 0) > 1)
            return true;
        return false;
    }
    // The panels that take the keyboard (WlrKeyboardFocus.OnDemand below).
    readonly property bool keyboardPanelOpen: screenState.launcher || screenState.session
    property double lightDismissSince: 0
    property bool hadFocus: false

    property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly property real sdfBorderOffset: 2 * fsTransitionProg // SDFs joins are not exact, so offset by 2px to ensure nothing shows
    readonly property real borderThickness: Config.border.thickness * (1 - fsTransitionProg)
    readonly property real borderRounding: Config.border.rounding * (1 - fsTransitionProg)
    readonly property real shadowOpacity: 0.7 * (1 - fsTransitionProg)

    // The frame's shadow needs a full-window layer plus the effect's blur textures, which cost about
    // as much GPU memory as everything else the idle shell holds. The layer exists only while some
    // panel is on screen; the shadow fades out over `shadowFade` before the layer goes, so closing
    // the last panel does not make the shadow pop off.
    readonly property bool anyPanelVisible: panelsItem.dashboard.visible || panelsItem.launcher.visible || panelsItem.session.visible || panelsItem.sidebar.visible || panelsItem.osd.visible || panelsItem.utilities.visible || panelsItem.notifications.visible || panelsItem.popoutsWrapper.visible
    property real shadowFade: anyPanelVisible ? 1 : 0
    readonly property real borderLayoutThickness: hasFullscreen ? 0 : Config.border.thickness

    property color surfaceColour: Colours.tPalette.m3surface

    readonly property int dragMaskPadding: {
        if (lightDismissOpen || panelsItem.popouts.isDetached)
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
        panelsItem.popouts.close();
    }

    name: "drawers"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: (fsTransitionProg > 0 && Config.general.showOverFullscreen) || (hasSpecialWorkspace && hasFullscreenOnNormalWs) ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: screenState.launcher || screenState.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Port: a panel that closes on a click elsewhere takes input over the whole window, so the
    // click lands here (Interactions) instead of on the window below.
    mask: hasFullscreen ? emptyRegion : lightDismissOpen ? dismissRegion : regions

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

    Behavior on shadowFade {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Region {
        id: emptyRegion

        x: panelsItem.notifications.x + barItem.implicitWidth
        y: panelsItem.notifications.y + root.borderThickness
        width: panelsItem.notifications.width
        height: panelsItem.notifications.height

        Region {
            // Port: x reads w_, not width (waku's Region has one change signal for its geometry).
            readonly property real w_: panelsItem.osdWrapper.width * (1 - panelsItem.osd.offsetScale) + root.borderThickness

            x: root.width - w_
            y: panelsItem.osdWrapper.y + root.borderThickness
            width: w_
            height: panelsItem.osd.height
        }
    }

    Regions {
        id: regions

        bar: barItem
        panels: panelsItem
        win: root
    }

    Region {
        id: dismissRegion

        x: 0
        y: 0
        width: root.width
        height: root.height
    }

    function dismiss(): void {
        screenState.launcher = false;
        screenState.session = false;
        screenState.sidebar = false;
        screenState.dashboard = false;
        panelsItem.popouts.hasCurrent = false;
        barItem.closeTray();
    }

    // The engine takes the foreground when keyboardFocus turns on, so a launcher opened by a
    // shortcut receives keys. `hadFocus` starts true when the window is already active and
    // otherwise becomes true when the activation arrives (onActiveChanged below).
    onKeyboardPanelOpenChanged: {
        hadFocus = keyboardPanelOpen && root.backingWindow.active;
        if (keyboardPanelOpen)
            lightDismissSince = Date.now();
    }

    // Focus loss: the user switched to another window while a panel was open. Activation is
    // asynchronous, so a loss in the first 400 ms after opening is not the user's.
    Connections {
        function onActiveChanged(): void {
            if (root.backingWindow.active) {
                root.hadFocus = true;
            } else if (root.hadFocus && root.lightDismissOpen) {
                root.hadFocus = false;
                if (Date.now() - root.lightDismissSince > 400)
                    root.dismiss();
            }
        }

        target: root.backingWindow
    }

    // Escape closes the open panel even when no field has the focus.
    Shortcut {
        sequence: "Escape"
        enabled: root.lightDismissOpen
        onActivated: root.dismiss()
    }

    StyledRect {
        anchors.fill: parent
        opacity: (root.screenState.session && Config.session.enabled) || panelsItem.popouts.detachedMode !== "" ? 0.5 : 0
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
        layer.enabled: root.anyPanelVisible || root.shadowFade > 0
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, Math.max(0, root.shadowOpacity) * root.shadowFade)
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
            borderLeft: barItem.implicitWidth - anchors.margins - root.sdfBorderOffset
            borderRight: root.borderThickness - anchors.margins - root.sdfBorderOffset
            borderTop: root.borderThickness - anchors.margins - root.sdfBorderOffset
            borderBottom: root.borderThickness - anchors.margins - root.sdfBorderOffset
        }

        PanelBg {
            id: dashBg

            attachTop: true
            panel: panelsItem.dashboard
            gapTop: panelsItem.dashboard.anchors.topMargin
            deformAmount: 0.1
        }

        PanelBg {
            id: launcherBg

            attachBottom: true
            panel: panelsItem.launcher
            gapBottom: panelsItem.launcher.anchors.bottomMargin
            deformAmount: 0.1
        }

        PanelBg {
            id: sessionBg

            attachRight: true
            panel: panelsItem.sessionWrapper
            gapRight: panelsItem.session.anchors.rightMargin
            deformAmount: 0.2
            x: panelsItem.sessionWrapper.x + panelsItem.session.x + barItem.implicitWidth
            implicitWidth: panelsItem.session.width
        }

        PanelBg {
            id: sidebarBg

            attachRight: true
            panel: panelsItem.sidebar
            gapRight: panelsItem.sidebar.anchors.rightMargin
            deformAmount: 0.03
            implicitHeight: panel.height * (1 / rawDeformMatrix.m22) + 2
            exclude: panelsItem.sidebar.offsetScale > 0.08 ? [] : [utilsBg]
            bottomLeftRadius: Math.max(0, Math.min(1, panelsItem.sidebar.offsetScale / 0.3)) * radius
        }

        PanelBg {
            id: osdBg

            attachRight: true
            panel: panelsItem.osdWrapper
            gapRight: panelsItem.osd.anchors.rightMargin
            deformAmount: 0.25
            x: panelsItem.osdWrapper.x + panelsItem.osd.x + barItem.implicitWidth
            implicitWidth: panelsItem.osd.width
        }

        PanelBg {
            id: notifsBg

            attachTop: true
            attachRight: true
            panel: panelsItem.notifications
        }

        PanelBg {
            id: utilsBg

            attachBottom: true
            attachRight: true
            panel: panelsItem.utilities
            gapBottom: panelsItem.utilities.anchors.bottomMargin
            deformAmount: panelsItem.sidebar.visible ? 0.1 : 0.15
            exclude: panelsItem.sidebar.offsetScale > 0.08 ? [] : [sidebarBg]
            topLeftRadius: Math.max(0, Math.min(1, panelsItem.sidebar.offsetScale / 0.3)) * radius
        }

        PanelBg {
            id: popoutBg

            attachLeft: !panelsItem.popouts.isDetached
            // Extra width to prevent vertical movement deformation partially detaching panel from bar
            property real extraWidth: panelsItem.popouts.isDetached ? 0 : 0.2

            panel: panelsItem.popoutsWrapper
            deformAmount: panelsItem.popouts.isDetached ? 0.05 : panelsItem.popouts.hasCurrent ? 0.15 : 0.1
            x: panelsItem.popoutsWrapper.x + panelsItem.popouts.x + barItem.implicitWidth - panelsItem.popouts.width * extraWidth
            implicitWidth: panelsItem.popouts.width * (1 + extraWidth)

            Behavior on extraWidth {
                Anim {}
            }
        }
    }

    Interactions {
        id: interactions

        screen: root.screen
        popouts: panelsItem.popouts
        screenState: root.screenState
        panels: panelsItem
        bar: barItem
        borderThickness: root.borderLayoutThickness
        fullscreen: root.hasFullscreen
        lightDismiss: root.lightDismissOpen
        onDismissRequested: root.dismiss()

        Panels {
            id: panelsItem

            screen: root.screen
            screenState: root.screenState
            bar: barItem
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
            id: barItem

            anchors.top: parent.top
            anchors.bottom: parent.bottom

            screen: root.screen
            screenState: root.screenState
            popouts: panelsItem.popouts

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
        component: barItem
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "panels"
        component: panelsItem
    }

    component PanelBg: BlobRect {
        required property Item panel
        property real deformAmount: 0.15
        // Port: edges the panel is flush with. The waku blob stub does not fuse shapes, so a
        // flush edge is square and overlaps the frame instead of leaving a seam and a wedge.
        property bool attachTop: false
        property bool attachRight: false
        property bool attachBottom: false
        property bool attachLeft: false
        // Port: how far the panel has moved off its attached edge. The expressive slide curves
        // overshoot, so the wrapper's margin goes positive for a few frames and the panel leaves
        // the frame. The upstream SDF union keeps the shape fused to the frame; the stub extends
        // the rectangle to the frame by the same amount so no wallpaper shows in the gap.
        property real gapTop: 0
        property real gapRight: 0
        property real gapBottom: 0
        readonly property real coverTop: attachTop ? Math.max(0, gapTop) : 0
        readonly property real coverRight: attachRight ? Math.max(0, gapRight) : 0
        readonly property real coverBottom: attachBottom ? Math.max(0, gapBottom) : 0

        // Port: concave junction fillets. Upstream fuses a flush panel with the frame by a circular
        // smooth-min whose blend arc has radius `smoothing`; the stub draws separate shapes, so each
        // end of an attached edge gets a fillet piece (the square minus a quarter circle) in the
        // group colour. The radius is the frame's own, in logical px, not scaled by the UI scale.
        // Fillets lie in free space beside the panel, outside the open-panel mask regions.
        readonly property real filletMax: root.Config.border.smoothing * (1 - root.fsTransitionProg)
        // Inner edges of the frame in this item's coordinates.
        readonly property real frameL: barItem.implicitWidth - x
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
            px: parent.width + parent.coverRight; py: 0; ax: 0; ay: -1; bx: -1; by: 0
        }
        Fillet {
            r: parent.filletRight
            active: parent.attachRight && !parent.attachBottom
            px: parent.width + parent.coverRight; py: parent.height; ax: 0; ay: 1; bx: -1; by: 0
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
        // Port: a closed panel sits just off its edge and, with the blob smoothing, still bulges the
        // frame into a small rounded corner there (the utilities panel at the bottom right).
        visible: panel.visible
        x: panel.x + barItem.implicitWidth
        y: panel.y + root.borderThickness
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Tokens.rounding.extraLarge
        topLeftRadius: attachTop ? 0 : radius
        topRightRadius: attachTop || attachRight ? 0 : radius
        bottomRightRadius: attachBottom || attachRight ? 0 : radius
        bottomLeftRadius: attachBottom || attachLeft ? 0 : radius
        bleedTop: attachTop ? root.borderThickness + coverTop : 0
        bleedRight: attachRight ? root.borderThickness + coverRight : 0
        bleedBottom: attachBottom ? root.borderThickness + coverBottom : 0
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

        // The panel's own squash and stretch, so the fillet stays on the deformed edge. Fillets are
        // children of the panel's BlobRect, in the same coordinates as its deform matrix.
        transform: Matrix4x4 {
            matrix: parent.deformMatrix
        }

        ShapePath {
            fillColor: Qt.rgba(blobGroup.color.r, blobGroup.color.g, blobGroup.color.b, 1)
            // A thin edge in the same colour overdraws the anti-aliased seam against the frame and
            // the panel, so no hairline of background shows through at the join.
            strokeColor: fillColor
            strokeWidth: 1.5

            // The piece runs `n` under the frame (against b) and under the panel (against a), so
            // the arc's thin tip, where it turns tangent to the frame, always sits on solid colour.
            PathSvg {
                readonly property real n: 3
                path: `M${px - (ax + bx) * n},${py - (ay + by) * n}`
                    + ` L${px + ax * r - bx * n},${py + ay * r - by * n}`
                    + ` L${px + ax * r},${py + ay * r}`
                    + ` A${r},${r} 0 0 ${sweep} ${px + bx * r},${py + by * r}`
                    + ` L${px + bx * r - ax * n},${py + by * r - ay * n} Z`
            }
        }
    }
}
