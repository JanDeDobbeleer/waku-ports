pragma Singleton

import "CalendarServiceUtils.js" as CalendarUtils

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Location.Calendar

Singleton {
  id: root

  // Core state
  property var events: ([])
  property bool loading: false
  property bool available: false
  property string lastError: ""
  property var calendars: ([])

  property var dataProvider: null

  // Persistent cache
  property string cacheFile: Settings.cacheDir + "calendar.json"

  // Cache file handling
  FileView {
    id: cacheFileView
    path: root.cacheFile
    printErrors: false

    JsonAdapter {
      id: cacheAdapter
      property var cachedEvents: ([])
      property var cachedCalendars: ([])
      property string lastUpdate: ""
    }

    onLoadFailed: {
      cacheAdapter.cachedEvents = ([]);
      cacheAdapter.cachedCalendars = ([]);
      cacheAdapter.lastUpdate = "";
    }

    onLoaded: {
      root.loadFromCache();
    }
  }

  Component.onCompleted: {
    Logger.i("Calendar", "Service started");
    loadFromCache();
    checkAvailability();
  }

  // Save cache with debounce
  Timer {
    id: saveDebounce
    interval: 1000
    onTriggered: cacheFileView.writeAdapter()
  }

  function setEvents(newEvents: var) {
    root.events = newEvents;
    cacheAdapter.cachedEvents = newEvents;
    cacheAdapter.lastUpdate = new Date().toISOString();
    saveCache();
  }

  function setCalendars(newCalendars: var) {
    root.calendars = newCalendars;
    cacheAdapter.cachedCalendars = newCalendars;
    saveCache();
  }

  function loadCachedEvents() {
    if (CalendarUtils.length(cacheAdapter.cachedEvents) > 0) {
      root.events = cacheAdapter.cachedEvents;
    }
  }

  function saveCache() {
    saveDebounce.restart();
  }

  // Load events and calendars from cache
  function loadFromCache() {
    if (cacheAdapter.cachedEvents && CalendarUtils.length(cacheAdapter.cachedEvents) > 0) {
      root.events = cacheAdapter.cachedEvents;
      Logger.d("Calendar", `Loaded ${CalendarUtils.length(cacheAdapter.cachedEvents)} cached event(s)`);
    }

    if (cacheAdapter.cachedCalendars && CalendarUtils.length(cacheAdapter.cachedCalendars) > 0) {
      root.calendars = cacheAdapter.cachedCalendars;
      Logger.d("Calendar", `Loaded ${CalendarUtils.length(cacheAdapter.cachedCalendars)} cached calendar(s)`);
    }

    if (cacheAdapter.lastUpdate) {
      Logger.d("Calendar", `Cache last updated: ${cacheAdapter.lastUpdate}`);
    }
  }

  // Auto-refresh timer (every 5 minutes)
  Timer {
    id: refreshTimer
    interval: 300000
    running: true
    repeat: true
    onTriggered: root.loadEvents(undefined, undefined)
  }

  // Core functions
  function checkAvailability() {
    // Events come from khal or Evolution Data Server, which Windows does not have: never available.
    if (true || !Settings.data.location.showCalendarEvents) {
      root.available = false;
      return;
    }

    Khal.init();
    EvolutionDataServer.init();
  }

  function loadCalendars() {
    if (!root.available || !dataProvider) {
      return;
    }

    dataProvider.loadCalendars();
  }
  function loadEvents(daysAhead: var, daysBehind: var): void {
    CalendarUtils.loadEvents(root, daysAhead, daysBehind);
  }
}
