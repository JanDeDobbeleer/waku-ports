pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste.Config
import qs.components
import qs.modules.launcher.services
import "LauncherWrapperHelpers.js" as LauncherWrapperHelpers

Item {
    id: root

    required final property ShellScreen screen
    required final property ScreenState screenState
    required final property var panels

    readonly final property bool shouldBeActive: screenState.launcher && Config.launcher.enabled

    readonly final property real maxHeight: {
        return LauncherWrapperHelpers.maxHeight(screen.height, Config.border.thickness, Tokens.padding.extraLarge, screenState.dashboard, panels);
    }

    final property real offsetScale: shouldBeActive ? 0 : 1

    function contentHeight(): real { return content.implicitHeight; }
    function preloadApps(): void { LauncherWrapperHelpers.preload(Apps); }

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            implicitHeight = Qt.binding(root.contentHeight);
        else
            implicitHeight = implicitHeight; // Break binding during close anim
    }

    visible: offsetScale < 1
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 630 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    Component.onCompleted: Qt.callLater(root.preloadApps) // Load apps on init

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight
        }
    }
}
