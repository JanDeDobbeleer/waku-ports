.pragma library

function expandedScale(stops, value, current) {
  var length = stops ? stops.length : 0
  for (var i = 0; i < length; i++) {
    var stop = stops[i]
    if (value <= stop * 0.92) return stop > current ? stop : current
  }
  return length > 0 ? stops[length - 1] : current
}
