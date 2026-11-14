pragma Singleton
import QtQuick
import qs.Commons as Commons
import "BorderGeometry.js" as Geometry

// Central border-spec factory for shell surfaces and controls. A spec carries
// color, optional gradient, and top/right/bottom/left widths so renderers can
// choose the cheap Rectangle path or the Shape-ring path without duplicating
// theme parsing logic.
QtObject {
  id: root

  function none(): var {
    return flat("transparent", 0)
  }

  function flat(color: var, width: var): var {
    return {
      color: color || "transparent",
      widths: Geometry.parseWidthSpec(width, 0),
      gradient: { colors: [], angle: 0, enabled: false },
    }
  }

  function value(section: string, key: string): var {
    var v = Commons.Color.shellValues[section + "." + key]
    return (v === undefined || v === null) ? "" : v
  }

  function valueOr(section: string, keys: var): var {
    for (let i = 0; i < Geometry.arrayLength(keys); i++) {
      let v = value(section, keys[i])
      if (String(v).length > 0) return v
    }
    return ""
  }

  function resolveValueRef(raw: var): string {
    var s = String(raw || "").replace(/^\s+|\s+$/g, "")
    var seen = {}
    while (s.match(/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/) && !seen[s]) {
      seen[s] = true
      let next = Commons.Color.shellValues[s]
      if (next === undefined || next === null || String(next).length === 0) break
      s = String(next).replace(/^\s+|\s+$/g, "")
    }
    return s
  }

  function alpha(section: string, key: string, fallback: real): real {
    var raw = value(section, key)
    if (String(raw).length === 0) return fallback
    var n = Number(raw)
    return isFinite(n) ? Geometry.clampAlpha(n) : fallback
  }

  function cssColor(color: var, opacity: real): var {
    var a = opacity === undefined || opacity === null ? 1 : Geometry.clampAlpha(opacity)
    if (color && typeof color === "object" && Geometry.field(color, "r") !== undefined) {
      return Geometry.qmlHexColor(Geometry.padHex(Number(Geometry.field(color, "r")) * 255) + Geometry.padHex(Number(Geometry.field(color, "g")) * 255) + Geometry.padHex(Number(Geometry.field(color, "b")) * 255), (Geometry.field(color, "a") === undefined ? 1 : Number(Geometry.field(color, "a"))) * a * 255)
    }

    var s = String(color || "").replace(/^\s+|\s+$/g, "")
    var role = s.toLowerCase()
    if (role === "foreground" || role === "text") return cssColor(Commons.Color.foreground, a)
    if (role === "accent") return cssColor(Commons.Color.accent, a)
    if (role === "urgent") return cssColor(Commons.Color.urgent, a)
    if (role === "background") return cssColor(Commons.Color.background, a)
    if (role === "transparent") return "transparent"
    return Geometry.canonicalColor(s, a)
  }

  function resolvedGradient(raw: var, fallbackColor: var, opacity: real): var {
    var s = String(raw || "").replace(/^\s+|\s+$/g, "")
    if (s.length === 0) return { colors: [], angle: 0, enabled: false }

    var parts = s.split(/\s+/)
    var colors = []
    var angle = 0
    for (let i = 0; i < parts.length; i++) {
      if (parts[i].match(/^-?\d+(?:\.\d+)?deg$/)) angle = Number(parts[i].replace(/deg$/, ""))
      else colors.push(cssColor(parts[i], opacity))
    }
    if (colors.length === 0) colors.push(cssColor(fallbackColor, opacity))
    return { colors: colors, angle: angle, enabled: colors.length > 1 }
  }

  function sameColor(a: var, b: var): bool { return Geometry.sameColor(a, b) }

  function localOrSurfaceSpec(section: string, token: string, localColor: var, defaultColor: var, fallbackWidth: int): var {
    if (!sameColor(localColor, defaultColor)) return flat(localColor, fallbackWidth)
    return surfaceSpec(section, token, localColor, fallbackWidth)
  }

  function surfaceWidths(section: string, token: string, fallbackWidth: int): var {
    var base = valueOr(section, token === "border" ? ["border-width"] : [token + "-width", "border-width"])
    var widths = Geometry.parseWidthSpec(base, fallbackWidth)
    return Geometry.withSideOverrides(
      widths,
      valueOr(section, token === "border" ? ["border-width-top"] : [token + "-width-top", "border-width-top"]),
      valueOr(section, token === "border" ? ["border-width-right"] : [token + "-width-right", "border-width-right"]),
      valueOr(section, token === "border" ? ["border-width-bottom"] : [token + "-width-bottom", "border-width-bottom"]),
      valueOr(section, token === "border" ? ["border-width-left"] : [token + "-width-left", "border-width-left"])
    )
  }

  function borderValue(raw: var, fallbackColor: var, opacity: real, legacyGradientRaw: var): var {
    var fallback = cssColor(fallbackColor, opacity)
    var primaryRaw = String(raw || "").replace(/^\s+|\s+$/g, "")
    var primary = resolvedGradient(primaryRaw.length > 0 ? primaryRaw : fallbackColor, fallbackColor, opacity)
    var color = Geometry.arrayLength(Geometry.field(primary, "colors")) > 0 ? Geometry.field(Geometry.field(primary, "colors"), 0) : fallback
    var gradient = Geometry.field(primary, "enabled") ? primary : { colors: [], angle: 0, enabled: false }

    // Backward compatibility for existing configs written during the separate
    // border-gradient experiment. New configs put solid colors and gradients in
    // the same border token.
    if (!Geometry.field(gradient, "enabled") && String(legacyGradientRaw || "").replace(/^\s+|\s+$/g, "").length > 0) {
      let legacy = resolvedGradient(legacyGradientRaw, color, opacity)
      if (Geometry.field(legacy, "enabled")) gradient = legacy
    }

    return { color: color, gradient: gradient }
  }

  function surfaceSpec(section: string, token: string, fallbackColor: var, fallbackWidth: int): var {
    var opacity = alpha(section, token + "-alpha", 1.0)
    var legacyGradientRaw = valueOr(section, token === "border" ? ["border-gradient"] : [token + "-gradient", "border-gradient"])
    var resolved = borderValue(resolveValueRef(value(section, token)), fallbackColor, opacity, legacyGradientRaw)

    return {
      color: Geometry.field(resolved, "color"),
      widths: surfaceWidths(section, token, fallbackWidth),
      gradient: Geometry.field(resolved, "gradient"),
    }
  }

  function hyprlandActiveSpec(fallbackColor: var, fallbackWidth: int): var {
    var raw = value("hyprland", "active-border")
    var opacity = alpha("hyprland", "active-border-alpha", 1.0)

    // Existing generated themes predate [hyprland] and already keep the active
    // border under [notifications]. Use it as the compatibility source until
    // the next theme refresh writes the shared token.
    if (String(raw).length === 0) {
      raw = value("notifications", "border")
      opacity = alpha("notifications", "border-alpha", opacity)
    }

    var resolved = borderValue(resolveValueRef(raw), fallbackColor, opacity, "")
    return {
      color: Geometry.field(resolved, "color"),
      widths: Geometry.parseWidthSpec(value("hyprland", "active-border-width"), fallbackWidth),
      gradient: Geometry.field(resolved, "gradient"),
    }
  }

  function controlPrefix(state: string): string {
    if (state === "hover" || state === "hot") return "hover-cursor"
    return state || "normal"
  }

  function controlColor(prefix: string, foreground: var, accent: var, urgent: var): var {
    if (prefix === "focus") return Style.focusStateColor(foreground, accent, urgent)
    if (prefix === "hover-cursor") return Style.hoverStateColor(foreground, accent, urgent)
    if (prefix === "selected") return Style.selectedStateColor(foreground, accent, urgent)
    return Style.normalStateColor(foreground, accent, urgent)
  }

  function controlAlpha(prefix: string): real {
    if (prefix === "focus") return Style.focusBorderAlpha
    if (prefix === "hover-cursor") return Style.hoverBorderAlpha
    if (prefix === "selected") return Style.selectedBorderAlpha
    return Style.normalBorderAlpha
  }

  function controlFallbackWidth(prefix: string): int {
    if (prefix === "focus") return Style.focusBorderWidth
    if (prefix === "hover-cursor") return Style.hoverBorderWidth
    if (prefix === "selected") return Style.selectedBorderWidth
    return Style.normalBorderWidth
  }

  function controlWidths(state: string): var {
    var prefix = controlPrefix(state)
    var fallbackWidth = controlFallbackWidth(prefix)
    var base = Style.styleOverrides[prefix + "-border-width"]
    var widths = Geometry.parseWidthSpec(base, fallbackWidth)
    return Geometry.withSideOverrides(
      widths,
      Style.styleOverrides[prefix + "-border-width-top"],
      Style.styleOverrides[prefix + "-border-width-right"],
      Style.styleOverrides[prefix + "-border-width-bottom"],
      Style.styleOverrides[prefix + "-border-width-left"]
    )
  }

  function controlHasWidth(state: string): bool {
    return Geometry.maxWidth(controlWidths(state)) > 0
  }

  function controlSpec(state: string, foreground: var, accent: var): var {
    var prefix = controlPrefix(state)
    var resolved = borderValue(
      Style.styleOverrides[prefix + "-border"],
      controlColor(prefix, foreground, accent, Commons.Color.urgent),
      controlAlpha(prefix),
      Style.styleOverrides[prefix + "-border-gradient"]
    )

    return { color: Geometry.field(resolved, "color"), widths: controlWidths(prefix), gradient: Geometry.field(resolved, "gradient") }
  }

  function withWidth(spec: var, width: var): var {
    if (!spec) return flat("transparent", 0)
    return Geometry.withWidth(spec, width)
  }

  function isNone(spec: var): bool { return Geometry.isNone(spec) }
  function needsOverlay(spec: var): bool { return Geometry.needsOverlay(spec) }
  function canUseNative(spec: var): bool { return Geometry.canUseNative(spec) }
  function top(spec: var): var { return Geometry.side(spec, "top") }
  function right(spec: var): var { return Geometry.side(spec, "right") }
  function bottom(spec: var): var { return Geometry.side(spec, "bottom") }
  function left(spec: var): var { return Geometry.side(spec, "left") }
  function uniformWidth(spec: var): var { return Geometry.side(spec, "top") }
  function color(spec: var): var { return Geometry.specColor(spec) }
}
