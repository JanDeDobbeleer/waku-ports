.pragma library

function palette(scheme, dark) {
  if (!scheme || !scheme.valid || scheme.dark !== dark || !scheme.colors) return ""
  var c = scheme.colors
  function color(name, fallback) {
    var value = String(c[name] || c[fallback] || "")
    return /^#[0-9a-f]{6}$/i.test(value) ? value : ""
  }

  var background = color("surface", "background")
  var foreground = color("onSurface", "onBackground")
  var accent = color("primary", "secondary")
  var muted = color("outline", "onSurfaceVariant")
  var selection = color("surfaceContainerHighest", "surfaceVariant")
  var red = color("error", "primary")
  var secondary = color("secondary", "primary")
  var tertiary = color("tertiary", "primary")
  if (!background || !foreground || !accent || !muted || !selection || !red || !secondary || !tertiary) return ""
  return JSON.stringify({
    mode: scheme.dark ? "dark" : "light",
    accent: accent, selection: selection, muted: muted,
    background: background, dark_background: background, darker_background: background,
    lighter_background: selection, foreground: foreground, dark_foreground: muted,
    light_foreground: foreground, bright_foreground: foreground,
    red: red, yellow: tertiary, orange: tertiary, green: secondary, cyan: secondary,
    blue: accent, magenta: tertiary, brown: muted,
    bright_red: red, bright_yellow: tertiary, bright_green: secondary, bright_cyan: secondary,
    bright_blue: accent, bright_magenta: tertiary
  })
}

function encode(qt, text) {
  return qt.btoa(text)
}

function isDark(scheme) {
  return !!scheme && scheme.dark === true
}
