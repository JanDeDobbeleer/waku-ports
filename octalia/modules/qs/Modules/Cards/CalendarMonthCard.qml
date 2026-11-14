pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Location
import qs.Services.System
import qs.Widgets
import "./CalendarMonthCardUtils.js" as CalendarMonthCardUtils

// Calendar month grid with navigation
NBox {
  id: root
  Layout.fillWidth: true
  implicitHeight: calendarContent.implicitHeight + Style.margin2M

  // Internal state - independent from header
  readonly property var now: Time.now
  property int calendarMonth: now.getMonth()
  property int calendarYear: now.getFullYear()
  readonly property int firstDayOfWeek: Settings.data.location.firstDayOfWeek === -1 ? CalendarMonthCardUtils.firstDayOfWeek(I18n.locale) : Settings.data.location.firstDayOfWeek

  // Helper function to calculate ISO week number
  function getISOWeekNumber(date: var): int {
    return CalendarMonthCardUtils.getISOWeekNumber(date);
  }

  // Helper function to check if an event is all-day
  function isAllDayEvent(event: var): bool {
    return CalendarMonthCardUtils.isAllDayEvent(event);
  }

  // Navigation functions
  function navigateToPreviousMonth(): void {
    let newDate = new Date(root.calendarYear, root.calendarMonth - 1, 1);
    root.calendarYear = newDate.getFullYear();
    root.calendarMonth = newDate.getMonth();
    const now = new Date();
    const monthStart = new Date(root.calendarYear, root.calendarMonth, 1);
    const monthEnd = new Date(root.calendarYear, root.calendarMonth + 1, 0);
    const daysBehind = Math.max(0, Math.ceil((now - monthStart) / (24 * 60 * 60 * 1000)));
    const daysAhead = Math.max(0, Math.ceil((monthEnd - now) / (24 * 60 * 60 * 1000)));
    CalendarService.loadEvents(daysAhead + 30, daysBehind + 30);
  }

  function navigateToNextMonth(): void {
    let newDate = new Date(root.calendarYear, root.calendarMonth + 1, 1);
    root.calendarYear = newDate.getFullYear();
    root.calendarMonth = newDate.getMonth();
    const now = new Date();
    const monthStart = new Date(root.calendarYear, root.calendarMonth, 1);
    const monthEnd = new Date(root.calendarYear, root.calendarMonth + 1, 0);
    const daysBehind = Math.max(0, Math.ceil((now - monthStart) / (24 * 60 * 60 * 1000)));
    const daysAhead = Math.max(0, Math.ceil((monthEnd - now) / (24 * 60 * 60 * 1000)));
    CalendarService.loadEvents(daysAhead + 30, daysBehind + 30);
  }

  // Wheel handler for month navigation
  WheelHandler {
    id: wheelHandler
    target: root
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function (event) {
      if (event.angleDelta.y > 0) {
        // Scroll up - go to previous month
        root.navigateToPreviousMonth();
        event.accepted = true;
      } else if (event.angleDelta.y < 0) {
        // Scroll down - go to next month
        root.navigateToNextMonth();
        event.accepted = true;
      }
    }
  }

  ColumnLayout {
    id: calendarContent
    anchors.fill: parent
    anchors.margins: Style.marginM
    spacing: Style.marginS

    // Navigation row
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      Item {
        Layout.preferredWidth: Style.marginS
      }

      NText {
        text: I18n.locale.monthName(root.calendarMonth, Locale.LongFormat).toUpperCase() + " " + root.calendarYear
        pointSize: Style.fontSizeM
        font.weight: Style.fontWeightBold
        color: Color.mOnSurface
      }

      NDivider {
        Layout.fillWidth: true
      }

      NIconButton {
        icon: "chevron-left"
        onClicked: root.navigateToPreviousMonth()
      }

      NIconButton {
        icon: "calendar"
        onClicked: {
          root.calendarMonth = root.now.getMonth();
          root.calendarYear = root.now.getFullYear();
          CalendarService.loadEvents(undefined, undefined);
        }
      }

      NIconButton {
        icon: "chevron-right"
        onClicked: root.navigateToNextMonth()
      }
    }

    // Day names header
    RowLayout {
      Layout.fillWidth: true
      spacing: 0

      Item {
        visible: Settings.data.location.showWeekNumberInCalendar
        Layout.preferredWidth: visible ? Style.baseWidgetSize * 0.7 : 0
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 7
        rows: 1
        columnSpacing: 0
        rowSpacing: 0

        Repeater {
          model: 7
          Item {
            id: weekDayLabel
            required property int index
            Layout.fillWidth: true
            Layout.preferredHeight: Style.fontSizeS * 2

            NText {
              anchors.centerIn: parent
              text: {
                let dayIndex = (root.firstDayOfWeek + weekDayLabel.index) % 7;
                const dayName = I18n.locale.dayName(dayIndex, Locale.ShortFormat);
                return dayName.substring(0, 2).toUpperCase();
              }
              color: Color.mPrimary
              pointSize: Style.fontSizeS
              font.weight: Style.fontWeightBold
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }
      }
    }

    // Calendar grid with week numbers
    RowLayout {
      Layout.fillWidth: true
      spacing: 0

      // Helper functions
      id: calendarGridRoot

      function hasEventsOnDate(year: int, month: int, day: int): bool {
        return CalendarMonthCardUtils.hasEventsOnDate(CalendarService.available, CalendarService.events, year, month, day);
      }

      function getEventsForDate(year: int, month: int, day: int): var {
        return CalendarMonthCardUtils.getEventsForDate(CalendarService.available, CalendarService.events, year, month, day);
      }

      function isMultiDayEvent(event: var): bool {
        return CalendarMonthCardUtils.isMultiDayEvent(event);
      }

      function getEventColor(event: var, isToday: bool): color {
        if (isMultiDayEvent(event))
          return isToday ? Color.mOnSecondary : Color.mTertiary;
        if (root.isAllDayEvent(event))
          return isToday ? Color.mOnSecondary : Color.mSecondary;
        return isToday ? Color.mOnSecondary : Color.mPrimary;
      }

      // Week numbers column
      ColumnLayout {
        visible: Settings.data.location.showWeekNumberInCalendar
        Layout.preferredWidth: visible ? Style.baseWidgetSize * 0.7 : 0
        Layout.alignment: Qt.AlignTop
        spacing: Style.marginXXS

        id: weekNumbersColumn
        property var weekNumbers: {
          var i;
          if (!grid.daysModel || CalendarMonthCardUtils.arrayLength(grid.daysModel) === 0)
            return [];
          const weeks = [];
          const numWeeks = Math.ceil(CalendarMonthCardUtils.arrayLength(grid.daysModel) / 7);
          for (i = 0; i < numWeeks; i++) {
            const dayIndex = i * 7;
            if (dayIndex < CalendarMonthCardUtils.arrayLength(grid.daysModel)) {
              const weekDay = grid.daysModel[dayIndex];
              const date = new Date(weekDay.year, weekDay.month, weekDay.day);
              let thursday = new Date(date);
              if (root.firstDayOfWeek === 0) {
                thursday.setDate(date.getDate() + 4);
              } else if (root.firstDayOfWeek === 1) {
                thursday.setDate(date.getDate() + 3);
              } else {
                let daysToThursday = (4 - root.firstDayOfWeek + 7) % 7;
                thursday.setDate(date.getDate() + daysToThursday);
              }
              weeks.push(root.getISOWeekNumber(thursday));
            }
          }
          return weeks;
        }

        Repeater {
          model: weekNumbersColumn.weekNumbers
          Item {
            id: weekNumber
            required property int modelData
            Layout.preferredWidth: Style.baseWidgetSize * 0.7
            Layout.preferredHeight: Style.baseWidgetSize * 0.9

            NText {
              anchors.centerIn: parent
              color: Qt.alpha(Color.mPrimary, 0.7)
              pointSize: Style.fontSizeXXS
              text: weekNumber.modelData
            }
          }
        }
      }

      // Calendar grid
      GridLayout {
        id: grid
        Layout.fillWidth: true
        columns: 7
        columnSpacing: Style.marginXXS
        rowSpacing: Style.marginXXS

        property int month: root.calendarMonth
        property int year: root.calendarYear

        property var daysModel: {
          var day, i;
          const firstOfMonth = new Date(year, month, 1);
          const lastOfMonth = new Date(year, month + 1, 0);
          const daysInMonth = lastOfMonth.getDate();
          const firstDayOfWeek = root.firstDayOfWeek;
          const firstOfMonthDayOfWeek = firstOfMonth.getDay();
          let daysBefore = (firstOfMonthDayOfWeek - firstDayOfWeek + 7) % 7;
          const lastOfMonthDayOfWeek = lastOfMonth.getDay();
          const daysAfter = (firstDayOfWeek - lastOfMonthDayOfWeek - 1 + 7) % 7;
          const days = [];
          const today = new Date();

          // Previous month days
          const prevMonth = new Date(year, month, 0);
          const prevMonthDays = prevMonth.getDate();
          for (i = daysBefore - 1; i >= 0; i--) {
            const day = prevMonthDays - i;
            days.push({
                        "day": day,
                        "month": month - 1,
                        "year": month === 0 ? year - 1 : year,
                        "today": false,
                        "currentMonth": false
                      });
          }

          // Current month days
          for (day = 1; day <= daysInMonth; day++) {
            const date = new Date(year, month, day);
            const isToday = date.getFullYear() === today.getFullYear() && date.getMonth() === today.getMonth() && date.getDate() === today.getDate();
            days.push({
                        "day": day,
                        "month": month,
                        "year": year,
                        "today": isToday,
                        "currentMonth": true
                      });
          }

          // Next month days
          for (i = 1; i <= daysAfter; i++) {
            days.push({
                        "day": i,
                        "month": month + 1,
                        "year": month === 11 ? year + 1 : year,
                        "today": false,
                        "currentMonth": false
                      });
          }

          return days;
        }

        Repeater {
          model: grid.daysModel

          Item {
            id: calendarDay
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredHeight: Style.baseWidgetSize * 0.9

            Rectangle {
              width: Style.baseWidgetSize * 0.9
              height: Style.baseWidgetSize * 0.9
              anchors.centerIn: parent
              radius: Style.radiusM
              color: CalendarMonthCardUtils.field(calendarDay.modelData, "today") ? Color.mSecondary : "transparent"

              NText {
                anchors.centerIn: parent
                text: CalendarMonthCardUtils.field(calendarDay.modelData, "day")
                color: {
                  if (CalendarMonthCardUtils.field(calendarDay.modelData, "today"))
                    return Color.mOnSecondary;
                  if (CalendarMonthCardUtils.field(calendarDay.modelData, "currentMonth"))
                    return Color.mOnSurface;
                  return Color.mOnSurfaceVariant;
                }
                opacity: CalendarMonthCardUtils.field(calendarDay.modelData, "currentMonth") ? 1.0 : 0.4
                pointSize: Style.fontSizeM
                font.weight: CalendarMonthCardUtils.field(calendarDay.modelData, "today") ? Style.fontWeightBold : Style.fontWeightMedium
              }

              // Event indicator dots
              Row {
                visible: Settings.data.location.showCalendarEvents && calendarGridRoot.hasEventsOnDate(CalendarMonthCardUtils.field(calendarDay.modelData, "year"), CalendarMonthCardUtils.field(calendarDay.modelData, "month"), CalendarMonthCardUtils.field(calendarDay.modelData, "day"))
                spacing: 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Style.marginXS

                Repeater {
                  model: calendarGridRoot.getEventsForDate(CalendarMonthCardUtils.field(calendarDay.modelData, "year"), CalendarMonthCardUtils.field(calendarDay.modelData, "month"), CalendarMonthCardUtils.field(calendarDay.modelData, "day"))

                  Rectangle {
                    id: eventDot
                    required property var modelData
                    width: 4
                    height: width
                    radius: Style.radiusXXS
                    color: calendarGridRoot.getEventColor(eventDot.modelData, CalendarMonthCardUtils.field(eventDot.modelData, "today"))
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                enabled: Settings.data.location.showCalendarEvents

                onClicked: {
                  const dateWithSlashes = CalendarMonthCardUtils.dateString(CalendarMonthCardUtils.field(calendarDay.modelData, "month"), CalendarMonthCardUtils.field(calendarDay.modelData, "day"), CalendarMonthCardUtils.field(calendarDay.modelData, "year"));
                  if (ProgramCheckerService.gnomeCalendarAvailable) {
                    Quickshell.execDetached(["gnome-calendar", "--date", dateWithSlashes]);
                  }
                }
              }

              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }
            }
          }
        }
      }
    }
  }
}
