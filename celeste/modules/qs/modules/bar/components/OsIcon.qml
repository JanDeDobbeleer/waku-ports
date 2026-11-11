import QtQuick
import Celeste.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property ScreenState screenState

    implicitWidth: Math.round(Tokens.font.body.large.pointSize * 1.2)
    implicitHeight: Math.round(Tokens.font.body.large.pointSize * 1.2)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.screenState.launcher = !root.screenState.launcher;
        }
    }

    ColouredIcon {
        anchors.centerIn: parent
        source: SysInfo.osLogo
        implicitSize: Math.round(Tokens.font.body.large.pointSize * 1.2)
        colour: Colours.palette.m3tertiary
    }
}
