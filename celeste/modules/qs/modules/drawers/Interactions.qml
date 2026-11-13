import QtQuick
import Quickshell
import Celeste.Config
import qs.components
import qs.components.controls
import qs.modules.bar as Bar
import qs.modules.bar.popouts as BarPopouts

CustomMouseArea {
    id: root

    required final property ShellScreen screen
    required final property BarPopouts.Wrapper popouts
    required final property ScreenState screenState
    required final property Panels panels
    required final property Bar.BarWrapper bar
    required final property real barWidth
    required final property real borderThickness
    required final property bool fullscreen
    // True while a panel that closes when the user clicks elsewhere is open.
    required final property bool lightDismiss

    signal dismissRequested
    signal barWheel(y: real, angleDelta: point)
    signal barClicked(x: real, y: real)
    signal barTrayCloseRequested
    signal barPopoutCheckRequested(y: real)

    final property point dragStart
    final property bool dashboardShortcutActive

    Timer {
        id: dashboardHoverTimer

        interval: Config.dashboard.hoverDelay
        onTriggered: {
            if (!root.dashboardShortcutActive && Config.dashboard.showOnHover && root.inTopPanel(root.panels.dashboard, root.panels.dashboard.offsetScale, root.mouseX, root.mouseY))
                root.screenState.dashboard = true;
        }
    }
    final property bool osdShortcutActive
    final property bool utilitiesShortcutActive
    final property bool sidebarShortcutActive

    function withinPanelHeight(panel: Item, x: real, y: real): bool {
        const panelY = root.borderThickness + panel.y;
        return y >= panelY - Config.border.rounding && y <= panelY + panel.height + Config.border.rounding;
    }

    function withinPanelWidth(panel: Item, x: real, y: real): bool {
        const panelX = barWidth + panel.x;
        return x >= panelX - Config.border.rounding && x <= panelX + panel.width + Config.border.rounding;
    }

    function inLeftPanel(panel: Item, x: real, y: real): bool {
        return x < barWidth + panel.x + panel.width && withinPanelHeight(panel, x, y);
    }

    function inRightPanel(panel: Item, x: real, y: real): bool {
        return x > Math.min(width - Config.border.minThickness, barWidth + panel.x) && withinPanelHeight(panel, x, y);
    }

    function inTopPanel(panel: Item, offsetScale: real, x: real, y: real): bool {
        const panelHeight = panel.height * (1 - offsetScale);
        return y < Math.max(Config.border.minThickness, Config.border.thickness + panelHeight) && withinPanelWidth(panel, x, y);
    }

    function inBottomPanel(panel: Item, offsetScale: real, x: real, y: real, isCorner: bool): bool {
        const panelHeight = panel.height * (1 - offsetScale);
        return y > height - Math.max(Config.border.minThickness, Config.border.thickness + panelHeight) - (isCorner ? Config.border.rounding : 0) && withinPanelWidth(panel, x, y);
    }

    // Port: whether the point is on a visible panel. A click anywhere else, off the bar, closes
    // the light-dismiss panels (the window has no compositor grab here; see ContentWindow).
    function onVisiblePanel(x: real, y: real): bool {
        return overPanel(panels.dashboard, x, y) || overPanel(panels.launcher, x, y) || overPanel(panels.sessionWrapper, x, y) || overPanel(panels.sidebar, x, y) || overPanel(panels.utilities, x, y) || overPanel(panels.popoutsWrapper, x, y) || overPanel(panels.notifications, x, y) || overPanel(panels.osdWrapper, x, y);
    }

    function overPanel(p: Item, x: real, y: real): bool {
        if (!p.visible || p.width <= 0 || p.height <= 0)
            return false;
        const left = barWidth + p.x;
        const top = borderThickness + p.y;
        return x >= left && x <= left + p.width && y >= top && y <= top + p.height;
    }

    // A press at (x, y): closes the light-dismiss panels when it is off the bar and off the panels.
    // Returns whether it did (the press is then used up, not passed to anything).
    function dismissOnPress(x: real, y: real): bool {
        if (!lightDismiss || x < barWidth || onVisiblePanel(x, y))
            return false;
        dismissRequested();
        return true;
    }

    function onWheel(event: WheelEvent): void {
        if (fullscreen && !bar.isHovered)
            return;
        if (event.x < barWidth) {
            barWheel(event.y, event.angleDelta);
        }
    }

    function hoverFullscreenBar(x: real, y: real): bool {
        const onBar = bar.isHovered && (x < bar.contentWidth || (popouts.hasCurrent && inLeftPanel(panels.popoutsWrapper, x, y)));
        bar.isHovered = x < 2 || onBar;
        return bar.isHovered;
    }

    anchors.fill: parent
    acceptedButtons: fullscreen && !bar.isHovered && !lightDismiss ? Qt.NoButton : Qt.AllButtons
    hoverEnabled: true

    onPressed: event => {
        dragStart = Qt.point(event.x, event.y);
        if (dismissOnPress(event.x, event.y))
            event.accepted = true;
    }
    // Port: a click on empty bar space opens the dashboard, like a click on the clock does.
    onClicked: event => {
        if (event.button === Qt.LeftButton && event.x < barWidth)
            barClicked(event.x, event.y);
    }
    onContainsMouseChanged: {
        if (!containsMouse) {
            // Only hide if not activated by shortcut
            if (!osdShortcutActive) {
                screenState.osd = false;
                root.panels.osd.hovered = false;
            }

            if (!dashboardShortcutActive)
                screenState.dashboard = false;

            if (!utilitiesShortcutActive)
                screenState.utilities = false;

            if (!popouts.currentName.startsWith("traymenu") || popouts.currentDepth <= 1) {
                popouts.hasCurrent = false;
                barTrayCloseRequested();
            }

            if (fullscreen || Config.bar.showOnHover)
                bar.isHovered = false;

            if (Config.sidebar.showOnHover && !sidebarShortcutActive)
                screenState.sidebar = false;
        }
    }

    onPositionChanged: event => {
        if (popouts.isDetached)
            return;

        const x = event.x;
        const y = event.y;
        const dragX = x - dragStart.x;
        const dragY = y - dragStart.y;

        if (fullscreen) {
            if (!hoverFullscreenBar(x, y)) {
                root.panels.osd.hovered = inRightPanel(panels.osdWrapper, x, y);
                return;
            }
        }

        // Show bar in non-exclusive mode on hover
        if (!screenState.bar && Config.bar.showOnHover && x < bar.clampedWidth)
            bar.isHovered = true;

        // Show/hide bar on drag
        if (pressed && dragStart.x < bar.clampedWidth) {
            if (dragX > Config.bar.dragThreshold)
                screenState.bar = true;
            else if (dragX < -Config.bar.dragThreshold)
                screenState.bar = false;
        }

        if (panels.sidebar.offsetScale === 1) {
            // Show osd on hover
            // Port: not while the power menu is open, they share the right edge.
            const showOsd = !screenState.session && inRightPanel(panels.osdWrapper, x, y);

            // Always update visibility based on hover if not in shortcut mode
            if (!osdShortcutActive) {
                screenState.osd = showOsd;
                root.panels.osd.hovered = showOsd;
            } else if (showOsd) {
                // If hovering over OSD area while in shortcut mode, transition to hover control
                osdShortcutActive = false;
                root.panels.osd.hovered = true;
            }

            const showSidebar = pressed && dragStart.x > Math.min(width - Config.border.minThickness, barWidth + panels.sidebar.x);

            // Show sidebar on hover (top-right corner, bounded by notification panel height)
            if (Config.sidebar.showOnHover && Config.sidebar.enabled) {
                const sidebarTriggerY = Math.max(Config.sidebar.minHoverThreshold, panels.notifications.y + panels.notifications.height + borderThickness);
                const showSidebarHover = x > Math.min(width - Config.border.minThickness, barWidth + panels.sidebar.x) && y <= sidebarTriggerY;
                if (showSidebarHover && !screenState.sidebar)
                    screenState.sidebar = true;
            }

            // Show/hide session on drag
            if (pressed && inRightPanel(panels.sessionWrapper, dragStart.x, dragStart.y) && withinPanelHeight(panels.sessionWrapper, x, y)) {
                if (dragX < -Config.session.dragThreshold)
                    screenState.session = true;
                else if (dragX > Config.session.dragThreshold)
                    screenState.session = false;

                // Show sidebar on drag if in session area and session is nearly fully visible
                if (showSidebar && panels.session.offsetScale <= 0 && dragX < -Config.sidebar.dragThreshold)
                    screenState.sidebar = true;
            } else if (showSidebar && dragX < -Config.sidebar.dragThreshold) {
                // Show sidebar on drag if not in session area
                screenState.sidebar = true;
            }
        } else {
            const outOfSidebar = x < width - panels.sidebar.width * (1 - panels.sidebar.offsetScale);
            // Show osd on hover
            // Port: not while the power menu is open, they share the right edge.
            const showOsd = !screenState.session && outOfSidebar && inRightPanel(panels.osdWrapper, x, y);

            // Always update visibility based on hover if not in shortcut mode
            if (!osdShortcutActive) {
                screenState.osd = showOsd;
                root.panels.osd.hovered = showOsd;
            } else if (showOsd) {
                // If hovering over OSD area while in shortcut mode, transition to hover control
                osdShortcutActive = false;
                root.panels.osd.hovered = true;
            }

            // Show/hide session on drag
            if (pressed && outOfSidebar && inRightPanel(panels.sessionWrapper, dragStart.x, dragStart.y) && withinPanelHeight(panels.sessionWrapper, x, y)) {
                if (dragX < -Config.session.dragThreshold)
                    screenState.session = true;
                else if (dragX > Config.session.dragThreshold)
                    screenState.session = false;
            }

            // Show/hide sidebar on hover
            if (Config.sidebar.showOnHover && Config.sidebar.enabled && !pressed) {
                const sidebarTriggerY = Math.max(Config.sidebar.minHoverThreshold, panels.notifications.y + panels.notifications.height + borderThickness);
                const showSidebarHover = x > Math.min(width - Config.border.minThickness, barWidth + panels.sidebar.x) && y <= sidebarTriggerY;
                if (showSidebarHover && !screenState.sidebar) {
                    screenState.sidebar = true;
                } else if (!sidebarShortcutActive) {
                    const inSidebarArea = inRightPanel(panels.sidebar, x, y) || inRightPanel(panels.sessionWrapper, x, y) || inRightPanel(panels.utilities, x, y);
                    if (!inSidebarArea)
                        screenState.sidebar = false;
                } else if (showSidebarHover) {
                    // If hovering over sidebar area while in shortcut mode, transition to hover control
                    sidebarShortcutActive = false;
                }
            }

            // Hide sidebar on drag
            if (pressed && inRightPanel(panels.sidebar, dragStart.x, 0) && dragX > Config.sidebar.dragThreshold)
                screenState.sidebar = false;
        }

        // Show launcher on hover, or show/hide on drag if hover is disabled
        if (Config.launcher.showOnHover) {
            if (!screenState.launcher && inBottomPanel(panels.launcher, panels.launcher.offsetScale, x, y, false))
                screenState.launcher = true;
        } else if (pressed && inBottomPanel(panels.launcher, panels.launcher.offsetScale, dragStart.x, dragStart.y, false) && withinPanelWidth(panels.launcher, x, y)) {
            if (dragY < -Config.launcher.dragThreshold)
                screenState.launcher = true;
            else if (dragY > Config.launcher.dragThreshold)
                screenState.launcher = false;
        }

        // Show dashboard on hover
        const showDashboard = Config.dashboard.showOnHover && inTopPanel(panels.dashboard, panels.dashboard.offsetScale, x, y);

        // Always update visibility based on hover if not in shortcut mode
        // Port: opening needs a dwell, so passing over the top edge (a window's own toolbar, for
        // instance) does not pop it; closing is immediate.
        if (!dashboardShortcutActive) {
            if (!showDashboard) {
                dashboardHoverTimer.stop();
                screenState.dashboard = false;
            } else if (!screenState.dashboard && !dashboardHoverTimer.running) {
                dashboardHoverTimer.restart();
            }
        } else if (showDashboard) {
            // If hovering over dashboard area while in shortcut mode, transition to hover control
            dashboardShortcutActive = false;
        }

        // Show/hide dashboard on drag (for touchscreen devices)
        if (pressed && inTopPanel(panels.dashboard, panels.dashboard.offsetScale, dragStart.x, dragStart.y) && withinPanelWidth(panels.dashboard, x, y)) {
            if (dragY > Config.dashboard.dragThreshold)
                screenState.dashboard = true;
            else if (dragY < -Config.dashboard.dragThreshold)
                screenState.dashboard = false;
        }

        // Show utilities on hover
        const showUtilities = inBottomPanel(panels.utilities, panels.utilities.offsetScale, x, y, true);

        // Always update visibility based on hover if not in shortcut mode
        if (!utilitiesShortcutActive) {
            screenState.utilities = showUtilities;
        } else if (showUtilities) {
            // If hovering over utilities area while in shortcut mode, transition to hover control
            utilitiesShortcutActive = false;
        }

        // Show popouts on hover
        if (x < barWidth) {
            barPopoutCheckRequested(y);
        } else if ((!popouts.currentName.startsWith("traymenu") || popouts.currentDepth <= 1) && !inLeftPanel(panels.popoutsWrapper, x, y)) {
            popouts.hasCurrent = false;
            barTrayCloseRequested();
        }
    }

    // Monitor individual visibility changes
    Connections {
        function onLauncherChanged() {
            // If launcher is hidden, clear shortcut flags for dashboard and OSD
            if (!root.screenState.launcher) {
                root.dashboardShortcutActive = false;
                root.osdShortcutActive = false;
                root.utilitiesShortcutActive = false;
                root.sidebarShortcutActive = false;

                // Also hide dashboard and OSD if they're not being hovered
                const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.panels.dashboard.offsetScale, root.mouseX, root.mouseY);
                const inOsdArea = root.inRightPanel(root.panels.osdWrapper, root.mouseX, root.mouseY);

                if (!inDashboardArea) {
                    root.screenState.dashboard = false;
                }
                if (!inOsdArea) {
                    root.screenState.osd = false;
                    root.panels.osd.hovered = false;
                }
            }
        }

        function onDashboardChanged() {
            if (root.screenState.dashboard) {
                // Dashboard became visible, immediately check if this should be shortcut mode
                const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.panels.dashboard.offsetScale, root.mouseX, root.mouseY);
                if (!inDashboardArea) {
                    root.dashboardShortcutActive = true;
                }
            } else {
                // Dashboard hidden, clear shortcut flag
                root.dashboardShortcutActive = false;
            }
        }

        function onOsdChanged() {
            if (root.screenState.osd) {
                // OSD became visible, immediately check if this should be shortcut mode
                const inOsdArea = root.inRightPanel(root.panels.osdWrapper, root.mouseX, root.mouseY);
                if (!inOsdArea) {
                    root.osdShortcutActive = true;
                }
            } else {
                // OSD hidden, clear shortcut flag
                root.osdShortcutActive = false;
            }
        }

        function onUtilitiesChanged() {
            if (root.screenState.utilities) {
                // Utilities became visible, immediately check if this should be shortcut mode
                const inUtilitiesArea = root.inBottomPanel(root.panels.utilities, root.panels.utilities.offsetScale, root.mouseX, root.mouseY, false);
                if (!inUtilitiesArea) {
                    root.utilitiesShortcutActive = true;
                }
            } else {
                // Utilities hidden, clear shortcut flag
                root.utilitiesShortcutActive = false;
            }
        }

        function onSidebarChanged() {
            if (root.screenState.sidebar) {
                // Sidebar became visible, immediately check if this should be shortcut mode
                const inSidebarArea = root.inRightPanel(root.panels.sidebar, root.mouseX, root.mouseY) || root.inRightPanel(root.panels.sessionWrapper, root.mouseX, root.mouseY) || root.inRightPanel(root.panels.utilities, root.mouseX, root.mouseY);
                if (!inSidebarArea)
                    root.sidebarShortcutActive = true;
            } else {
                // Sidebar hidden, clear shortcut flag
                root.sidebarShortcutActive = false;
            }
        }

        target: root.screenState
    }
}
