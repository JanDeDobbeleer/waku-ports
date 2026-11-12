import QtQuick
import qs.Commons

Flickable {
  id: root

  final readonly property real maxScroll: Math.max(0, contentHeight - height)

  function clamp(): void { contentY = Util.clamp(contentY, 0, maxScroll) }
  onHeightChanged: clamp()
  onContentHeightChanged: clamp()

  function scrollTo(y: real): void {
    scrollAnim.stop()
    scrollAnim.from = contentY
    scrollAnim.to = y
    scrollAnim.start()
  }
  function scrollToTop(): void { scrollTo(0) }

  // Wheel input writes contentY directly instead of starting this animation.
  NumberAnimation {
    id: scrollAnim
    target: root
    property: "contentY"
    duration: Style.duration(160)
    easing.type: Easing.OutCubic
  }
}
