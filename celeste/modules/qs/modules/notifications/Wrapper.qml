import QtQuick
import Celeste.Config
import qs.components

Item {
    id: root

    required final property ScreenState screenState
    required final property Item sidebarPanel
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel
    property alias utilitiesPanel: content.utilitiesPanel

    visible: height > 0
    anchors.topMargin: -Tokens.px(5)
    implicitWidth: Math.max(sidebarPanel.width, content.implicitWidth)
    implicitHeight: content.implicitHeight

    Content {
        id: content

        anchors.topMargin: -root.anchors.topMargin
        screenState: root.screenState
    }
}
