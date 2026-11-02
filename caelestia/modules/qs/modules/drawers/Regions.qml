pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.modules.bar as Bar

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    readonly property real borderThickness: win.Config.border.thickness
    readonly property real clampedThickness: win.Config.border.clampedThickness

    x: bar.clampedWidth + win.dragMaskPadding
    y: clampedThickness + win.dragMaskPadding
    width: win.width - bar.clampedWidth - clampedThickness - win.dragMaskPadding * 2
    height: win.height - clampedThickness * 2 - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        y: 0
        h_: panel.height * (1 - root.panels.dashboard.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.launcher
        y: root.win.height - h_
        h_: panel.height * (1 - root.panels.launcher.offsetScale) + root.borderThickness
    }

    R {
        id: sessionRegion

        panel: root.panels.sessionWrapper
        x: root.win.width - w_
        w_: panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness + sidebarRegion.w_
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar
        x: root.win.width - w_
        w_: panel.width * (1 - root.panels.sidebar.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.osdWrapper
        x: root.win.width - w_
        w_: panel.width * (1 - root.panels.osd.offsetScale) + root.borderThickness + sessionRegion.w_
    }

    R {
        panel: root.panels.notifications
        y: 0
        h_: panel.height + root.borderThickness
    }

    R {
        panel: root.panels.utilities
        y: root.win.height - h_
        h_: panel.height * (1 - root.panels.utilities.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.popoutsWrapper
        w_: panel.width * (1 - root.panels.popoutsWrapper.offsetScale)
    }

    component R: Region {
        required property Item panel

        // Port: waku's Region has one change signal for x, y, width and height, so a binding
        // that reads its own width or height loops. The size lives in w_ and h_ instead.
        property real w_: panel.width
        property real h_: panel.height

        x: panel.x + root.bar.implicitWidth
        y: panel.y + root.borderThickness
        width: w_
        height: h_
        intersection: Intersection.Subtract
    }
}
