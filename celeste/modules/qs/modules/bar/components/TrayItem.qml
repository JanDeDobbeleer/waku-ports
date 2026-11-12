pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils
import "TrayItemHelpers.js" as TrayItemHelpers

// One tray icon. Left click activates, middle click secondary-activates and right click asks the
// item to show its own menu (Explorer shows the real one). The icon keeps its own colours unless
// Config.bar.tray.recolour is set.
MouseArea {
    id: root

    required final property var modelData
    final property int size: Tokens.font.body.small.pointSize * 2

    readonly final property string name: TrayItemHelpers.name(modelData)

    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    hoverEnabled: true
    implicitWidth: size
    implicitHeight: size

    onClicked: event => TrayItemHelpers.activate(modelData, event, Qt, QsWindow.window)

    Loader {
        anchors.fill: parent
        active: !!TrayItemHelpers.fakeGlyph(root.modelData)
        sourceComponent: MaterialIcon {
            text: TrayItemHelpers.fakeGlyph(root.modelData)
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.medium
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Image {
        anchors.fill: parent
        visible: !TrayItemHelpers.fakeGlyph(root.modelData) && !Config.bar.tray.recolour
        source: TrayItemHelpers.fakeGlyph(root.modelData) ? "" : TrayItemHelpers.iconPath(root.modelData, Icons)
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
    }

    ColouredIcon {
        anchors.fill: parent
        visible: Config.bar.tray.recolour
        source: TrayItemHelpers.fakeGlyph(root.modelData) || !Config.bar.tray.recolour ? "" : TrayItemHelpers.iconPath(root.modelData, Icons)
        colour: Colours.palette.m3secondary
    }
}
