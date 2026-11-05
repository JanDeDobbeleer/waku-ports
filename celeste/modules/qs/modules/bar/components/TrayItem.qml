pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

// One tray icon. Left click activates, middle click secondary-activates and right click asks the
// item to show its own menu (Explorer shows the real one). The icon keeps its own colours unless
// Config.bar.tray.recolour is set.
MouseArea {
    id: root

    required property var modelData
    property int size: Tokens.font.body.small.pointSize * 2

    readonly property string name: modelData.tooltipTitle || modelData.title || modelData.id

    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    hoverEnabled: true
    implicitWidth: size
    implicitHeight: size

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            modelData.activate();
        else if (event.button === Qt.MiddleButton)
            modelData.secondaryActivate();
        else
            modelData.display(QsWindow.window, event.x, event.y);
    }

    Loader {
        anchors.fill: parent
        active: !!root.modelData.fakeGlyph
        sourceComponent: MaterialIcon {
            text: root.modelData.fakeGlyph
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.medium
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Image {
        anchors.fill: parent
        visible: !root.modelData.fakeGlyph && !Config.bar.tray.recolour
        source: root.modelData.fakeGlyph ? "" : Icons.getTrayIcon(root.modelData.id, root.modelData.icon)
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
    }

    ColouredIcon {
        anchors.fill: parent
        visible: Config.bar.tray.recolour
        source: root.modelData.fakeGlyph || !Config.bar.tray.recolour ? "" : Icons.getTrayIcon(root.modelData.id, root.modelData.icon)
        colour: Colours.palette.m3secondary
    }
}
