pragma ComponentBehavior: Bound

import QtQuick
import Celeste.Config
import Celeste.I18n
import qs.components
import qs.services
import qs.modules.dashboard.dash as DashCards

// Port (not upstream): the flyout of the bar clock. A header with the full date and the time, then
// the dashboard's month calendar (same state: screenState.dashboardDate).
Column {
    id: root

    required final property ScreenState screenState

    spacing: Tokens.spacing.small
    width: Tokens.px(280)

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter

        text: Time.format("dddd d MMMM yyyy")
        color: Colours.palette.m3tertiary
        font: Tokens.font.title.small
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter

        text: Time.format(Units.twelveHourClock ? "h:mm AP" : "HH:mm")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    Item {
        width: parent.width
        height: calendar.implicitHeight

        DashCards.Calendar {
            id: calendar

            screenState: root.screenState
        }
    }
}
