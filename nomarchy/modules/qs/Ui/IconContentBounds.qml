pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import "IconContentBoundsValues.js" as BoundsValues

Item {
  id: root

  property Item sourceItem: null
  property Item boundsParent: null
  property rect mappedBounds: Qt.rect(0, 0, 0, 0)
  visible: false

  readonly property bool textItem: (sourceItem as Text) !== null
  readonly property bool imageItem: (sourceItem as Image) !== null
  readonly property bool shapeItem: (sourceItem as Shape) !== null
  readonly property bool boxItem: (sourceItem as Rectangle) !== null
    || (sourceItem as Canvas) !== null || (sourceItem as ShaderEffect) !== null

  function unionBounds(a: rect, b: rect): rect {
    if (b.width <= 0 || b.height <= 0) return a
    if (a.width <= 0 || a.height <= 0) return b
    var x = Math.min(a.x, b.x)
    var y = Math.min(a.y, b.y)
    return Qt.rect(x, y, Math.max(a.x + a.width, b.x + b.width) - x,
      Math.max(a.y + a.height, b.y + b.height) - y)
  }


  readonly property rect paintedBounds: {
    var item = sourceItem
    var bounds = Qt.rect(0, 0, 0, 0)
    if (!item || !item.visible || item.opacity <= 0) return bounds
    if (textItem) {
      let values = BoundsValues.textBounds(item, textMetrics.tightBoundingRect, Text.AlignHCenter, Text.AlignRight)
      bounds = Qt.rect(values[0], values[1], values[2], values[3])
    } else if (imageItem) {
      let values = BoundsValues.imageBounds(item, Image.AlignLeft, Image.AlignRight, Image.AlignTop,
        Image.AlignBottom, Image.PreserveAspectFit, Image.Pad)
      bounds = Qt.rect(values[0], values[1], values[2], values[3])
    } else if (shapeItem) {
      let values = BoundsValues.shapeBounds(item, Shape.NoResize, Shape.PreserveAspectFit, Shape.PreserveAspectCrop,
        Shape.AlignHCenter, Shape.AlignRight, Shape.AlignVCenter, Shape.AlignBottom)
      bounds = Qt.rect(values[0], values[1], values[2], values[3])
    } else if (boxItem) {
      let values = BoundsValues.boxBounds(item)
      bounds = Qt.rect(values[0], values[1], values[2], values[3])
    }
    for (let i = 0; i < childrenBounds.count; i++) {
      let child = childrenBounds.itemAt(i)
      if (child) bounds = unionBounds(bounds, BoundsValues.mappedBounds(child))
    }
    if (BoundsValues.isClipped(item) && bounds.width > 0 && bounds.height > 0) {
      let clipped = BoundsValues.clipBounds(item, bounds)
      bounds = Qt.rect(clipped[0], clipped[1], clipped[2], clipped[3])
    }
    return bounds
  }

  function updateMappedBounds(): void {
    var b = paintedBounds
    mappedBounds = sourceItem && boundsParent && b.width > 0 && b.height > 0
      ? BoundsValues.mapBounds(sourceItem, boundsParent, b)
      : b
  }

  function configureSource(): void {
    if (textItem) BoundsValues.setTextRendering(sourceItem, Text.CurveRendering)
    updateMappedBounds()
  }

  onPaintedBoundsChanged: updateMappedBounds()
  onSourceItemChanged: configureSource()
  onBoundsParentChanged: updateMappedBounds()
  Component.onCompleted: updateMappedBounds()

  TextMetrics {
    id: textMetrics
    font: root.textItem ? BoundsValues.textFont(root.sourceItem) : Qt.font({ pixelSize: 12 })
    text: root.textItem ? BoundsValues.textValue(root.sourceItem) : ""
  }

  Connections {
    target: root.sourceItem
    function onXChanged() { root.updateMappedBounds() }
    function onYChanged() { root.updateMappedBounds() }
    function onWidthChanged() { root.updateMappedBounds() }
    function onHeightChanged() { root.updateMappedBounds() }
    function onScaleChanged() { root.updateMappedBounds() }
    function onRotationChanged() { root.updateMappedBounds() }
    function onTransformOriginChanged() { root.updateMappedBounds() }
  }

  Repeater {
    id: childrenBounds
    model: root.sourceItem ? BoundsValues.childrenOf(root.sourceItem) : []
    delegate: Loader {
      id: childLoader
      required property var modelData
      readonly property rect mappedBounds: item ? BoundsValues.mappedBounds(item) : Qt.rect(0, 0, 0, 0)
      source: Qt.resolvedUrl("IconContentBounds.qml")
      Binding { target: childLoader.item; property: "sourceItem"; value: childLoader.modelData }
      Binding { target: childLoader.item; property: "boundsParent"; value: root.sourceItem }
    }
  }
}
