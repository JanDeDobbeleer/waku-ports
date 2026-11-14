.pragma library

function firstDayOfWeek(locale) {
  return locale.firstDayOfWeek;
}

function arrayLength(items) {
  return items ? items.length : 0;
}

function field(record, name) {
  return record ? record[name] : undefined;
}

function getISOWeekNumber(date) {
  var target = new Date(date.valueOf());
  var dayNr = (date.getDay() + 6) % 7;
  target.setDate(target.getDate() - dayNr + 3);
  var firstThursday = new Date(target.getFullYear(), 0, 4);
  var diff = target - firstThursday;
  var oneWeek = 1000 * 60 * 60 * 24 * 7;
  return 1 + Math.round(diff / oneWeek);
}

function isAllDayEvent(event) {
  var duration = event.end - event.start;
  var startDate = new Date(event.start * 1000);
  var isAtMidnight = startDate.getHours() === 0 && startDate.getMinutes() === 0;
  return duration === 86400 && isAtMidnight;
}

function eventMatchesDate(event, start, end) {
  return (event.start >= start && event.start < end) || (event.end > start && event.end <= end) || (event.start < start && event.end > end);
}

function dateRange(year, month, day) {
  var target = new Date(year, month, day);
  var start = Math.floor(new Date(target.getFullYear(), target.getMonth(), target.getDate()).getTime() / 1000);
  return { start: start, end: start + 86400 };
}

function hasEventsOnDate(available, events, year, month, day) {
  if (!available || !events || events.length === 0)
    return false;
  var range = dateRange(year, month, day);
  for (var i = 0; i < events.length; ++i) {
    if (eventMatchesDate(events[i], range.start, range.end))
      return true;
  }
  return false;
}

function getEventsForDate(available, events, year, month, day) {
  if (!available || !events || events.length === 0)
    return [];
  var range = dateRange(year, month, day);
  var matches = [];
  for (var i = 0; i < events.length; ++i) {
    if (eventMatchesDate(events[i], range.start, range.end))
      matches.push(events[i]);
  }
  return matches;
}

function isMultiDayEvent(event) {
  if (isAllDayEvent(event))
    return false;
  var startDate = new Date(event.start * 1000);
  var endDate = new Date(event.end * 1000);
  var startDateOnly = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate());
  var endDateOnly = new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate());
  return startDateOnly.getTime() !== endDateOnly.getTime();
}

function dateString(month, day, year) {
  return (month + 1).toString().padStart(2, "0") + "/" + day.toString().padStart(2, "0") + "/" + year.toString().substring(2);
}
