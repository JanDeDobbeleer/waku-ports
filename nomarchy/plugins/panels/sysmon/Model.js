// Reads of the engine's untyped sample lists and disk maps, kept out of QML so
// qmlcachegen can compile the bindings that use them.
.pragma library

function clampPercent(value) {
  var v = Number(value)
  if (!isFinite(v)) return 0
  return Math.max(0, Math.min(100, v))
}

// The last `count` samples as polyline points, newest at the right edge. The
// line is inset by half its width so a flat 0% or 100% run stays visible.
function sparkPoints(history, count, width, height, lineWidth) {
  var samples = Array.from(history || [])
  if (samples.length > count) samples = samples.slice(samples.length - count)
  var points = []
  if (samples.length === 0 || width <= 0 || height <= 0) return points
  var step = count > 1 ? width / (count - 1) : width
  var inset = lineWidth / 2
  var span = Math.max(0, height - lineWidth)
  var left = width - (samples.length - 1) * step
  for (var i = 0; i < samples.length; i++) {
    points.push(Qt.point(left + i * step, inset + span * (1 - clampPercent(samples[i]) / 100)))
  }
  if (points.length === 1) points.unshift(Qt.point(Math.max(0, points[0].x - step), points[0].y))
  return points
}

// The same line closed along the bottom edge, for the faint fill beneath it.
function areaPoints(points, height) {
  var list = Array.from(points || [])
  if (list.length < 2) return []
  list.push(Qt.point(list[list.length - 1].x, height))
  list.push(Qt.point(list[0].x, height))
  return list
}

function gigabytes(bytes) {
  return (Number(bytes) || 0) / 1073741824
}

// "Qualcomm(R) Adreno(TM) X1-85 GPU" -> "Qualcomm Adreno X1-85 GPU".
function gpuName(name) {
  return String(name || "").replace(/\((R|TM|C)\)/gi, "").replace(/\s+/g, " ").trim()
}

function diskRows(disks) {
  return Array.from(disks || []).map(function(disk) {
    return {
      mount: String(disk.mount || ""),
      used: gigabytes(disk.used),
      total: gigabytes(disk.total),
      percent: clampPercent(disk.percent)
    }
  }).filter(function(row) { return row.mount !== "" && row.total > 0 })
}

function rowField(row, key) {
  return row ? row[key] : undefined
}