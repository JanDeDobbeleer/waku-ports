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

    readonly final property ScreenState screenState: ShellState.forScreen(screen)

    readonly final property HyprMonitor monitor: Hypr.monitorFor(screen)
    readonly final property bool hasSpecialWorkspace: (monitor?.specialName.length ?? 0) > 0
    readonly final property bool hasFullscreenOnNormalWs: Hypr.hasFullscreen(monitor?.activeWorkspace ?? null)
    readonly final property bool hasFullscreen: hasSpecialWorkspace ? Hypr.specialFullscreen(monitor) : hasFullscreenOnNormalWs

    // Port: the panels that close when the user presses Escape, clicks outside them, switches to
    // another window, or toggles them again. Upstream gets the click and focus part from
    // HyprlandFocusGrab; waku's shim of it ends for good after its first clear (it writes `active`,
    // which removes this binding), so the window does it itself.
    readonly final property bool lightDismissOpen: {
        const s = screenState;
        const conf = Config;
        if ((s.launcher && conf.launcher.enabled) || (s.session && conf.session.enabled) || (s.sidebar && conf.sidebar.enabled))
            return true;
        // Port: with hover on, a dashboard opened by hovering closes when the pointer leaves; one
        // opened by a click or shortcut (Interactions.dashboardShortcutActive) stays until a click
        // elsewhere dismisses it.
        if ((!conf.dashboard.showOnHover || interactions.dashboardShortcutActive) && s.dashboard && conf.dashboard.enabled)
            return true;
        if (panelsItem.popouts.currentName.startsWith("traymenu") && panelsItem.popouts.currentDepth > 1)
            return true;
        return false;
    }
    // The panels that take the keyboard (WlrKeyboardFocus.OnDemand below).
    readonly final property bool keyboardPanelOpen: screenState.launcher || screenState.session
    final property double lightDismissSince: 0
    final property bool hadFocus: false

    final property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly final property real sdfBorderOffset: 2 * fsTransitionProg // SDFs joins are not exact, so offset by 2px to ensure nothing shows
    readonly final property real borderThickness: Config.border.thickness * (1 - fsTransitionProg)
    readonly final property real borderRounding: Config.border.rounding * (1 - fsTransitionProg)
    readonly final property real shadowOpacity: 0.7 * (1 - fsTransitionProg)

    // The frame's shadow needs a full-window layer plus the effect's blur textures, which cost about
    // as much GPU memory as everything else the idle shell holds. The layer exists only while some
    // panel is on screen; the shadow fades out over `shadowFade` before the layer goes, so closing
    // the last panel does not make the shadow pop off.
    readonly final property bool anyPanelVisible: panelsItem.dashboard.visible || panelsItem.launcher.visible || panelsItem.session.visible || panelsItem.sidebar.visible || panelsItem.osd.visible || panelsItem.utilities.visible || panelsItem.notifications.visible || panelsItem.popoutsWrapper.visible
    final property real shadowFade: anyPanelVisible ? 1 : 0
    readonly final property real borderLayoutThickness: hasFullscreen ? 0 : Config.border.thickness

    final property color surfaceColour: Colours.tPalette.m3surface

    readonly final property int dragMaskPadding: {
        if (lightDismissOpen || panelsItem.popouts.isDetached)
            return 0;

        if (monitor?.specialName || Hypr.windowCount(monitor?.activeWorkspace ?? null) > 0)
            return 0;

        const thresholds = [];
        if (Config.dashboard.enabled)
            thresholds.push(Config.dashboard.dragThreshold);
        if (Config.launcher.enabled)
            thresholds.push(Config.launcher.dragThreshold);
        if (Config.session.enabled)
            thresholds.push(Config.session.dragThreshold);
        if (Config.sidebar.enabled)
            thresholds.push(Config.sidebar.dragThreshold);
        return thresholds.length > 0 ? Math.max.apply(null, thresholds) : -Infinity;
    }

    onHasFullscreenChanged: {
        screenState.launcher = false;
        screenState.session = false;
        screenState.dashboard = false;
        panelsItem.closePopouts();
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
            readonly final property real w_: panelsItem.osdWrapper.width * (1 - panelsItem.osd.offsetScale) + root.borderThickness

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
        barWidth: barItem.implicitWidth
        winWidth: root.width
        winHeight: root.height
        dragMaskPadding: root.dragMaskPadding
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
            smoothing: Config.border.smoothing
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
            final property real extraWidth: panelsItem.popouts.isDetached ? 0 : 0.2

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
        barWidth: barItem.implicitWidth
        borderThickness: root.borderLayoutThickness
        fullscreen: root.hasFullscreen
        lightDismiss: root.lightDismissOpen
        onDismissRequested: root.dismiss()
        onBarWheel: (y, angleDelta) => barItem.handleWheel(y, angleDelta)
        onBarClicked: (x, y) => {
            if (barItem.emptyAt(x, y))
                barItem.clickClock();
        }
        onBarTrayCloseRequested: barItem.closeTray()
        onBarPopoutCheckRequested: y => barItem.checkPopout(y)

        Panels {
            id: panelsItem

            screen: root.screen
            screenState: root.screenState
            bar: barItem
            barWidth: barItem.implicitWidth
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
        id: panelBg

        required final property Item panel
        final property real deformAmount: 0.15
        // Port: edges the panel is flush with. The waku blob stub does not fuse shapes, so a
        // flush edge is square and overlaps the frame instead of leaving a seam and a wedge.
        final property bool attachTop: false
        final property bool attachRight: false
        final property bool attachBottom: false
        final property bool attachLeft: false
        // Port: how far the panel has moved off its attached edge. The expressive slide curves
        // overshoot, so the wrapper's margin goes positive for a few frames and the panel leaves
        // the frame. The upstream SDF union keeps the shape fused to the frame; the stub extends
        // the rectangle to the frame by the same amount so no wallpaper shows in the gap.
        final property real gapTop: 0
        final property real gapRight: 0
        final property real gapBottom: 0
        readonly final property real coverTop: attachTop ? Math.max(0, gapTop) : 0
        readonly final property real coverRight: attachRight ? Math.max(0, gapRight) : 0
        readonly final property real coverBottom: attachBottom ? Math.max(0, gapBottom) : 0

        // Port: concave junction fillets. Upstream fuses a flush panel with the frame by a circular
        // smooth-min whose blend arc has radius `smoothing`; the stub draws separate shapes, so each
        // end of an attached edge gets a fillet piece (the square minus a quarter circle) in the
        // group colour. The radius is the frame's own, in logical px, not scaled by the UI scale.
        // Fillets lie in free space beside the panel, outside the open-panel mask regions.
        readonly final property real filletMax: Config.border.smoothing * (1 - root.fsTransitionProg)
        // Inner edges of the frame in this item's coordinates.
        readonly final property real frameL: barItem.implicitWidth - x
        readonly final property real frameR: root.width - root.borderThickness - x
        readonly final property real frameT: root.borderThickness - y
        readonly final property real frameB: root.height - root.borderThickness - y
        // How far the panel reaches out of each frame edge; the radius grows with it as it slides.
        readonly final property real filletRight: Math.max(0, Math.min(filletMax, frameR, height / 2))
        readonly final property real filletLeft: Math.max(0, Math.min(filletMax, width - frameL, height / 2))
        readonly final property real filletTop: Math.max(0, Math.min(filletMax, height - frameT, width / 2))
        readonly final property real filletBottom: Math.max(0, Math.min(filletMax, frameB, width / 2))

        // Right edge: ends at the top and bottom of the panel (a top or bottom attachment is the frame).
        // The junction is the panel's own right edge, which is the neighbouring panel's left edge
        // for session and osd when the sidebar is open, and the frame otherwise.
        Fillet {
            bg: panelBg
            r: panelBg.filletRight
            active: panelBg.attachRight && !panelBg.attachTop
            px: panelBg.width + panelBg.coverRight; py: 0; ax: 0; ay: -1; bx: -1; by: 0
        }
        Fillet {
            bg: panelBg
            r: panelBg.filletRight
            active: panelBg.attachRight && !panelBg.attachBottom
            px: panelBg.width + panelBg.coverRight; py: panelBg.height; ax: 0; ay: 1; bx: -1; by: 0
        }
        Fillet {
            bg: panelBg
            r: panelBg.filletLeft
            active: panelBg.attachLeft
            px: panelBg.frameL; py: 0; ax: 0; ay: -1; bx: 1; by: 0
        }
        Fillet {
            bg: panelBg
            r: panelBg.filletLeft
            active: panelBg.attachLeft
            px: panelBg.frameL; py: panelBg.height; ax: 0; ay: 1; bx: 1; by: 0
        }
        Fillet {
            bg: panelBg
            r: panelBg.filletTop
            active: panelBg.attachTop && !panelBg.attachLeft
            px: 0; py: panelBg.frameT; ax: -1; ay: 0; bx: 0; by: 1
        }
        Fillet {
            bg: panelBg
            r: panelBg.filletTop
            active: panelBg.attachTop && !panelBg.attachRight
            px: panelBg.width; py: panelBg.frameT; ax: 1; ay: 0; bx: 0; by: 1
        }
        Fillet {
            bg: panelBg
            r: panelBg.filletBottom
            active: panelBg.attachBottom && !panelBg.attachLeft
            px: 0; py: panelBg.frameB; ax: -1; ay: 0; bx: 0; by: -1
        }
        Fillet {
            bg: panelBg
            r: panelBg.filletBottom
            active: panelBg.attachBottom && !panelBg.attachRight
            px: panelBg.width; py: panelBg.frameB; ax: 1; ay: 0; bx: 0; by: -1
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
        id: fillet

        required final property BlobRect bg
        final property real r: 0
        final property real px: 0
        final property real py: 0
        final property real ax: 0
        final property real ay: 0
        final property real bx: 0
        final property real by: 0

        readonly final property int sweep: (bx * ay - by * ax) > 0 ? 1 : 0

        final property bool active: true

        visible: active && r > 0.5
        preferredRendererType: Shape.CurveRenderer

        // The panel's own squash and stretch, so the fillet stays on the deformed edge. Fillets are
        // children of the panel's BlobRect, in the same coordinates as its deform matrix.
        transform: Matrix4x4 {
            matrix: fillet.bg.deformMatrix
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
                readonly final property real n: 3
                path: `M${fillet.px - (fillet.ax + fillet.bx) * n},${fillet.py - (fillet.ay + fillet.by) * n}`
                    + ` L${fillet.px + fillet.ax * fillet.r - fillet.bx * n},${fillet.py + fillet.ay * fillet.r - fillet.by * n}`
                    + ` L${fillet.px + fillet.ax * fillet.r},${fillet.py + fillet.ay * fillet.r}`
                    + ` A${fillet.r},${fillet.r} 0 0 ${fillet.sweep} ${fillet.px + fillet.bx * fillet.r},${fillet.py + fillet.by * fillet.r}`
                    + ` L${fillet.px + fillet.bx * fillet.r - fillet.ax * n},${fillet.py + fillet.by * fillet.r - fillet.ay * n} Z`
            }
        }
    }
}
