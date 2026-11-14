.pragma library

function parseEvents(text, root) {
    const result = [];
    const duplicates = new Set();

    for (const line of text.split("\n")) {
      if (!line.trim())
        continue;
      const dayEvents = JSON.parse(line);
      for (const event of dayEvents) {
        if (event["repeat-pattern"] !== "") {
          // if there is a repeat pattern, the event must be included each time
          result.push({
                        uid: event.uid,
                        calendar: event.calendar,
                        summary: event.title,
                        start: root.parseTimestamp(event["start-long-full"]),
                        end: root.parseTimestamp(event["end-long-full"]),
                        location: event.location,
                        description: event.description
                      });
        } else if (!duplicates.has(event.uid)) {
          // in any other cases, we must remove duplicates using the uid of the event
          result.push({
                        uid: event.uid,
                        calendar: event.calendar,
                        summary: event.title,
                        start: root.parseTimestamp(event["start-long-full"]),
                        end: root.parseTimestamp(event["end-long-full"]),
                        location: event.location,
                        description: event.description
                      });
          duplicates.add(event.uid);
        }
      }
    }

    return result;
}

function calendarsLoaded(collector, root, CalendarService, Logger) {
        try {
          const calendars = collector.text.trim().split("\n");
          CalendarService.setCalendars(calendars);

          Logger.d("Calendar", `Found ${calendars.length} calendar(s)`);

          // Auto-load events after discovering calendars
          if (calendars.length > 0) {
            root.loadEvents(undefined, undefined);
          }
        } catch (e) {
          Logger.d("Calendar", "Failed to parse calendars: " + e);
          CalendarService.lastError = "Failed to parse calendar list";
        }
}

function eventsLoaded(collector, root, CalendarService, Logger) {
        try {
          const events = parseEvents(collector.text.trim(), root);
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

function loadEvents(root, CalendarService, process, Logger, daysAhead = 31, daysBehind = 14) {
  CalendarService.loading = true;
  CalendarService.lastError = "";
  const now = new Date();
  const startDate = new Date(now.getTime() - (daysBehind * 24 * 60 * 60 * 1000));
  process.startTime = root.formatDateYMD(startDate);
  process.duration = `${daysAhead + daysBehind}d`;
  process.running = true;
  Logger.d("Calendar", `Loading events (${daysBehind} days behind, ${daysAhead} days ahead): ${process.startTime}  ${process.duration}`);
}
