.pragma library

function moved(state, item, mouse) {
  if (!item || !mouse) {
    state.reset()
    return false
  }
  var target = state.referenceItem || item
  var point = item.mapToItem(target, mouse.x, mouse.y)
  var firstSample = !state.primed
  var didMove = !firstSample
    ? Math.abs(point.x - state.lastX) > state.threshold || Math.abs(point.y - state.lastY) > state.threshold
    : state.initialSampleAllowed
  if (firstSample || didMove) {
    state.lastX = point.x
    state.lastY = point.y
  }
  state.primed = true
  state.initialSampleAllowed = false
  return didMove
}
