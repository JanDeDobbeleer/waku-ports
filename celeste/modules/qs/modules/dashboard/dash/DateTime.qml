pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Celeste.Config
import Celeste.I18n
import qs.components
import qs.services
import "DateTimeHelpers.js" as DateTimeHelpers

Item {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Tokens.sizes.dashboard.dateTimeWidth

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        StyledText {
            Layout.bottomMargin: -(font.pointSize * 0.4)
            Layout.alignment: Qt.AlignHCenter
            text: Time.hourStr
            color: Colours.palette.m3secondary
            font: Tokens.clockFont({ size: 28, weight: Font.DemiBold })
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "•••"
            color: Colours.palette.m3primary
            font: Tokens.clockFont({ size: 28 * 0.9 })
        }

        StyledText {
            Layout.topMargin: -(font.pointSize * 0.4)
            Layout.alignment: Qt.AlignHCenter
            text: Time.minuteStr
            color: Colours.palette.m3secondary
            font: Tokens.clockFont({ size: 28, weight: Font.DemiBold })
        }

        Loader {
            Layout.topMargin: -DateTimeHelpers.topMargin(item)
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: Config.dashboard.showClockSeconds
            visible: active

            sourceComponent: StyledText {
                text: "•••"
                color: Colours.palette.m3primary
                font: Tokens.clockFont({ size: 28 * 0.9 })
            }
        }
        Loader {
            Layout.topMargin: -DateTimeHelpers.topMargin(item)
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: Config.dashboard.showClockSeconds
            visible: active

            sourceComponent: StyledText {
                text: Time.format("ss")
                color: Colours.palette.m3secondary
                font: Tokens.clockFont({ size: 28, weight: Font.DemiBold })
            }
        }

        Loader {
            asynchronous: true
            Layout.alignment: Qt.AlignHCenter

            active: Units.twelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: Time.amPmStr
                color: Colours.palette.m3primary
                font: Tokens.clockFont({ size: 18, weight: Font.DemiBold })
            }
        }
    }
}
