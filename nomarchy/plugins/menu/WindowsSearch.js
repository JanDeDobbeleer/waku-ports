.pragma library

// Evaluate arithmetic without executing user input as JavaScript.
function calculate(input) {
  var text = String(input || "").trim()
  if (text.length > 200 || !/[+\-*/%]/.test(text) || !/^[\d\s.+*/%()\-]+$/.test(text)) return ""
  var pos = 0
  function space() { while (/\s/.test(text.charAt(pos)) && pos < text.length) pos++ }
  function primary() {
    space()
    if (text.charAt(pos) === "+" || text.charAt(pos) === "-") {
      var sign = text.charAt(pos++) === "-" ? -1 : 1
      return sign * primary()
    }
    if (text.charAt(pos) === "(") {
      pos++
      var value = expression()
      space()
      if (text.charAt(pos++) !== ")") throw new Error("parenthesis")
      return value
    }
    var match = text.slice(pos).match(/^(?:\d+(?:\.\d*)?|\.\d+)/)
    if (!match) throw new Error("number")
    pos += match[0].length
    return Number(match[0])
  }
  function term() {
    var value = primary()
    for (;;) {
      space()
      var op = text.charAt(pos)
      if (op !== "*" && op !== "/" && op !== "%") return value
      pos++
      var right = primary()
      value = op === "*" ? value * right : op === "/" ? value / right : value % right
    }
  }
  function expression() {
    var value = term()
    for (;;) {
      space()
      var op = text.charAt(pos)
      if (op !== "+" && op !== "-") return value
      pos++
      var right = term()
      value = op === "+" ? value + right : value - right
    }
  }
  try {
    var result = expression()
    space()
    return pos === text.length && isFinite(result) ? String(Number(result.toPrecision(12))) : ""
  } catch (e) {
    return ""
  }
}

function row(kind, id, label, detail, action) {
  return {
    itemId: id, disabled: false, kind: kind, icon: kind === "calculator" ? "󰃬" : "󰖲",
    iconFont: "", appIcon: "", appId: "", label: label, target: "", detail: detail,
    path: "", childCount: 0, action: action, provider: "", score: 0, section: ""
  }
}

function results(query, windows, copyLabel, windowLabel) {
  var text = String(query || "").trim()
  var result = calculate(text)
  var rows = result === "" ? [] : [row("calculator", "calculator", result, copyLabel || "Press Enter to copy", result)]
  var needle = text.toLowerCase()
  if (!needle) return rows
  for (var i = 0; i < windows.length; i++) {
    var window = windows[i]
    if (!window || !window.hwnd || !window.title) continue
    var title = String(window.title)
    var app = String(window.appId || "")
    if ((title + " " + app).toLowerCase().indexOf(needle) < 0) continue
    rows.push(row("window", "window." + window.hwnd, title, app || windowLabel || "Open window", String(window.hwnd)))
  }
  return rows
}

function activateWindow(windows, hwnd) {
  for (var i = 0; i < windows.length; i++) {
    if (windows[i] && String(windows[i].hwnd) === hwnd) {
      windows[i].activate()
      return
    }

  }
}

function activateWallpaperTheme(shell) {
  return shell && shell.wallpaperTheme ? shell.wallpaperTheme.request(true) : "unavailable"
}
