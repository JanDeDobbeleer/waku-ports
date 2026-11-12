pragma Singleton

import "EvolutionDataUtils.js" as EvolutionUtils

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Location

Singleton {
  id: root

  // Python scripts
  readonly property string checkCalendarAvailableScript: Quickshell.shellDir + '/Scripts/python/src/calendar/check-calendar.py'
  readonly property string listCalendarsScript: Quickshell.shellDir + '/Scripts/python/src/calendar/list-calendars.py'
  readonly property string calendarEventsScript: Quickshell.shellDir + '/Scripts/python/src/calendar/calendar-events.py'

  function init() {
    availabilityCheckProcess.running = true;
  }
  function loadCalendars() {
    listCalendarsProcess.running = true;
  }
  function loadEvents(daysAhead: var, daysBehind: var): void {
    EvolutionUtils.loadEvents(CalendarService, loadEventsProcess, Logger, daysAhead, daysBehind);
  }

  // Process to check for evolution-data-server libraries
  Process {
    id: availabilityCheckProcess
    running: false
    command: ["sh", "-c", "command -v python3 >/dev/null 2>&1 && python3 " + root.checkCalendarAvailableScript + " || echo 'unavailable: python3 not installed'"]

    stdout: StdioCollector {
      onStreamFinished: {
        const result = text.trim();
        if (result === "available") {
          CalendarService.dataProvider = CalendarService.dataProvider || root;
          CalendarService.available = true;
        }

        if (CalendarService.available) {
          Logger.i("Calendar", "EDS libraries available");
          root.loadCalendars();
        } else {
          Logger.w("Calendar", "EDS libraries not available: " + result);
          CalendarService.lastError = "Evolution Data Server libraries not installed";
        }
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {
          Logger.d("Calendar", "Availability check error: " + text);
          CalendarService.lastError = "Failed to check library availability";
        }
      }
    }
  }

  // Process to list available calendars
  Process {
    id: listCalendarsProcess
    running: false
    command: ["python3", root.listCalendarsScript]

    stdout: StdioCollector {
      id: calendarsOutput
      onStreamFinished: {
        EvolutionUtils.calendarsLoaded(calendarsOutput, root, CalendarService, Logger);
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {
          Logger.d("Calendar", "List calendars error: " + text);
          CalendarService.lastError = text.trim();
        }
      }
    }
  }

  // Process to load events
  Process {
    id: loadEventsProcess
    running: false
    property int startTime: 0
    property int endTime: 0

    command: ["python3", root.calendarEventsScript, startTime.toString(), endTime.toString()]

    stdout: StdioCollector {
      id: eventsOutput
      onStreamFinished: {
        CalendarService.loading = false;

        EvolutionUtils.eventsLoaded(eventsOutput, root, CalendarService, Logger);
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        CalendarService.loading = false;

        if (text.trim()) {
          Logger.d("Calendar", "Load events error: " + text);
          CalendarService.lastError = text.trim();

          // Fall back to cached events
          CalendarService.loadCachedEvents();
          Logger.d("Calendar", "Using cached events");
        }
      }
    }
  }
}
