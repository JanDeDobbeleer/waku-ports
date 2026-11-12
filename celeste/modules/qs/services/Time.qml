pragma Singleton

import QtQuick
import Quickshell
import Celeste.I18n
import qs.compat

Singleton {
    property alias enabled: clock.enabled
    readonly final property date date: clock.date
    readonly final property int hours: clock.hours
    readonly final property int minutes: clock.minutes
    readonly final property int seconds: clock.seconds

    readonly final property string timeStr: format(Units.twelveHourClock ? "hh:mm:A" : "hh:mm")
    readonly final property list<string> timeComponents: timeStr.split(":")
    readonly final property string hourStr: timeComponents[0] ?? ""
    readonly final property string minuteStr: timeComponents[1] ?? ""
    readonly final property string amPmStr: timeComponents[2] ?? ""

    function format(fmt: string): string {
        return Tr.formatDateTime(clock.date, fmt);
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }
}
