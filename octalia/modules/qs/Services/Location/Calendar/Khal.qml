pragma Singleton

import "KhalUtils.js" as KhalUtils

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Location

Singleton {
  id: root

  readonly property string khalEventsScript: Quickshell.shellDir + '/Scripts/python/src/calendar/khal-events.py'

  function init() {
    availabilityCheckProcess.running = true;
  }
  function loadCalendars() {
    listCalendarsProcess.running = true;
  }
  function loadEvents(daysAhead: var, daysBehind: var): void {
    KhalUtils.loadEvents(root, CalendarService, loadEventsProcess, Logger, daysAhead, daysBehind);
  }

  // Process to check for khal installation
  Process {
    id: availabilityCheckProcess
    running: false
    command: ["sh", "-c", "command -v khal >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1"]
    onExited: function (exitCode) {
      if (exitCode === 0) {
        CalendarService.available = true;
        CalendarService.dataProvider = CalendarService.dataProvider || root;
      }

      if (CalendarService.available) {
        Logger.i("Calendar", "Khal available");
        root.loadCalendars();
      } else {
        Logger.w("Calendar", "Khal not available");
        CalendarService.lastError = "khal binary not installed";
      }
    }
  }

  // Process to list available calendars
  Process {
    id: listCalendarsProcess
    running: false
    command: ["khal", "printcalendars"]

    stdout: StdioCollector {
      id: calendarsOutput
      onStreamFinished: {
        KhalUtils.calendarsLoaded(calendarsOutput, root, CalendarService, Logger);
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
    property string startTime: ""
    property string duration: ""

    command: ["python3", root.khalEventsScript, startTime, duration]

    stdout: StdioCollector {
      id: eventsOutput
      onStreamFinished: {
        CalendarService.loading = false;

        KhalUtils.eventsLoaded(eventsOutput, root, CalendarService, Logger);
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

  function parseEvents(text: var): var {
    return KhalUtils.parseEvents(text, root);
  }

  function parseTimestamp(timeStr: var): real {
    // expects ISO8601 format
    return Math.floor((Date.parse(timeStr)).valueOf() / 1000);
  }

  function formatDateYMD(date: var): string {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, "0");
    const d = String(date.getDate()).padStart(2, "0");
    return y + "-" + m + "-" + d;
  }
}
