pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste.Config
import qs.modules.bar as Bar

Region {
    id: root

    required final property Bar.BarWrapper bar
    required final property real barWidth
    required final property Panels panels
    required final property real winWidth
    required final property real winHeight
    required final property real dragMaskPadding

    readonly final property real borderThickness: Config.border.thickness
    readonly final property real clampedThickness: Config.border.clampedThickness

    x: bar.clampedWidth + dragMaskPadding
    y: clampedThickness + dragMaskPadding
    width: winWidth - bar.clampedWidth - clampedThickness - dragMaskPadding * 2
    height: winHeight - clampedThickness * 2 - dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        y: 0
        h_: panel.height * (1 - root.panels.dashboard.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.launcher
        y: root.winHeight - h_
        h_: panel.height * (1 - root.panels.launcher.offsetScale) + root.borderThickness
    }

    R {
        id: sessionRegion

        panel: root.panels.sessionWrapper
        x: root.winWidth - w_
        w_: panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness + sidebarRegion.w_
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar
        x: root.winWidth - w_
        w_: panel.width * (1 - root.panels.sidebar.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.osdWrapper
        x: root.winWidth - w_
        w_: panel.width * (1 - root.panels.osd.offsetScale) + root.borderThickness + sessionRegion.w_
    }

    R {
        panel: root.panels.notifications
        y: 0
        h_: panel.height + root.borderThickness
    }

    R {
        panel: root.panels.utilities
        y: root.winHeight - h_
        h_: panel.height * (1 - root.panels.utilities.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.popoutsWrapper
        w_: panel.width * (1 - root.panels.popoutsWrapper.offsetScale)
    }

    component R: Region {
        required final property Item panel

        // Port: waku's Region has one change signal for x, y, width and height, so a binding
        // that reads its own width or height loops. The size lives in w_ and h_ instead.
        final property real w_: panel.width
        final property real h_: panel.height

        x: panel.x + root.barWidth
        y: panel.y + root.borderThickness
        width: w_
        height: h_
        intersection: Intersection.Subtract
    }
}
