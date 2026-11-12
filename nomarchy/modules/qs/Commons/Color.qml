pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "BorderGeometry.js" as Geometry

// Color surfaces for the shell. Foundational palette (foreground, background,
// accent, urgent) comes from theme/colors.toml. Per-surface roles come from
// theme/shell.toml — generated per theme from default/themed/shell.toml.tpl,
// or shipped directly by a theme to replace the generated file. Surfaces that
// don't appear in shell.toml fall back to the foundational palette.
QtObject {
  id: root

  readonly property string home: (Quickshell.env("HOME") || "")
  readonly property string stateHome: home + "/.local/state"
  readonly property string currentThemePath: stateHome + "/nomarchy/current/theme"

  property color foreground: "#cacccc"
  property color background: "#101315"
  property color accent: "#cacccc"
  property color urgent: "#a55555"
  property color muted: "#707880"

  // Flat dictionary of "section.key" -> raw string from shell.toml.
  // Reassigning this whole property is what makes surface bindings below
  // re-evaluate when the theme swaps; mutating it in place would not.
  property var shellValues: ({})

  function pick(key: string, fallback: var): var {
    var v = shellValues[key]
    return (typeof v === "string" && v.length > 0) ? v : fallback
  }

  function pickAlpha(key: string, fallback: real): real {
    var v = shellValues[key]
    if (typeof v !== "string" || v.length === 0) return fallback
    var n = Number(v)
    if (!isFinite(n)) return fallback
    return Util.clampAlpha(n)
  }

  function firstColorToken(value: var): var {
    var parts = String(value || "").replace(/^\s+|\s+$/g, "").split(/\s+/)
    for (let i = 0; i < parts.length; i++) {
      if (!parts[i].match(/^-?\d+(?:\.\d+)?deg$/)) return parts[i]
    }
    return value
  }

  function flatColor(value: var, fallback: color): color {
    var seen = Object.create(null)
    var token = firstColorToken(value)
    var role = String(token || "").replace(/^\s+|\s+$/g, "").toLowerCase()
    while (root.shellValues[role] && root.shellValues[role] !== token) {
      if (seen[role]) return fallback
      seen[role] = true
      token = firstColorToken(root.shellValues[role])
      role = String(token || "").replace(/^\s+|\s+$/g, "").toLowerCase()
    }
    if (role === "foreground" || role === "text") return root.foreground
    if (role === "accent") return root.accent
    if (role === "urgent") return root.urgent
    if (role === "muted") return root.muted
    if (role === "background") return root.background
    if (role === "transparent") return Qt.rgba(0, 0, 0, 0)

    var color = Geometry.canonicalColor(token, 1)
    if (typeof color === "string" && color === token && token.charAt(0) !== "#") return fallback
    return color
  }

  // Compose a color from a base-color key and its `-alpha` companion. If the
  // base token is a gradient, color-only consumers use the first stop.
  function composed(colorKey: string, alphaKey: string, colorFallback: color, alphaFallback: real): color {
    return Util.alpha(flatColor(pick(colorKey, colorFallback), colorFallback), pickAlpha(alphaKey, alphaFallback))
  }

  component BarColors: QtObject {
    final property color background: root.composed("bar.background", "bar.background-alpha", root.background, 1.0)
    final property color text: root.pick("bar.text", root.foreground)
    final property color active: root.pick("bar.active", root.urgent)
  }
  final readonly property BarColors bar: BarColors {}
  component PopupColors: QtObject {
    final property color background: root.composed("popups.background", "popups.background-alpha", root.background, 1.0)
    final property color text: root.pick("popups.text", root.foreground)
    final property color border: root.composed("popups.border", "popups.border-alpha", root.accent, 1.0)
  }
  final readonly property PopupColors popups: PopupColors {}
  component TooltipColors: QtObject {
    final property color background: root.composed("tooltip.background", "tooltip.background-alpha", root.background, 1.0)
    final property color text: root.pick("tooltip.text", root.foreground)
    final property color border: root.composed("tooltip.border", "tooltip.border-alpha", root.foreground, 1.0)
  }
  final readonly property TooltipColors tooltip: TooltipColors {}
  component NotificationColors: QtObject {
    final property color background: root.composed("notifications.background", "notifications.background-alpha", root.background, 1.0)
    final property color text: root.pick("notifications.text", root.foreground)
    final property color border: root.composed("notifications.border", "notifications.border-alpha", root.accent, 1.0)
    final property color countdown: root.pick("notifications.countdown", root.accent)
  }
  final readonly property NotificationColors notifications: NotificationColors {}
  component MenuColors: QtObject {
    final property color background: root.composed("menu.background", "menu.background-alpha", root.background, 1.0)
    final property color text: root.pick("menu.text", root.foreground)
    final property color border: root.composed("menu.border", "menu.border-alpha", root.foreground, 1.0)
    final property color scrim: root.composed("menu.scrim", "menu.scrim-alpha", root.background, 0.5)
    final property color selectedBackground: root.composed("menu.selected-background", "menu.selected-background-alpha", root.foreground, 0.08)
    final property color selectedText: root.pick("menu.selected-text", root.accent)
    final property color selectedBorder: root.composed("menu.selected-border", "menu.selected-border-alpha", root.foreground, 0.0)
  }
  final readonly property MenuColors menu: MenuColors {}
  // polkit + lock share a single border-alpha across border / border-active /
  // border-error: the three states are mutually exclusive in time, so one
  // companion is enough.
  component PolkitColors: QtObject {
    final property color background: root.composed("polkit.background", "polkit.background-alpha", root.background, 1.0)
    final property color text: root.pick("polkit.text", root.foreground)
    final property color textError: root.pick("polkit.text-error", root.urgent)
    final property color border: root.composed("polkit.border", "polkit.border-alpha", root.accent, 1.0)
    final property color borderError: root.composed("polkit.border-error", "polkit.border-alpha", root.urgent, 1.0)
    final property color accent: root.pick("polkit.accent", root.accent)
    final property color scrim: root.composed("polkit.scrim", "polkit.scrim-alpha", root.background, 0.5)
  }
  final readonly property PolkitColors polkit: PolkitColors {}
  component LockColors: QtObject {
    final property color background: root.composed("lock.background", "lock.background-alpha", root.background, 0.8)
    final property color text: root.pick("lock.text", root.foreground)
    final property color placeholder: Geometry.field(root.shellValues, "lock.placeholder") ? root.flatColor(Geometry.field(root.shellValues, "lock.placeholder"), Util.alpha(root.foreground, 0.66)) : Util.alpha(root.foreground, 0.66)
    final property color textError: root.pick("lock.text-error", root.urgent)
    final property color border: root.composed("lock.border", "lock.border-alpha", root.foreground, 1.0)
    final property color borderActive: root.composed("lock.border-active", "lock.border-alpha", root.accent, 1.0)
    final property color borderError: root.composed("lock.border-error", "lock.border-alpha", root.urgent, 1.0)
    final property color selection: root.composed("lock.selection", "lock.selection-alpha", root.accent, 0.45)
  }
  final readonly property LockColors lock: LockColors {}
  // The image picker has no card surface or backdrop; per-slice dim
  // overlays / text outlines use the foundational `background` color directly.
  component ImagePickerColors: QtObject {
    final property color text: root.pick("image-picker.text", root.foreground)
    final property color selectedBorder: root.composed("image-picker.selected-border", "image-picker.selected-border-alpha", root.accent, 1.0)
    final property color unselectedBorder: root.composed("image-picker.unselected-border", "image-picker.unselected-border-alpha", root.foreground, 0.28)
  }
  final readonly property ImagePickerColors imagePicker: ImagePickerColors {}

  function loadColors(raw: string): void {
    var lines = String(raw || "").split("\n")
    var foundAccent = false
    var foundMuted = false
    var loadedForeground = false
    var loadedBackground = false
    var color0Value = ""
    var color4Value = ""
    var color7Value = ""
    var color8Value = ""
    for (let i = 0; i < lines.length; i++) {
      let match = lines[i].match(/^\s*([A-Za-z0-9_-]+)\s*=\s*["']?(#[0-9A-Fa-f]{6})/)
      if (!match) continue
      if (match[1] === "foreground") { foreground = match[2]; loadedForeground = true }
      else if (match[1] === "background") { background = match[2]; loadedBackground = true }
      // Prefer the explicit `accent` key; only fall back to color4 when the
      // theme doesn't define a separate accent. color4 appears later in the
      // file so the old single-property approach clobbered accent with it.
      else if (match[1] === "accent") { accent = match[2]; foundAccent = true }
      else if (match[1] === "muted") { muted = match[2]; foundMuted = true }
      else if (match[1] === "color0") color0Value = match[2]
      else if (match[1] === "color4") color4Value = match[2]
      else if (match[1] === "color7") color7Value = match[2]
      else if (match[1] === "color8") color8Value = match[2]
      else if (match[1] === "red" || match[1] === "color1") urgent = match[2]
    }
    if (!loadedBackground && color0Value.length > 0) background = color0Value
    if (!loadedForeground && color7Value.length > 0) foreground = color7Value
    if (!foundAccent && color4Value.length > 0) accent = color4Value
    if (!foundMuted) muted = color8Value.length > 0 ? color8Value : foreground
  }

  // Last theme-supplied and user-supplied shell.toml dicts, kept separate so
  // either can be reloaded without re-reading the other. `shellValues` is
  // always the merge of theme (base) and user (override) — see mergeShell.
  property var themeShellValues: ({})
  property var userShellValues: ({})

  // Single TOML walker for shell.toml. Both Color (surface roles) and Style
  // (typography, spacing, bar, control states) consume the resulting dict.
  // Accepts quoted strings, bare numeric values, bare width lists, and bare
  // role names; tolerates inline comments. Numbers are kept as strings here —
  // readers coerce when they pull a value.
  function parseShell(raw: string): var {
    var parsed = {}
    var text = String(raw || "")
    if (text) {
      let lines = text.split("\n")
      let section = ""
      for (let i = 0; i < lines.length; i++) {
        let line = lines[i].replace(/^\s+|\s+$/g, "")
        if (!line || line.charAt(0) === "#") continue
        let sectionMatch = line.match(/^\[([A-Za-z0-9_-]+)\]\s*(#.*)?$/)
        if (sectionMatch) { section = sectionMatch[1]; continue }
        let stringKv = line.match(/^([A-Za-z0-9_-]+)\s*=\s*["']([^"']+)["']\s*(#.*)?$/)
        let numKv = line.match(/^([A-Za-z0-9_-]+)\s*=\s*(-?\d+(?:\.\d+)?)\s*(#.*)?$/)
        let widthKv = line.match(/^([A-Za-z0-9_-]+)\s*=\s*(-?\d+(?:\.\d+)?(?:\s+-?\d+(?:\.\d+)?){1,3})\s*(#.*)?$/)
        let bareKv = line.match(/^([A-Za-z0-9_-]+)\s*=\s*([A-Za-z][A-Za-z0-9_-]*)\s*(#.*)?$/)
        let kv = stringKv || numKv || widthKv || bareKv
        if (!kv || !section) continue
        parsed[section + "." + kv[1]] = kv[2]
      }
    }
    return parsed
  }

  // Re-derive `shellValues` from theme base + user override and push it to
  // Style. User keys win, so a machine-level `~/.config/nomarchy/shell.toml`
  // survives theme switches (which replace only themeShellValues).
  function mergeShell(): void {
    var merged = {}
    for (let tk in themeShellValues) merged[tk] = themeShellValues[tk]
    for (let uk in userShellValues) merged[uk] = userShellValues[uk]
    shellValues = merged
    Style.applyShellValues(merged)
  }

  function loadShell(raw: string): void {
    themeShellValues = parseShell(raw)
    mergeShell()
  }

  function loadUserShell(raw: string): void {
    userShellValues = parseShell(raw)
    mergeShell()
  }

  // Startup load only. Runtime theme switches push the payload explicitly
  // through shell IPC.
  property FileView colorsFile: FileView {
    id: colorsFile
    path: root.currentThemePath + "/colors.toml"
    // Windows port: tools	heme-apply.ps1 rewrites the files; reload when they change.
    watchChanges: true
    onFileChanged: reload()
    printErrors: false
    onLoaded: root.loadColors(text())
  }
  property FileView shellFile: FileView {
    id: shellFile
    path: root.currentThemePath + "/shell.toml"
    watchChanges: true
    onFileChanged: reload()
    printErrors: false
    onLoaded: root.loadShell(text())
    onLoadFailed: root.loadShell("")
  }
  // Machine-level override, layered on top of whatever theme is active. This
  // is where `nomarchy display text size` writes `[font] base-size`. Watched so the
  // CLI takes effect live without restarting the shell; absent by default.
  property FileView userShellFile: FileView {
    id: userShellFile
    path: root.home + "/.config/nomarchy/shell.toml"
    watchChanges: true
    printErrors: false
    onLoaded: root.loadUserShell(text())
    // Re-read on change (including first creation) before loading — `text()`
    // is stale in the change signal itself, so route both paths through reload
    // → onLoaded to always parse fresh content.
    onFileChanged: reload()
    onLoadFailed: root.loadUserShell("")
  }
}
