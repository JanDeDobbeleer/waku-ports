// Reads the notification service's stored rows for the notification center.
.pragma library

var RETENTION_SECONDS = 24 * 3600
var REDACTED_SUMMARY = "Verification notification"

function field(object, name) {
  return object ? object[name] : undefined
}

function call(object, name, args) {
  if (!object || typeof object[name] !== "function") return undefined
  return object[name].apply(object, args || [])
}

function text(row, name) {
  var value = row ? row[name] : ""
  return value === undefined || value === null ? "" : String(value)
}

function number(row, name) {
  var value = row ? Number(row[name]) : 0
  return isFinite(value) ? value : 0
}

function flag(row, name) {
  return !!row && row[name] === true
}

function plain(markup) {
  return String(markup || "")
    .replace(/<br\s*\/?>/gi, " ")
    .replace(/<[^>]+>/g, "")
    .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"")
    .replace(/&#39;|&apos;/g, "'").replace(/&nbsp;/g, " ").replace(/&amp;/g, "&")
    .replace(/\s+/g, " ").trim()
}

function entry(row, live) {
  return {
    key: text(row, "key"),
    live: live,
    app: text(row, "app"),
    glyph: text(row, "glyph"),
    summary: text(row, "summary"),
    body: plain(text(row, "body")),
    redacted: text(row, "summary") === REDACTED_SUMMARY,
    urgent: number(row, "urgency") === 2,
    ts: number(row, "ts")
  }
}

// On-screen cards and closed history, newest first, one row per key.
function entries(service, nowSeconds) {
  var live = field(service, "liveEntries") || []
  var history = field(service, "historyEntries") || []
  var cutoff = nowSeconds - RETENTION_SECONDS
  var seen = Object.create(null), out = []
  for (var i = live.length - 1; i >= 0; i--) {
    var row = entry(live[i], true)
    if (!row.key || seen[row.key]) continue
    seen[row.key] = true
    out.push(row)
  }
  for (var j = 0; j < history.length; j++) {
    var closed = history[j]
    if (!closed || !(Number(closed.closed_ts) > cutoff)) continue
    var item = entry(closed, false)
    if (!item.key || seen[item.key]) continue
    seen[item.key] = true
    out.push(item)
  }
  out.sort(function(a, b) { return b.ts - a.ts })
  return out
}

function unreadCount(rows, seenTs) {
  var count = 0
  for (var i = 0; i < rows.length; i++) if (rows[i].ts > seenTs) count++
  return count
}

function length(rows) {
  return Array.isArray(rows) ? rows.length : 0
}

function keyAt(rows, index) {
  return Array.isArray(rows) && index >= 0 && index < rows.length ? rows[index].key : ""
}
