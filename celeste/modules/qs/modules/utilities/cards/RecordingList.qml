pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Celeste.Config
import Celeste.I18n
import Celeste.Models
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property var props
    required property ScreenState screenState

    spacing: 0

    WrapperMouseArea {
        Layout.fillWidth: true

        cursorShape: Qt.PointingHandCursor
        onClicked: root.props.recordingListExpanded = !root.props.recordingListExpanded

        RowLayout {
            spacing: Tokens.spacing.medium

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: "list"
                fontStyle: Tokens.font.icon.large
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                text: Tr.tr("Recordings")
                font: Tokens.font.body.medium
            }

            IconButton {
                icon: root.props.recordingListExpanded ? "unfold_less" : "unfold_more"
                type: IconButton.Text
                label.animate: true
                onClicked: root.props.recordingListExpanded = !root.props.recordingListExpanded
            }
        }
    }

    // waku gap: no screen recorder on Windows yet, so there is no recording folder to list, play,
    // reveal or delete. The header keeps upstream's layout; the body is a notice.
    StyledRect {
        Layout.fillWidth: true
        implicitHeight: (Tokens.font.body.large.pointSize + Tokens.padding.small) * (root.props.recordingListExpanded ? 10 : 3)
        radius: Tokens.rounding.small
        color: Colours.tPalette.m3surfaceContainerHigh

        RowLayout {
            anchors.centerIn: parent
            width: parent.width - Tokens.padding.large * 2
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: "videocam_off"
                color: Colours.palette.m3outline
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Recording is not available on Windows yet")
                color: Colours.palette.m3outline
                wrapMode: Text.WordWrap
            }
        }

        Behavior on implicitHeight {
            Anim {}
        }
    }
}
