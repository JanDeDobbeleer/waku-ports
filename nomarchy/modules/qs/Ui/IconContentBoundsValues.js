.pragma library

function mappedBounds(item) { return item.mappedBounds }

function childrenOf(item) { return item ? item.children : [] }
function textFont(item) { return item ? item.font : Qt.font({ pixelSize: 12 }) }
function textValue(item) { return item ? item.text : "" }
function textBounds(item, ink, alignCenter, alignRight) {
  var spareWidth = item.width - item.leftPadding - item.rightPadding - item.contentWidth
  var textX = item.leftPadding
  if (item.effectiveHorizontalAlignment === alignCenter) textX += spareWidth / 2
  else if (item.effectiveHorizontalAlignment === alignRight) textX += spareWidth
  return [textX + ink.x, item.baselineOffset + ink.y, ink.width, ink.height]
}
function imageBounds(item, alignLeft, alignRight, alignTop, alignBottom, preserveFit, pad) {
  var w = item.paintedWidth
  var h = item.paintedHeight
  var x = item.horizontalAlignment === alignLeft ? 0
    : (item.horizontalAlignment === alignRight ? item.width - w : (item.width - w) / 2)
  var y = item.verticalAlignment === alignTop ? 0
    : (item.verticalAlignment === alignBottom ? item.height - h : (item.height - h) / 2)
  if (item.fillMode === preserveFit) return [x, y, w, h]
  if (item.fillMode === pad) {
    var left = Math.max(0, x)
    var top = Math.max(0, y)
    return [left, top, Math.max(0, Math.min(item.width, x + w) - left),
      Math.max(0, Math.min(item.height, y + h) - top)]
  }
  return [0, 0, item.width, item.height]
}
function shapeBounds(item, noResize, preserveFit, preserveCrop, alignCenter, alignRight, alignVCenter, alignBottom) {
  var bounds = item.boundingRect
  var sx = 1
  var sy = 1
  if (item.fillMode !== noResize && item.implicitWidth > 0 && item.implicitHeight > 0) {
    sx = item.width / item.implicitWidth
    sy = item.height / item.implicitHeight
    if (item.fillMode === preserveFit) sx = sy = Math.min(sx, sy)
    else if (item.fillMode === preserveCrop) sx = sy = Math.max(sx, sy)
  }
  var spareWidth = item.width - item.implicitWidth * sx
  var spareHeight = item.height - item.implicitHeight * sy
  var x = item.horizontalAlignment === alignCenter ? spareWidth / 2
    : (item.horizontalAlignment === alignRight ? spareWidth : 0)
  var y = item.verticalAlignment === alignVCenter ? spareHeight / 2
    : (item.verticalAlignment === alignBottom ? spareHeight : 0)
  return [x + bounds.x * sx, y + bounds.y * sy, bounds.width * sx, bounds.height * sy]
}
function boxBounds(item) { return [0, 0, item.width, item.height] }
function clipBounds(item, bounds) {
  var left = Math.max(0, bounds.x)
  var top = Math.max(0, bounds.y)
  return [left, top, Math.max(0, Math.min(item.width, bounds.x + bounds.width) - left),
    Math.max(0, Math.min(item.height, bounds.y + bounds.height) - top)]
}
function mapBounds(item, parent, bounds) {
  return item.mapToItem(parent, bounds.x, bounds.y, bounds.width, bounds.height)
}
function isClipped(item) { return !!(item && item.clip) }
function setTextRendering(item, mode) { if (item) item.renderType = mode }
