import QtQuick

ListView {
  // Preserve the user's scroll position when a refreshed model is assigned.
  final property real rememberedY: 0
  function rememberPosition(): void { rememberedY = contentY }
  onContentYChanged: if (moving || dragging) rememberedY = contentY
  onModelChanged: contentY = Math.max(0, Math.min(rememberedY, Math.max(0, contentHeight - height)))
}
