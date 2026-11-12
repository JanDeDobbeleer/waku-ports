pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// The taskbar clock: the time over the date, right aligned, as Start11 draws it.
Column {
    spacing: 0

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        anchors.right: parent.right
        text: Qt.formatDateTime(clock.date, "h:mm AP")
        color: Style.text
        font.family: Style.font
        font.pixelSize: Style.smallSize
    }
    Text {
        anchors.right: parent.right
        text: Qt.formatDateTime(clock.date, Qt.locale().dateFormat(Locale.ShortFormat))
        color: Style.text
        font.family: Style.font
        font.pixelSize: Style.smallSize
    }
}
