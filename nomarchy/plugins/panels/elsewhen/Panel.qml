pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model
import "Dynamic.js" as Dynamic
import "GlobeModel.js" as Solar

// A bar button that opens a panel of clocks, one row per city, and zooms into
// a globe. QML has no Intl, so a `date` probe supplies each zone's offset and
// the rows tick locally against it; the probe re-runs on open and every five
// minutes to catch DST.
Panel {
  id: root
  moduleName: "nomarchy.elsewhen"
  ipcTarget: "nomarchy.elsewhen"
  manageIpc: false

  // Items inside the panel's lazily built content, null until it first
  // opens. Code inside the content reaches its own ids directly.
  readonly property AnimatedFlickable scroller: panel.loadedContent ? Dynamic.value(panel.loadedContent, "scroller") as AnimatedFlickable : null
  readonly property Column scrollContent: panel.loadedContent ? Dynamic.value(panel.loadedContent, "scrollContent") as Column : null
  readonly property HeroTitle hero: panel.loadedContent ? Dynamic.value(panel.loadedContent, "hero") as HeroTitle : null
  readonly property Item stage: panel.loadedContent ? Dynamic.value(panel.loadedContent, "stage") as Item : null
  readonly property Column listWrap: panel.loadedContent ? Dynamic.value(panel.loadedContent, "listWrap") as Column : null
  readonly property Repeater cityRows: panel.loadedContent ? Dynamic.value(panel.loadedContent, "cityRows") as Repeater : null
  readonly property CitySearch citySearch: panel.loadedContent ? Dynamic.value(panel.loadedContent, "citySearch") as CitySearch : null
  readonly property CitySearch hereSearch: panel.loadedContent ? Dynamic.value(panel.loadedContent, "hereSearch") as CitySearch : null
  readonly property Loader globeLoader: panel.loadedContent ? Dynamic.value(panel.loadedContent, "globeLoader") as Loader : null


  // ---- settings
  // `cities` once written; until then the older `zones` string.
  readonly property var zones: Model.parseCities(setting("cities", null), setting("zones", ""))
  readonly property var zoneIds: zones.map(function(z: var): var { return Dynamic.value(z, "id") })
  // Never written: the first probe seeds the list around the local zone.
  readonly property bool needsSeed: Dynamic.value(zones, "length") === 0
  readonly property var probeIds: needsSeed ? zoneIds.concat(Model.seedCandidateZones()) : zoneIds

  readonly property var formatLocale: Qt.locale(Commons.I18n.formatLocale)
  readonly property bool autoHour24: Model.usesTwentyFourHour(formatLocale.timeFormat(Locale.ShortFormat))
  readonly property bool hour24: Model.resolveHour24(setting("hour24", ""), autoHour24)
  // "home" shows the distance from here ("+2h"), "utc" the zone itself ("UTC-5").
  readonly property string offsetMode: setting("offsetMode", "home") === "utc" ? "utc" : "home"
  // Only the US measurement system means Fahrenheit.
  readonly property string autoUnits: Dynamic.value(formatLocale, "measurementSystem") === Locale.ImperialUSSystem ? "F" : "C"
  readonly property string units: Model.resolveUnits(setting("units", ""), autoUnits)
  readonly property bool globeEnabled: setting("globeEnabled", true) !== false
  // Draw the globe with less in it while it moves.
  readonly property bool smoothMotion: setting("smoothMotion", true) !== false

  // The words the model's clocks and dates read in, from the shell's language.
  readonly property var words: {
    return {
      t: Commons.I18n.t,
      tn: Commons.I18n.tn,
      fmt: Commons.I18n.formatNumber,
      am: Dynamic.value(formatLocale, "amText"),
      pm: Dynamic.value(formatLocale, "pmText"),
      date: function(parts: var): string {
        return new Date(Dynamic.value(parts, "year"), Dynamic.value(parts, "month"), Dynamic.value(parts, "day"), 12)
          .toLocaleString(formatLocale, Commons.I18n.t("elsewhen.dateFormat"))
      }
    }
  }

  function toggleHour24(): void { persistSettings({ hour24: !hour24 }) }
  function toggleOffsetMode(): void { persistSettings({ offsetMode: offsetMode === "utc" ? "home" : "utc" }) }
  function toggleUnits(): void { persistSettings({ units: units === "C" ? "F" : "C" }) }

  function offsetTextFor(rowData: var): string {
    if (!rowData || !Dynamic.value(rowData, "ready")) return ""
    return offsetMode === "utc" ? Model.utcOffsetLabel(Dynamic.value(rowData, "offsetMinutes"), words) : Dynamic.value(rowData, "relative")
  }

  // ---- state
  property var probe: ({})
  property var searchProbe: ({})
  property string zoneCatalogText: ""
  property var facts: ({})
  // Geocoder answers are final for the session; fallbacks are retried.
  property var geo: ({})
  property var fallbackGeo: ({})
  property var weather: ({})
  // Cities jumped to on the globe; never persisted.
  property var sessionCities: []
  property int localOffsetMinutes: -(new Date().getTimezoneOffset())
  property string localZone: ""
  property double nowMs: Date.now()
  property bool probeQueued: false
  property bool searchProbeQueued: false
  property bool factsQueued: false

  readonly property bool adding: citySearch ? Dynamic.value(citySearch, "active") : false
  onAddingChanged: if (!adding && scroller) Dynamic.call(scroller, "scrollToTop")
  readonly property bool choosingHere: hereSearch ? Dynamic.value(hereSearch, "active") : false
  readonly property var zoneOptions: Model.zoneOptions(zoneCatalogText, zones)
  // The globe's jump box may go to a city that is already tracked.
  readonly property var allZoneOptions: Model.zoneOptions(zoneCatalogText, [])
  readonly property var searchZoneIds: {
    var out = []
    var matches = (citySearch ? Dynamic.value(citySearch, "matches") : []).concat(hereSearch ? Dynamic.value(hereSearch, "matches") : [])
    for (let i = 0; i < Dynamic.value(matches, "length"); i++) {
      let id = matches[i].value
      if (out.indexOf(id) < 0) out.push(id)
    }
    return out
  }
  onSearchZoneIdsChanged: probeSearchZones()

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  readonly property color foreground: bar ? BarValues.foreground(bar) : Commons.Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color fainter: Qt.darker(foreground, 2.1)
  // A literal gold: several themes' "yellow" is not yellow.
  readonly property color daylightMarker: "#E5C736"
  readonly property string fontFamily: bar ? BarValues.fontFamily(bar) : Style.font.family

  // ---- the zoom
  // One number drives the list-to-globe transition: 0 is the list, 1 the globe.
  property bool globeMode: false
  property real zoom: globeMode ? 1 : 0
  readonly property bool zoomIdle: zoom === 0 || zoom === 1
  readonly property real bigGlobeOpacity: Util.clamp(zoom / 0.12, 0, 1)
  readonly property real globeStageHeight: Style.space(378)
  // Far enough for the top row to fall past the whole list.
  readonly property real knockFall: (listWrap ? Dynamic.value(listWrap, "implicitHeight") : 0) + Style.space(220)

  // Shift-click the globe to run the transition at a third of the speed.
  readonly property int slowMotionFactor: 3
  // Set before globeMode flips, so the animation never reads a stale duration.
  property int zoomDuration: 800
  property int zoomEasing: Easing.OutQuart

  function setGlobeMode(on: bool, slow: var): void {
    if (on) {
      addSelected = false
      // Both live in the list, which the globe is about to knock away.
      if (hereSearch) Dynamic.call(hereSearch, "stop")
      peopleEditIndex = -1
    }
    zoomDuration = (on ? 800 : 500) * (slow === true ? slowMotionFactor : 1)
    zoomEasing = on ? Easing.OutQuart : Easing.InOutCubic
    globeMode = on
    if (on && globeLoader && Dynamic.value(globeLoader, "item")) showFocusOnGlobe()
  }

  // The globe opens on the list's focus, when its coordinates are known.
  function showFocusOnGlobe(): void {
    var g = globeLoader ? Dynamic.value(globeLoader, "item") as Globe : null
    if (!g) return
    if (focusIndex >= 0 && focusKnown) Dynamic.call(g, "goTo", [Dynamic.value(focusZone, "label"), Dynamic.value(focusZone, "id"), null])
    else Dynamic.call(g, "showHome")
  }

  // A tap on the globe: a city on this machine's zone becomes here, and the
  // zone's own city goes back to being the default.
  // The tapped city brings what is known of where it is - a tracked or jumped-to
  // town's own coordinates and region - so here is never geocoded by name again.
  function claimHome(label: var, zone: var): void {
    var stored = Model.homeCityAfterTap(label, zone, hereZone && Dynamic.value(hereZone, "chosen") ? Dynamic.value(hereZone, "label") : "", localZone)
    if (stored === null) return
    if (stored === "") { setHere({ label: Model.labelForZoneId(localZone), id: localZone }); return }
    var pick = { label: stored, id: zone }
    var known = zones.concat(sessionCities).filter(function(c: var): bool { return Dynamic.value(c, "label") === label && Dynamic.value(c, "id") === zone })[0]
    var place = known && Dynamic.value(known, "lat") !== undefined ? known : placeOf(pick)
    if (place) { pick.lat = Dynamic.value(place, "lat"); pick.lon = Dynamic.value(place, "lon") }
    if (known && Dynamic.value(known, "region")) pick.region = Dynamic.value(known, "region")
    setHere(pick)
  }

  // Here moves, and the row that stood for it follows, keeping its people. A
  // place on another zone moves the machine's clock first, and here only moves
  // once it has: a refused change leaves everything as it was.
  function setHere(pick: var): void {
    var next = Model.hereAfterPick(zones, hereZone, pick, localZone)
    if (!next) return
    if (Dynamic.value(next, "zoneChange") !== "") {
      if (timezoneProc.running) return
      // Only here waits on the clock; the list is whatever it is by then.
      timezoneProc.pending = { here: Dynamic.value(next, "here"), zoneChange: Dynamic.value(next, "zoneChange") }
      timezoneProc.command = Model.timezoneCommand(Dynamic.value(next, "zoneChange"))
      timezoneProc.running = true
      return
    }
    applyHere(next)
  }

  function applyHere(next: var): void {
    var values = { here: Dynamic.value(next, "here") === null ? undefined : Dynamic.value(next, "here"), homeCity: undefined }
    if (Dynamic.value(next, "zones") && Dynamic.value(next, "zones") !== zones) { values.cities = Model.serializeCities(Dynamic.value(next, "zones")); values.zones = undefined }
    persistSettings(values)
    refreshFacts()
  }

  function notify(title: var): void { Util.execArgv(["nomarchy-notification-send", title]) }

  function startChoosingHere(): void { if (hereSearch && localZone !== "" && !globeMode) Dynamic.call(hereSearch, "start") }

  function focusFromGlobe(label: var, zone: var): void {
    var i = Model.indexOfZone(zones, label, zone)
    if (i >= 0) focusOn(i)
  }

  // The little globe's center in stage coordinates, where the big one grows
  // from. The unused sum makes it recompute when the layout above moves.
  readonly property var heroCenter: {
    if (!hero || !stage) return null
    var _ = hero.icon.width + Dynamic.value(hero.icon, "height") + Dynamic.value(stage, "y") + stage.width
    var pt = Dynamic.call(hero.icon, "mapToItem", [stage, hero.icon.width / 2, Dynamic.value(hero.icon, "height") / 2])
    return (pt && Dynamic.value(pt, "x") !== undefined) ? pt : null
  }
  readonly property real heroCenterX: heroCenter ? Dynamic.value(heroCenter, "x") : (stage ? stage.width / 2 : 0)
  readonly property real heroCenterY: heroCenter ? Dynamic.value(heroCenter, "y") : 0
  readonly property real heroDiscRadius: hero ? Math.max(1, hero.icon.width / 2 - 1) : 1

  // ---- drag to reorder
  // Rows move by transform while dragging; the order is committed on drop.
  property int dragIndex: -1
  property real dragOffset: 0
  property real rowPitch: 0
  // Every row's pitch, measured at the grab: a row with people is a line taller.
  property var rowPitches: []
  property int dragTarget: -1

  function beginRowDrag(index: int, pitch: real): void {
    dropAnimation.stop()
    dragIndex = index
    dragTarget = index
    rowPitch = pitch
    var gap = pitch - (cityRows && Dynamic.call(cityRows, "itemAt", [index]) ? Dynamic.call(cityRows, "itemAt", [index]).height : 0)
    var pitches = []
    for (let i = 0; i < Dynamic.value(zones, "length"); i++) {
      let item = cityRows ? Dynamic.call(cityRows, "itemAt", [i]) : null
      pitches.push(item ? Dynamic.value(item, "height") + gap : pitch)
    }
    rowPitches = pitches
  }

  function moveRowDrag(offset: real): void {
    dragOffset = offset
    dragTarget = Model.dragTargetFor(dragIndex, dragOffset, rowPitch, dragTarget, Dynamic.value(zones, "length"), rowPitches)
  }

  // Glide into the slot, then commit.
  function releaseRowDrag(): void {
    if (dragIndex < 0) { cancelRowDrag(); return }
    dropAnimation.to = Model.dropOffset(dragIndex, dragTarget, rowPitch, rowPitches)
    dropAnimation.restart()
  }

  function commitRowDrag(): void {
    if (dragIndex >= 0 && dragTarget >= 0 && dragTarget !== dragIndex)
      persistSettings({ cities: Model.serializeCities(Model.moveZone(zones, dragIndex, dragTarget)), zones: undefined })
    cancelRowDrag()
  }

  function cancelRowDrag(): void {
    dropAnimation.stop()
    dragIndex = -1
    dragTarget = -1
    dragOffset = 0
  }

  // ---- scrubbing
  // Set absolutely from the pointer, held briefly after release, then back to now.
  property real scrubMinutes: 0
  readonly property double effectiveMs: nowMs + scrubMinutes * 60000
  readonly property string scrubLabel: Model.formatScrubDelta(scrubMinutes, words)

  // Measured against the unscrubbed present, so a drag cannot drift.
  function scrubTo(rowData: var, fraction: real): void {
    if (!rowData || !Dynamic.value(rowData, "ready")) return
    var parts = Model.zoneParts(nowMs, Dynamic.value(rowData, "offsetMinutes"))
    scrubMinutes = Model.scrubDeltaMinutes(fraction, parts.hour * 60 + parts.minute)
  }

  function beginScrub(rowData: var, fraction: real): void {
    scrubHold.stop()
    scrubTo(rowData, fraction)
  }

  function endScrub(): void { scrubHold.restart() }

  // Held until Escape or close: a key press has no release to time from. Unlike a
  // drag, which stays within the strip's day, the keys can run on into other days.
  function shiftHour(step: int): void {
    scrubHold.stop()
    scrubMinutes = Math.round(scrubMinutes) + step * 60
  }

  // ---- the moon
  // Shift-click a moon marker to walk the phase through a lunation.
  property bool moonShowing: false
  property real moonDemo: -1
  readonly property var moonShowStops: [0, 0.12, 0.25, 0.38, 0.5, 0.62, 0.75, 0.88, 1]
  property int moonShowStep: 0
  readonly property real moonPhase: moonShowing && moonDemo >= 0 ? moonDemo : Solar.moonPhase(effectiveMs)

  function startMoonShow(): void {
    moonShowStep = 0
    moonShowing = true
    moonDemo = moonShowStops[0]
    moonShowTimer.restart()
  }

  function stopMoonShow(): void {
    moonShowTimer.stop()
    // Before the value, so the tween does not run the phase back to -1.
    moonShowing = false
    moonDemo = -1
  }

  // ---- places
  readonly property var clockRows: Model.rows(zones, probe, effectiveMs, localOffsetMinutes, hour24, words)

  // The system zone names a representative city; a chosen `here` overrides it
  // while the machine stays on that zone, so a trip resets it on its own.
  readonly property var hereZone: Model.resolveHere(setting("here", null), setting("homeCity", ""), localZone)
  readonly property string homeCity: hereZone ? Dynamic.value(hereZone, "label") : ""
  readonly property var homeZone: hereZone || ({ label: "", id: localZone })

  function placeOf(zone: var): var {
    var f = facts[Model.factsKey(zone)]
    return (f && Dynamic.value(f, "lat") !== undefined && Dynamic.value(f, "lon") !== undefined) ? f : null
  }

  readonly property var homePlace: homeCity === "" || localZone === "" ? null : placeOf(homeZone)

  // Matched by name: Miami should not light up New York.
  readonly property var trackedNames: zones.map(function(z: var): string { return String(Dynamic.value(z, "label")).toLowerCase() })

  function globeRows(list: var, rank: int): var {
    var out = []
    for (let i = 0; i < Dynamic.value(list, "length"); i++) {
      let f = placeOf(list[i])
      if (f) out.push([list[i].label, list[i].id, Dynamic.value(f, "lat"), Dynamic.value(f, "lon"), rank])
    }
    return out
  }
  readonly property var trackedCities: globeRows(zones, 0)
  readonly property var sessionPlaces: globeRows(sessionCities, 1)

  // Held as the city's key, not a row index, so a reorder carries the focus
  // with the city and a removal drops it back to home.
  property string focusKey: ""
  readonly property int focusIndex: Model.indexOfZoneKey(zones, focusKey)
  readonly property var focusZone: focusIndex >= 0 ? zones[focusIndex] : homeZone
  readonly property var focusPlace: placeOf(focusZone)
  readonly property bool focusKnown: focusPlace !== null
  readonly property real focusLat: focusKnown ? Dynamic.value(focusPlace, "lat") : 0
  readonly property real focusLon: focusKnown ? Dynamic.value(focusPlace, "lon") : 0

  function focusOn(index: int): void {
    addSelected = false
    var from = hero ? Dynamic.value(hero, "spin") : 0
    focusKey = index >= 0 && index < Dynamic.value(zones, "length") ? Model.factsKey(zones[index]) : ""
    if (focusKnown && hero) Dynamic.call(hero, "turn", [from, focusLon])
  }

  // Past the last city, the list's cursor rests on "Add a city"; the globe stays put.
  property bool addSelected: false

  // Up and down walk home, each city and then "Add a city", wrapping round like the
  // search list. The globe has no add row, so there the walk skips it.
  function moveFocus(step: int): void {
    var at = addSelected ? Dynamic.value(zones, "length") : focusIndex
    var next = Model.moveSelection(at + 1, step, Dynamic.value(zones, "length") + (globeMode ? 1 : 2)) - 1
    if (next === Dynamic.value(zones, "length")) {
      addSelected = true
      scrollToItem(citySearch)
      return
    }
    focusOn(next)
    if (globeMode) showFocusOnGlobe()
    else scrollToItem(next >= 0 && cityRows ? Dynamic.call(cityRows, "itemAt", [next]) : null)
  }

  // The picked city goes, as with its × button, and the cursor lands on the city
  // that takes its place. The last city stays, so there is always one clock.
  function deleteFocused(): void {
    if (globeMode || addSelected || focusIndex < 0 || Dynamic.value(zones, "length") < 2) return
    var at = focusIndex
    removeCityAt(at)
    focusOn(Math.min(at, Dynamic.value(zones, "length") - 1))
  }

  function scrollToItem(item: Item): void {
    if (!scroller) return
    if (!item) { Dynamic.call(scroller, "scrollToTop"); return }
    var top = Dynamic.value(Dynamic.call(item, "mapToItem", [scrollContent, 0, 0]), "y")
    if (top < Dynamic.value(scroller, "contentY")) Dynamic.call(scroller, "scrollTo", [top])
    else if (top + Dynamic.value(item, "height") > Dynamic.value(scroller, "contentY") + Dynamic.value(scroller, "height"))
      Dynamic.call(scroller, "scrollTo", [Math.min(Dynamic.value(scroller, "maxScroll"), top + Dynamic.value(item, "height") - Dynamic.value(scroller, "height"))])
  }

  // Surrogate pairs rather than literal glyphs, which re-encoding can break.
  function weatherGlyph(zone: var): string {
    var f = facts[Model.factsKey(zone)]
    if (!f || f.w === undefined) return ""
    var kind = Model.weatherKind(f.w)
    if (kind === "sunny") return "\udb81\udda8"  // white-balance-sunny: a solid disc
    if (kind === "partly") return "\udb81\udd95"
    if (kind === "cloudy") return "\udb81\udd90"
    if (kind === "rain") return "\udb81\udd97"
    if (kind === "snow") return "\udb81\udd98"
    return ""
  }

  readonly property string localTime: {
    var here = Model.localParts(effectiveMs)
    var text = Model.formatTime(here, hour24, words)
    return hour24 ? text : text + " " + Model.meridiem(here, words)
  }

  // No full stop: a period hanging off the arc reads as a speck.
  readonly property string hereLine: (homeCity !== ""
      ? Commons.I18n.t("elsewhen.hereIn").arg(localTime).arg(homeCity)
      : Commons.I18n.t("elsewhen.here").arg(localTime))
    + (scrubLabel !== "" ? "  " + scrubLabel : "")

  // A capital's line box has empty space above it; the row's top pad drops by it.
  FontMetrics {
    id: nameFontMetrics
    font.family: root.fontFamily
    font.pixelSize: Style.font.subtitle
  }

  TextMetrics {
    id: nameCapMetrics
    font.family: root.fontFamily
    font.pixelSize: Style.font.subtitle
    text: "M"
  }

  readonly property real capGap: Math.max(0,
    Dynamic.value(nameFontMetrics, "height") - nameFontMetrics.descent + Dynamic.value(nameCapMetrics.tightBoundingRect, "y"))

  // The widest a row's time gets, so every row's weather lines up against one
  // column rather than hugging "4:06" in one row and "10:06" in the next.
  TextMetrics {
    id: widestTimeMetrics
    font.family: root.fontFamily
    font.pixelSize: Style.font.heading
    font.weight: Font.DemiBold
    // In the language's digits, which are not all as wide as ASCII ones.
    text: Model.formatTime({ hour: 0, minute: 0 }, true, root.words)
  }

  TextMetrics {
    id: meridiemMetrics
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    text: Dynamic.value(Dynamic.value(root.formatLocale, "pmText"), "length") > Dynamic.value(root.formatLocale, "amText").length
      ? Dynamic.value(root.formatLocale, "pmText") : Dynamic.value(root.formatLocale, "amText")
  }

  readonly property real timeColumnWidth: Math.ceil(widestTimeMetrics.advanceWidth
    + (hour24 ? 0 : Style.spacing.xs + meridiemMetrics.advanceWidth))

  function tick(): void {
    nowMs = Date.now()
    localOffsetMinutes = -(new Date().getTimezoneOffset())
  }

  // Written straight back to this widget's shell.json entry, like the clock's.
  // An undefined value removes its key.
  function persistSettings(values: var): void {
    var entry = { id: root.moduleName }
    for (let existing in root.settings) if (existing !== "id") entry[existing] = root.settings[existing]
    for (let key in values) {
      if (values[key] === undefined) Model.removeProperty(entry, key)
      else entry[key] = values[key]
    }

    root.settings = entry
    if (BarValues.hasUpdateEntryInline(root.bar))
      BarValues.updateEntryInline(root.bar, root.moduleName, entry)
  }

  function setZones(next: var): void {
    if (next === zones) return
    persistSettings({ cities: Model.serializeCities(next), zones: undefined })
    refresh()
    refreshFacts()
    fetchProfiles()
  }

  // The label matters as much as the zone: many cities share one. A place from
  // the geocoder brings its coordinates, so the row never has to look itself up.
  function addCity(id: string, label: string, place: var): void { setZones(Model.addZone(zones, id, label || "", place)) }
  function removeCity(id: string): void { setZones(Model.removeZone(zones, id)) }
  function removeCityAt(index: int): void { setZones(Model.removeZoneAt(zones, index)) }

  function startAdding(): void { if (citySearch) Dynamic.call(citySearch, "start") }

  function addSessionCity(label: string, id: string, place: var): void {
    for (let i = 0; i < Dynamic.value(sessionCities, "length"); i++)
      if (sessionCities[i].label === label && sessionCities[i].id === id) return
    var city = Model.addZone([], id, label, place)[0]
    if (!city) return
    sessionCities = sessionCities.concat([city])
    refreshFacts()
  }

  // The local city plus four places spread round the clock from it. Home is
  // here, so a city already chosen is the one the list starts with.
  function seedFirstRun(): void {
    var offs = ({})
    for (let id in probe) offs[id] = probe[id].offsetMinutes

    var seeded = localZone === "" || !hereZone ? []
      : Model.seedZones({ label: Dynamic.value(hereZone, "label"), id: localZone }, offs, 4)
    if (Dynamic.value(seeded, "length") > 0 && Dynamic.value(hereZone, "lat") !== undefined) seeded[0] = Object.assign({}, seeded[0], hereZone)
    if (Dynamic.value(seeded, "length") === 0) seeded = Model.parseZones(Model.DEFAULT_ZONES)
    if (Dynamic.value(seeded, "length") === 0) return

    persistSettings({ cities: Model.serializeCities(seeded), zones: undefined })
    refresh()
    refreshFacts()
  }

  // ---- people
  // GitHub profiles by handle, each fetched once a session and cached on disk for a week.
  property var profiles: ({})
  readonly property var pendingProfiles: Model.pendingProfiles(zones, profilesTried)
  property var profilesTried: ({})
  property double profileStamp: 0
  property bool profilesQueued: false
  property int peopleEditIndex: -1

  function fetchProfiles(): void {
    if (Dynamic.value(pendingProfiles, "length") === 0) return
    if (peopleProc.running) { profilesQueued = true; return }
    profilesTried = Model.markProfilesTried(profilesTried, pendingProfiles)
    peopleProc.command = Model.profilesCommand(pendingProfiles)
    peopleProc.running = true
  }

  function startPeopleEdit(index: int): void {
    if (citySearch) Dynamic.call(citySearch, "stop")
    if (hereSearch) Dynamic.call(hereSearch, "stop")
    peopleEditIndex = index
  }

  function finishPeopleEdit(index: int, text: var): void {
    peopleEditIndex = -1
    setZones(Model.setPeopleAt(zones, index, Model.parsePeople(text)))
    takeKeyboardBack()
  }

  function cancelPeopleEdit(): void {
    peopleEditIndex = -1
    takeKeyboardBack()
  }

  // A hidden field keeps its focus, so the panel asks for the keyboard back.
  function takeKeyboardBack(): void {
    Qt.callLater(function() { if (panel.loadedContent) Dynamic.call(panel.loadedContent, "forceActiveFocus") })
  }

  // ---- place search
  // The geocoder's places for each query, kept for the session. A query is
  // looked up once the typing pauses, one request at a time, latest wins.
  property var placeCache: ({})
  property string placeWanted: ""

  function requestPlaces(text: string): void {
    var q = Model.placeQuery(text)
    if (q === "" || placeCache[q] !== undefined) return
    placeWanted = q
    placeDebounce.restart()
  }

  function lookupPlaces(): void {
    var q = placeWanted
    if (q === "" || placeCache[q] !== undefined) return
    if (placeProc.running) return
    placeProc.query = q
    placeProc.command = ["curl", "-fsS", "--max-time", "8", Model.geocodeUrl(q)]
    placeProc.running = true
  }

  function placesFor(text: string): var {
    var q = Model.placeQuery(text)
    return q === "" ? [] : (placeCache[q] || [])
  }

  function placesPending(text: string): bool {
    var q = Model.placeQuery(text)
    return q !== "" && placeCache[q] === undefined
  }

  // ---- processes
  // Each refresh queues behind one in flight rather than being dropped.
  function refresh(): void {
    if (Dynamic.value(probeIds, "length") === 0) return
    if (probeProc.running) { probeQueued = true; return }
    probeProc.running = true
  }

  // The command is set here rather than bound: this runs from the ids' own
  // change handler, which can fire before a binding on them has caught up.
  function probeSearchZones(): void {
    if (Dynamic.value(searchZoneIds, "length") === 0) return
    if (searchProc.running) { searchProbeQueued = true; return }
    searchProc.command = Model.probeCommand(searchZoneIds, false)
    searchProc.running = true
  }

  function refreshFacts(): void {
    if (Dynamic.value(zones, "length") === 0) return
    if (geoProc.running || weatherProc.running) { factsQueued = true; return }
    var missing = factsRequest.filter(function(row: var): bool {
      var key = Model.factsKey(row)
      return !geo[key] && !pinnedGeo[key]
    })
    if (Dynamic.value(missing, "length") === 0) { fetchWeather(); return }
    geoProc.rows = missing
    geoProc.command = ["C:/Program Files/Git/usr/bin/bash.exe", "-c", 'for url; do curl -fsS --max-time 8 "$url"; printf "\\n\\036\\n"; done', "C:/Program Files/Git/usr/bin/bash.exe"]
      .concat(missing.map(function(row: var): string { return Model.geocodeUrl(Dynamic.value(row, "label")) }))
    geoProc.running = true
  }

  function coordsFor(key: string): var {
    return pinnedGeo[key] || geo[key] || fallbackGeo[key] || null
  }

  function fetchWeather(): void {
    // A reading for somewhere else is stale too: a city's coordinates can move under its name.
    weatherProc.keys = Model.staleWeatherKeys(factsRequest, weather, Date.now(), function(key: string): var { return root.coordsFor(key) })
    if (Dynamic.value(weatherProc, "keys").length === 0) { publishFacts(); return }
    weatherProc.points = Model.coordinatesForKeys(Dynamic.value(weatherProc, "keys"), function(key: string): var { return root.coordsFor(key) })
    weatherProc.command = ["curl", "-fsS", "--max-time", "8", Model.forecastUrl(Dynamic.value(weatherProc, "points"))]
    weatherProc.running = true
  }

  function publishFacts(): void {
    var keys = Model.factsKeys(factsRequest)
    facts = Model.mergeFacts(keys, Model.coordinatesForKeys(keys, function(key: string): var { return root.coordsFor(key) }), weather)
    if (!factsQueued) return
    factsQueued = false
    Qt.callLater(refreshFacts)
  }

  function loadCatalog(): void {
    if (zoneCatalogText !== "" || catalogProc.running) return
    catalogProc.running = true
  }

  function utcLabelFor(zoneId: string): string {
    var known = searchProbe[zoneId]
    return known === undefined ? "" : Model.utcOffsetLabel(Dynamic.value(known, "offsetMinutes"), words)
  }

  // Tracked cities, the city you are in (for the globe's home) and session cities.
  readonly property var factsRequest: {
    var out = zones.slice()
    if (hereZone) out.push(hereZone)
    return out.concat(sessionCities)
  }

  // Coordinates a city came with, from a place search: never geocoded by name.
  readonly property var pinnedGeo: Model.pinnedGeography(factsRequest)

  // ---- opening spin
  // It lands on the home meridian, so it waits for home's coordinates, read
  // straight from the facts: focusKnown can flip a beat before focusLon lands.
  property bool spinPending: false

  function homeMeridian(): var {
    var f = facts[Model.factsKey(focusZone)]
    return (f && Dynamic.value(f, "lon") !== undefined && Dynamic.value(f, "lon") !== null) ? Dynamic.value(f, "lon") : null
  }

  function startOpeningSpin(): void {
    var lon = homeMeridian()
    if (lon === null) { spinPending = true; spinFallback.restart(); return }
    spinPending = false
    spinFallback.stop()
    if (hero) Dynamic.call(hero, "spinOpening", [lon])
  }

  onFactsChanged: if (spinPending) startOpeningSpin()

  // No coordinates on a cold cache without network: spin anyway.
  Timer {
    id: spinFallback
    interval: 1500
    onTriggered: if (root.spinPending) { root.spinPending = false; if (root.hero) Dynamic.call(root.hero, "spinOpening", [null]) }
  }

  onOpenedChanged: {
    if (opened) {
      // The opening spin below drives the hero, so build the content first.
      panel.ensureContent()
      focusKey = ""
      addSelected = false
      tick(); refresh(); refreshFacts(); loadCatalog(); fetchProfiles()
      startOpeningSpin()
    } else {
      if (citySearch) Dynamic.call(citySearch, "stop")
      if (hereSearch) Dynamic.call(hereSearch, "stop")
      peopleEditIndex = -1
      setGlobeMode(false, false); scrubMinutes = 0
      spinPending = false; spinFallback.stop()
    }
  }
  Component.onCompleted: refresh()

  Process {
    id: probeProc
    command: Model.probeCommand(root.probeIds, true)
    stdout: StdioCollector {
      onStreamFinished: {
        root.probe = Model.parseProbe(text)
        var lz = Model.localZoneFromProbe(text)
        if (lz !== "") root.localZone = lz
        if (root.needsSeed) root.seedFirstRun()
        root.tick()
        Qt.callLater(function() {
          if (!root.probeQueued) return
          root.probeQueued = false
          root.refresh()
        })
      }
    }
  }

  // Merged, so a known offset stays on screen while the next probe runs.
  Process {
    id: searchProc
    stdout: StdioCollector {
      onStreamFinished: {
        var merged = {}
        for (let known in root.searchProbe) merged[known] = root.searchProbe[known]
        var fresh = Model.parseProbe(text)
        for (let id in fresh) merged[id] = fresh[id]
        root.searchProbe = merged
        Qt.callLater(function() {
          if (!root.searchProbeQueued) return
          root.searchProbeQueued = false
          root.probeSearchZones()
        })
      }
    }
  }

  Process {
    id: catalogProc
    command: ["timedatectl", "list-timezones"]
    stdout: StdioCollector {
      onStreamFinished: root.zoneCatalogText = text
    }
  }

  FileView {
    id: zoneTab
    path: "/usr/share/zoneinfo/zone1970.tab"
    printErrors: false
  }

  Process {
    id: geoProc
    property var rows: []
    stdout: StdioCollector {
      onStreamFinished: Model.mergeGeocodeResponses(root, Dynamic.value(geoProc, "rows"), text, zoneTab.text())
    }
  }

  // Moving the clock for a new here. The zone is the machine's as soon as the
  // command succeeds; the probe confirms it, and its offset, a moment later.
  Process {
    id: timezoneProc
    property var pending: null
    onExited: function(exitCode) {
      var next = pending
      pending = null
      if (!next) return
      if (exitCode !== 0) {
        root.notify(Commons.I18n.t("elsewhen.timezoneFailed").arg(Dynamic.value(next, "zoneChange")))
        return
      }
      root.localZone = Dynamic.value(next, "zoneChange")
      root.applyHere(next)
      root.tick()
      root.refresh()
      root.notify(Commons.I18n.t("elsewhen.timezoneChanged").arg(root.homeCity).arg(Dynamic.value(next, "zoneChange")))
    }
  }

  Timer {
    id: placeDebounce
    interval: 300
    onTriggered: root.lookupPlaces()
  }

  // A failed lookup is remembered as no places, so the list stops saying it is
  // searching. The next query is tried on the answer and again on the exit: the
  // output can finish while the process still reads as running, and a query
  // turned away then would never be asked.
  Process {
    id: placeProc
    property string query: ""
    onRunningChanged: if (!running) Qt.callLater(root.lookupPlaces)
    stdout: StdioCollector {
      onStreamFinished: {
        var next = Object.assign({}, root.placeCache)
        next[placeProc.query] = Model.placeOptions(text)
        root.placeCache = next
        Qt.callLater(root.lookupPlaces)
      }
    }
  }

  // Handles added mid-fetch are queued, and drained once it has exited rather
  // than when its output ends, which can be while it still reads as running.
  Process {
    id: peopleProc
    onRunningChanged: if (!running) Qt.callLater(function() {
      if (!root.profilesQueued) return
      root.profilesQueued = false
      root.fetchProfiles()
    })
    stdout: StdioCollector {
      onStreamFinished: {
        root.profiles = Object.assign({}, root.profiles, Model.parseProfiles(text))
        root.profileStamp = Date.now()
      }
    }
  }

  Process {
    id: weatherProc
    property var keys: []
    property var points: []
    stdout: StdioCollector {
      onStreamFinished: {
        root.weather = Object.assign({}, Dynamic.value(root, "weather"), Model.parseForecast(text, weatherProc.keys, Date.now(), weatherProc.points))
        root.publishFacts()
      }
    }
  }

  Timer {
    interval: 900000
    running: root.opened
    repeat: true
    onTriggered: root.refreshFacts()
  }

  // Heavy on the way out, brisk on the way back.
  Behavior on zoom {
    NumberAnimation {
      duration: Style.duration(root.zoomDuration)
      easing.type: root.zoomEasing
    }
  }

  Timer {
    id: moonShowTimer
    interval: 620
    repeat: true
    onTriggered: {
      root.moonShowStep++
      if (root.moonShowStep >= Dynamic.value(root.moonShowStops, "length")) root.stopMoonShow()
      else root.moonDemo = root.moonShowStops[root.moonShowStep]
    }
  }

  Behavior on moonDemo {
    enabled: root.moonShowing
    NumberAnimation { duration: Style.duration(460); easing.type: Easing.InOutSine }
  }

  NumberAnimation {
    id: dropAnimation
    target: root
    property: "dragOffset"
    duration: Style.duration(150)
    easing.type: Easing.OutCubic
    onFinished: root.commitRowDrag()
  }

  Timer {
    id: scrubHold
    interval: 2500
    onTriggered: root.scrubMinutes = 0
  }

  Timer {
    interval: 1000
    running: root.opened
    repeat: true
    onTriggered: root.tick()
  }

  Timer {
    interval: 300000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  Commons.ShellIpc {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { root.refresh(); return "ok" }

    function globe(): string {
      if (!root.globeEnabled) return "disabled"
      root.setGlobeMode(!root.globeMode, false)
      return root.globeMode ? "globe" : "list"
    }

    // Ticks first: the clock only runs while the panel is open.
    function times(): string {
      root.tick()
      return JSON.stringify(root.clockRows)
    }
    function add(zone: string, label: string): string {
      root.setZones(Model.addZone(Dynamic.value(root, "zones"), zone, label))
      return Model.serializeZones(Dynamic.value(root, "zones"))
    }
    function remove(zone: string): string { root.removeCity(zone); return Model.serializeZones(Dynamic.value(root, "zones")) }

    // The people in a city, by its name: "Emir, @sarahdev"; "" clears them.
    function who(city: string, people: string): string {
      var name = String(city).trim().toLowerCase()
      for (let i = 0; i < Dynamic.value(root, "zones").length; i++) {
        if (Dynamic.value(root, "zones")[i].label.toLowerCase() !== name) continue
        root.setZones(Model.setPeopleAt(Dynamic.value(root, "zones"), i, Model.parsePeople(people)))
        return JSON.stringify(Dynamic.value(root, "zones")[i].people || [])
      }
      return "no city named " + city
    }

    // Where this machine is, on its own zone: "Fort Lauderdale".
    function here(city: string): string {
      if (root.localZone === "") return "zone not known yet"
      root.setHere({ label: city, id: root.localZone })
      return root.homeCity
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    text: "󰇧"
    tooltipText: Commons.I18n.t("elsewhen.worldClock")
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton || buttonCode === Qt.MiddleButton) root.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Style.space(680))

    panelContent: LazyContent {}

    component LazyContent: PanelKeyCatcher {
      id: keyCatcher
      final property alias scroller: scroller
      final property alias scrollContent: scrollContentItem
      final property alias hero: hero
      final property alias stage: stage
      final property alias listWrap: listWrap
      final property alias cityRows: cityRows
      final property alias citySearch: citySearch
      final property alias hereSearch: hereSearch
      final property alias globeLoader: globeLoaderItem
      implicitHeight: scrollContentItem.implicitHeight
      anchors.fill: parent
      blocked: root.adding || root.choosingHere || root.peopleEditIndex >= 0
      // Escape unwinds one layer: search (its own field), a shifted time, globe, then panel.
      onCloseRequested: {
        if (root.scrubMinutes !== 0) { scrubHold.stop(); root.scrubMinutes = 0 }
        else if (root.globeMode) root.setGlobeMode(false, false)
        else root.close()
      }
      onDeleteRequested: root.deleteFocused()
      // Up and down pick a city; left and right move the clocks an hour.
      onMoveRequested: function(dx, dy) {
        if (dy !== 0) root.moveFocus(dy)
        else root.shiftHour(dx)
      }
      // Return or Space on "Add a city" opens the search. Otherwise Space toggles
      // the globe, and Return, which also arrives as an activate, does nothing.
      property bool returnHandled: false
      onReturnRequested: returnHandled = true
      onActivateRequested: {
        var fromReturn = returnHandled
        returnHandled = false
        if (root.addSelected) root.startAdding()
        else if (!fromReturn && root.globeEnabled) root.setGlobeMode(!root.globeMode, false)
      }
      onTabRequested: function(direction) { root.switchPanel(direction) }
      // "+" searches in either view; "j" jumps on the globe, "a" adds on the list.
      // "t" flips 24-hour and AM/PM time, like clicking a row's time, and Alt+T
      // flips Fahrenheit and Celsius, like clicking a temperature. On the list,
      // "w" asks where you are, like clicking the header, and "p" edits who is
      // in the picked city, like its person button.
      onTextKey: function(text, modifiers) {
        var key = text.toLowerCase()
        if (key === "r") root.refresh()
        else if (key === "t" && (modifiers & Qt.AltModifier)) root.toggleUnits()
        else if (key === "t") root.toggleHour24()
        else if (root.globeMode && (key === "+" || key === "j")) {
          if (Dynamic.value(globeLoaderItem, "globe")) Dynamic.call(Dynamic.value(globeLoaderItem, "globe"), "startJump")
        } else if (!root.globeMode && (key === "+" || key === "a")) {
          root.startAdding()
        } else if (!root.globeMode && key === "w") {
          root.startChoosingHere()
        } else if (!root.globeMode && key === "p" && root.focusIndex >= 0) {
          root.startPeopleEdit(root.focusIndex)
        }
      }

      // Clipped to the card and scrolled by the wheel only: the rows own drags.
      AnimatedFlickable {
        id: scroller
        anchors.fill: parent
        anchors.rightMargin: -Style.space(12)
        clip: true
        interactive: false
        contentWidth: width
        contentHeight: scrollContentItem.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        // Follows maxScroll: the results arrive over several frames after the
        // search opens, so a one-shot scroll lands short.
        onMaxScrollChanged: if (root.adding) scrollTo(maxScroll)

        WheelHandler {
          acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
          onWheel: function(event) {
            var d = Dynamic.value(event.pixelDelta, "y") !== 0 ? Dynamic.value(event.pixelDelta, "y") : Dynamic.value(event.angleDelta, "y") / 120 * Style.space(40)
            Dynamic.set(scroller, "contentY", Dynamic.value(scroller, "contentY") - d)
            scroller.clamp()
          }
        }

        Column {
          id: scrollContentItem
          width: scroller.width - Style.space(12)
          spacing: Style.spacing.panelGap

          HeroTitle {
            id: hero
            width: parent.width
            caption: root.hereLine
            // Accent while scrubbed, so a shifted time is never taken for now.
            captionColor: root.scrubMinutes !== 0 ? Commons.Color.accent : root.dim
            // Away from home it brings the globe back; at home it asks where here is.
            captionClickable: root.focusIndex >= 0 || (root.localZone !== "" && !root.globeMode)
            foreground: root.foreground
            dim: root.dim
            fontFamily: root.fontFamily
            zoom: root.zoom
            globeEnabled: root.globeEnabled
            bigGlobeOpacity: root.bigGlobeOpacity
            restLon: root.focusLon
            markerShown: root.focusKnown
            markerLat: root.focusLat
            markerLon: root.focusLon
            onCaptionClicked: {
              if (root.focusIndex >= 0) root.focusOn(-1)
              else if (root.choosingHere) Dynamic.call(hereSearch, "stop")
              else root.startChoosingHere()
            }
            onGlobeClicked: function(slow) { root.setGlobeMode(!root.globeMode, slow) }
          }

          // "Where are you?": any place; one on another zone moves the clock
          // there too. Opened by the header rather than a button of its own.
          CitySearch {
            id: hereSearch
            visible: active && root.zoom < 1
            width: parent.width
            showButton: false
            options: root.allZoneOptions
            placesFor: function(text: string): var { return root.placesFor(text) }
            placesPending: function(text: string): bool { return root.placesPending(text) }
            loading: root.zoneCatalogText === ""
            placeholderText: Commons.I18n.t("elsewhen.whereAreYou")
            offsetLabel: function(zoneId: string): string { return root.utcLabelFor(zoneId) }
            foreground: root.foreground
            dim: root.dim
            fainter: root.fainter
            fontFamily: root.fontFamily
            onActiveChanged: if (active) { root.loadCatalog(); if (Dynamic.value(citySearch, "active")) Dynamic.call(citySearch, "stop") }
            onQueryChanged: if (active) root.requestPlaces(query)
            onPicked: function(label, id, place) {
              var pick = { label: label, id: id }
              root.setHere(place ? Object.assign(pick, place) : pick)
            }
            onDismissed: root.takeKeyboardBack()
          }

          // ---- stage
          // The list and the globe share it; it grows with the zoom. Not
          // clipped, so the globe can start from the header above it.
          Item {
            id: stage
            width: parent.width
            height: Math.max(1, Dynamic.value(listWrap, "implicitHeight")
                    + (root.globeStageHeight - Dynamic.value(listWrap, "implicitHeight")) * root.zoom)

            // Clipped, so knocked rows fall out of the panel.
            Item {
              anchors.fill: parent
              // Let circular actions straddle the rows' top-right corners.
              anchors.topMargin: -Style.space(12)
              anchors.rightMargin: -Style.space(12)
              clip: true

              Column {
                id: listWrap
                y: Style.space(12)
                width: stage.width
                spacing: Style.spacing.panelGap

                Column {
                  visible: root.zoom < 1
                  width: parent.width
                  spacing: Style.spacing.md

                  // The zone list, not clockRows: that ticks, and would
                  // rebuild every delegate mid-drag.
                  Repeater {
                    id: cityRows
                    model: Dynamic.value(root, "zones")

                    CityRow { panel: root }
                  }
                }

                CitySearch {
                  id: citySearch
                  visible: root.zoom < 1
                  width: parent.width
                  options: root.zoneOptions
                  existing: Dynamic.value(root, "zones")
                  placesFor: function(text: string): var { return root.placesFor(text) }
                  placesPending: function(text: string): bool { return root.placesPending(text) }
                  loading: root.zoneCatalogText === ""
                  offsetLabel: function(zoneId: string): string { return root.utcLabelFor(zoneId) }
                  hasCursor: root.addSelected
                  foreground: root.foreground
                  dim: root.dim
                  fainter: root.fainter
                  fontFamily: root.fontFamily
                  onActiveChanged: if (active) { root.loadCatalog(); if (Dynamic.value(hereSearch, "active")) Dynamic.call(hereSearch, "stop") }
                  onQueryChanged: if (active) root.requestPlaces(query)
                  onPicked: function(label, id, place) { root.addCity(id, label, place) }
                  onDismissed: root.takeKeyboardBack()

                  // Knocked aside last, after every row.
                  transform: Translate {
                    x: Model.knockX(Dynamic.value(root, "zones").length, root.zoom, Style.space(95))
                    y: Model.knockY(Dynamic.value(root, "zones").length, root.zoom, root.knockFall)
                  }
                }
              }
            }

            // ---- globe
            // Loaded early on hover and kept for the whole flight, so reading
            // its data never lands mid-animation.
            Loader {
              id: globeLoaderItem
              active: root.globeEnabled && (root.globeMode || root.zoom > 0 || hero.iconHovered)
              visible: root.zoom > 0
              opacity: root.bigGlobeOpacity
              width: parent.width
              height: root.globeStageHeight
              source: "Globe.qml"
              readonly property Globe globe: item as Globe

              // The disc's center, above the globe's footer and jump bar.
              readonly property real discCX: width / 2
              readonly property real discCY: globe ? (height - Dynamic.value(globe, "footerHeight") - Dynamic.value(globe, "jumpHeight")) / 2 : height / 2
              readonly property real discR: globe && Dynamic.value(globe, "radius") > 0 ? Dynamic.value(globe, "radius") : 1
              readonly property real startScale: root.heroDiscRadius / discR
              readonly property real zoomScale: startScale + (1 - startScale) * root.zoom

              // Scaled about the disc, then carried from the little globe.
              transform: [
                Scale {
                  origin.x: globeLoaderItem.discCX
                  origin.y: globeLoaderItem.discCY
                  xScale: globeLoaderItem.zoomScale
                  yScale: globeLoaderItem.zoomScale
                },
                Translate {
                  x: (root.heroCenterX - globeLoaderItem.discCX) * (1 - root.zoom)
                  y: (root.heroCenterY - globeLoaderItem.discCY) * (1 - root.zoom)
                }
              ]

              onLoaded: {
                globe.foreground = Qt.binding(function(): color { return root.foreground })
                globe.dim = Qt.binding(function(): color { return root.dim })
                globe.fainter = Qt.binding(function(): color { return root.fainter })
                globe.daylightMarker = Qt.binding(function(): color { return root.daylightMarker })
                globe.moonPhase = Qt.binding(function(): real { return root.moonPhase })
                globe.fontFamily = Qt.binding(function(): string { return root.fontFamily })
                globe.hour24 = Qt.binding(function(): bool { return root.hour24 })
                globe.words = Qt.binding(function(): var { return root.words })
                globe.trackedNames = Qt.binding(function(): var { return root.trackedNames })
                globe.trackedCities = Qt.binding(function(): var { return root.trackedCities })
                globe.sessionCities = Qt.binding(function(): var { return root.sessionPlaces })
                globe.homeRow = Qt.binding(function(): var {
                  var home = root.homePlace
                  return home ? [root.homeCity, root.localZone, Dynamic.value(home, "lat"), Dynamic.value(home, "lon"), 0] : []
                })
                globe.offsetMode = Qt.binding(function(): string { return Dynamic.value(root, "offsetMode") })
                globe.homeOffsetMinutes = Qt.binding(function(): int { return root.localOffsetMinutes })
                globe.smoothMotion = Qt.binding(function(): bool { return root.smoothMotion })
                globe.transitioning = Qt.binding(function(): bool { return !root.zoomIdle })
                globe.zoomLevel = Qt.binding(function(): real { return root.zoom })
                // The footer and jump bar arrive once the globe has landed.
                globe.chromeOpacity = Qt.binding(function(): real { return Util.clamp((root.zoom - 0.74) / 0.26, 0, 1) })
                globe.jumpOptions = Qt.binding(function(): var { return root.allZoneOptions })
                globe.placesFor = function(text: string): var { return root.placesFor(text) }
                globe.placesPending = function(text: string): bool { return root.placesPending(text) }
                globe.placeSearchRequested.connect(function(text: string): void { root.requestPlaces(text) })
                globe.offsetModeToggleRequested.connect(function(): void { root.toggleOffsetMode() })
                globe.jumpRequested.connect(function(label: string, zone: string, place: var): void { root.addSessionCity(label, zone, place) })
                globe.exitRequested.connect(function(): void { root.setGlobeMode(false, false) })
                globe.jumpDismissed.connect(function(): void { Qt.callLater(function(): void { if (panel.loadedContent) Dynamic.call(panel.loadedContent, "forceActiveFocus") }) })
                globe.citySelected.connect(function(label: string, zone: string): void { root.focusFromGlobe(label, zone) })
                globe.cityTapped.connect(function(label: string, zone: string): void { root.claimHome(label, zone) })
                // A cold start can finish loading after the mode switched on.
                if (root.globeMode) root.showFocusOnGlobe()
              }
            }
          }
        }
      }
    }
  }
}
