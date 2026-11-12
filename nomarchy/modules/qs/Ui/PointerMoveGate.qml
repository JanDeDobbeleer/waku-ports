import QtQuick
import "PointerMoveGateUtils.js" as PointerMoveGateUtils

// Filters synthetic hover churn from moving delegates under a stationary
// pointer. Call reset() after keyboard/list mutations, then moved() from a
// row MouseArea's onPositionChanged before changing cursor selection. A
// transition known to originate from the pointer can call allowInitialSample()
// so the item under the stationary pointer remains selected.
QtObject {
  id: root

  property Item referenceItem: null
  property real threshold: 1
  property bool primed: false
  property bool initialSampleAllowed: false
  property real lastX: 0
  property real lastY: 0

  function reset() {
    root.primed = false
    root.initialSampleAllowed = false
    root.lastX = 0
    root.lastY = 0
  }

  function allowInitialSample() {
    root.reset()
    root.initialSampleAllowed = true
  }

  function moved(item: Item, mouse: var): bool {
    return PointerMoveGateUtils.moved(root, item, mouse)
  }
}
