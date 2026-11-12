.pragma library

function value(object, key) {
  return object == null ? undefined : object[key]
}

function call(receiver, method, args) {
  var callback = value(receiver, method)
  return typeof callback === "function" ? callback.apply(receiver, args || []) : undefined
}

function callFunction(callback, args) {
  return typeof callback === "function" ? callback.apply(null, args || []) : undefined
}

function finishDisplayDrag(layoutRects, screenRect, map, snapPixels, drop, select) {
  var name = value(value(screenRect, "modelData"), "name")
  var dragX = value(screenRect, "dragX")
  var dragY = value(screenRect, "dragY")
  var moved = Math.abs(dragX) + Math.abs(dragY) > 3
  var bounds = value(map, "bounds")
  var ratio = value(map, "ratio")
  var x = value(bounds, "x") + (value(screenRect, "x") - value(map, "offsetX")) / ratio
  var y = value(bounds, "y") + (value(screenRect, "y") - value(map, "offsetY")) / ratio
  screenRect.dragX = 0
  screenRect.dragY = 0
  var snap = snapPixels / ratio
  if (moved) drop(layoutRects, name, x, y, snap)
  else select(name)
}
