pragma ComponentBehavior: Bound

import QtQuick
import Celeste.Config
import qs.components

Item {
    id: root

    required final property ScreenState screenState
    required final property bool sidebarVisible
    readonly final property real nonAnimWidth: content.implicitWidth

    readonly final property bool shouldBeActive: screenState.session && Config.session.enabled
    final property real offsetScale: shouldBeActive ? 0 : 1
    final property real sidebarOffset: sidebarVisible ? 14 : 0

    visible: offsetScale < 1
    anchors.rightMargin: (-implicitWidth - 5 - sidebarOffset) * offsetScale
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight || 510 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
        }
    }
}
