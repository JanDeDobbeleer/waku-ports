.pragma library

function loadEvents(CalendarService, loadEventsProcess, Logger, daysAhead = 31, daysBehind = 14) {
    CalendarService.loading = true;
    CalendarService.lastError = "";

    const now = new Date();
    const startDate = new Date(now.getTime() - (daysBehind * 24 * 60 * 60 * 1000));
    const endDate = new Date(now.getTime() + (daysAhead * 24 * 60 * 60 * 1000));

    loadEventsProcess.startTime = Math.floor(startDate.getTime() / 1000);
    loadEventsProcess.endTime = Math.floor(endDate.getTime() / 1000);
    loadEventsProcess.running = true;

    Logger.d("Calendar", `Loading events (${daysBehind} days behind, ${daysAhead} days ahead): ${startDate.toLocaleDateString()} to ${endDate.toLocaleDateString()}`);
}

function calendarsLoaded(collector, root, CalendarService, Logger) {
        try {
          const result = JSON.parse(collector.text.trim());
          CalendarService.setCalendars(result);
          Logger.d("Calendar", `Found ${result.length} calendar(s)`);

          // Auto-load events after discovering calendars
          if (result.length > 0) {
            root.loadEvents(undefined, undefined);
          }
        } catch (e) {
          Logger.d("Calendar", "Failed to parse calendars: " + e);
          CalendarService.lastError = "Failed to parse calendar list";
        }
}

function eventsLoaded(collector, root, CalendarService, Logger) {
        try {
          const events = JSON.parse(collector.text.trim());
          CalendarService.setEvents(events);
          Logger.d("Calendar", `Loaded ${events.length} events(s)`);
        } catch (e) {
          Logger.d("Calendar", "Failed to parse events: " + e);
          CalendarService.lastError = "Failed to parse events";
          // Fall back to cached events
          CalendarService.loadCachedEvents();
          Logger.d("Calendar", "Using cached events");
        }
}
