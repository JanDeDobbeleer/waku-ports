pragma Singleton
import Quickshell
import QtQuick
import "UtilData.js" as UtilData

// Shared utility helpers used across plugins. Pure functions only — no
// state. Anything stateful belongs on Color, Style, or a service.
QtObject {
  id: root

  // Manual click forwarding must honor the same clipping as Qt's hit test.
  // Collapsed drawers keep their children laid out beyond the visible edge.
  function itemContainsPoint(target: Item, source: Item, x: real, y: real): bool {
    return UtilData.itemContainsPoint(target, source, x, y)
  }

  function clamp(value: var, min: var, max: var): var {
    var n = Number(value)
    if (!isFinite(n)) return min
    return Math.max(min, Math.min(max, n))
  }

  function clampAlpha(value: var): real {
    return clamp(value, 0, 1)
  }

  function wheelSteps(accumulator: real, delta: real): var {
    // Some mouse/compositor combinations scale a single notch well beyond
    // Qt's conventional 120 units. Keep one event to one step while still
    // accumulating the smaller deltas emitted by touchpads.
    delta = Math.max(-120, Math.min(120, delta))
    if (accumulator * delta < 0) accumulator = 0
    var total = accumulator + delta
    var steps = total < 0 ? Math.ceil(total / 120) : Math.floor(total / 120)
    return { steps: steps, remainder: total - steps * 120 }
  }

  // Compose a base color with an opacity. Accepts a color object or a hex
  // string; null/undefined yields transparent black at the requested alpha.
  function alpha(c: var, opacity: var): color {
    return UtilData.alpha(c, clampAlpha(opacity))
  }

  // file:// URL with each path segment percent-encoded so spaces and
  // special chars in user paths don't break Image.source.
  function fileUrl(path: var): string {
    if (!path) return ""
    // Windows port: a `D:\dir/file` path becomes file:///D:/dir/file. Qt reads `file://D%3A...` as a
    // host name, and a bare `D:\...` as a URL with scheme `d`.
    var p = String(path).replace(/\\/g, "/")
    var drive = p.match(/^([A-Za-z]:)(\/.*)?$/)
    if (drive) return "file:///" + drive[1] + (drive[2] || "").split("/").map(encodeURIComponent).join("/")
    return "file://" + p.split("/").map(encodeURIComponent).join("/")
  }

  function isVideoPath(path: var): bool {
    return /\.(mp4|m4v|mov|webm|mkv|avi)$/i.test(String(path || ""))
  }

  // Single-quote a string for bash. The replace handles embedded single
  // quotes by closing, escaping, and re-opening the literal.
  function shellQuote(value: var): string {
    return "'" + String(value || "").replace(/'/g, "'\\''") + "'"
  }

  function execDetached(command: var): void {
    Quickshell.execDetached(["C:/Program Files/Git/usr/bin/bash.exe", "-lc", command])
  }

  // Run an argv vector without a shell interpreting it: the constant `exec "$@"`
  // means the args only ever land in positional parameters, which bash expands
  // without re-tokenizing — so untrusted data ($(id), a filename) stays literal.
  // The login shell (-l) keeps the PATH/session env GUI targets (omasnap, mpv,
  // xdg-open) need. Prefer this over execDetached for anything built from input.
  function execArgv(argv: var): void {
    Quickshell.execDetached(["C:/Program Files/Git/usr/bin/bash.exe", "-lc", 'exec "$@"', "C:/Program Files/Git/usr/bin/bash.exe"].concat(argv))
  }

  function isPlainObject(value: var): bool {
    return value !== null && typeof value === "object" && !Array.isArray(value)
  }

  function canonicalWidgetId(id: var): string {
    return String(id || "")
  }

  // Best-effort base64 decode. Returns "" on parse failure rather than
  // surfacing garbage downstream.
  function decodeBase64(value: var): string {
    var s = String(value || "")
    return s ? UtilData.decodeBase64(s) : ""
  }

  function cloneJson(value: var): var {
    return JSON.parse(JSON.stringify(value === undefined ? null : value))
  }

  // Parse the last line of a custom-module / indicator process output as
  // waybar-style JSON ({text, class, tooltip, ...}). Falls back to {text: raw}
  // when the output isn't JSON, and {} for empty output.
  function parseModuleJson(raw: string): var {
    return UtilData.parseModuleJson(raw)
  }

  // Standard Qt text-editing keys shared by every searchable panel's filter:
  //   Backspace       delete previous character
  //   Ctrl+Backspace  delete previous word (Qt DeleteStartOfWord)
  //   Ctrl+U          clear the whole field
  // True only when the event would actually change the text, so an empty
  // filter never swallows the key — panels keep their own empty-filter
  // fallbacks (e.g. menu back-navigation) in later branches.
  // The arrow a horizontal key press means along the reading direction: in a
  // right-to-left layout, mirrored, Left moves forward and Right back. With
  // vim set, h and l count as Left and Right too.
  function readingKey(event: KeyEvent, vim: bool): int {
    var key = event.key
    if (vim && (key === Qt.Key_H || event.text === "h")) key = Qt.Key_Left
    else if (vim && (key === Qt.Key_L || event.text === "l")) key = Qt.Key_Right
    if (I18n.rightToLeft) {
      if (key === Qt.Key_Left) return Qt.Key_Right
      if (key === Qt.Key_Right) return Qt.Key_Left
    }
    return key
  }

  function editsFilter(event: KeyEvent, text: string): bool {
    if (!text) return false
    // Alt/Meta-modified sequences belong to other shortcuts — never edit here.
    if (event.modifiers & (Qt.AltModifier | Qt.MetaModifier)) return false
    if (event.key === Qt.Key_U)                     // Ctrl+U only (not Ctrl+Shift+U → Unicode input)
      return event.modifiers === Qt.ControlModifier
    return event.key === Qt.Key_Backspace           // plain, Shift, or Ctrl Backspace
  }

  // New filter text after applying an edit key. Assumes editsFilter(event, text).
  function editedFilter(event: KeyEvent, text: string): string {
    if (event.key === Qt.Key_U) return ""                        // Ctrl+U: clear
    if (event.modifiers & Qt.ControlModifier)                    // Ctrl+Backspace: word
      return text.replace(/\s+$/, "").replace(/\S+$/, "")
    return text.slice(0, -1)                                     // Backspace: char
  }

  // Layout normalization shared by bar config consumers
  // so the two never drift. Entries are deep-cloned to decouple from the
  // input config; consumers can mutate without leaking back to shell.json.
  function normalizeLayoutEntry(entry: var): var {
    if (typeof entry === "string") return { id: canonicalWidgetId(entry) }
    if (isPlainObject(entry) && UtilData.field(entry, "id")) {
      let copy = cloneJson(entry)
      UtilData.setField(copy, "id", canonicalWidgetId(UtilData.field(copy, "id")))
      return copy
    }
    return null
  }

  function normalizeLayoutSection(list: var): var {
    if (!Array.isArray(list)) return []
    var out = []
    for (let i = 0; i < UtilData.arrayLength(list); i++) {
      let e = normalizeLayoutEntry(list[i])
      if (e) out.push(e)
    }
    return out
  }

  // The bar's sections in the order they run along it, and tray, drawn
  // inside the tray's drawer. The center box sits in the middle of the bar;
  // centerBegin and centerEnd hang off its two edges.
  readonly property var barSections: ["left", "centerBegin", "center", "centerEnd", "right", "tray"]

  function normalizeLayout(layout: var): var {
    var src = isPlainObject(layout) ? layout : {}
    var out = {}
    for (let i = 0; i < UtilData.arrayLength(barSections); i++)
      out[barSections[i]] = normalizeLayoutSection(src[barSections[i]])
    return out
  }
}
