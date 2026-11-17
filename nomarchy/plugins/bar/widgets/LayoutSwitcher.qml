import QtQuick
import waku.services as S
import qs.Commons
import qs.Ui
import "LayoutSwitcherModel.js" as LayoutSwitcherModel

// Windows port: the layout of waku's built-in tiler for the focused workspace (each desktop and
// monitor keeps its own). Left click: next layout. Right click: previous.
BarWidget {
  id: root
  moduleName: "nomarchy.layout-switcher"

  readonly property var names: ({
    "mainStack": { "icon": "\uf114", "title": "Main and stack" },
    "mainStackTop": { "icon": "\ue8e9", "title": "Main on top" },
    "columns": { "icon": "\ue8ec", "title": "Columns" },
    "rows": { "icon": "\uf101", "title": "Rows" },
    "bsp": { "icon": "\ue8f1", "title": "Binary split" },
    "grid": { "icon": "\ue9b0", "title": "Grid" },
    "centerMain": { "icon": "\ue8f3", "title": "Centered main" }
  })

  readonly property string layoutName: S.Tiling.currentLayout
  readonly property bool available: S.Tiling.active && layoutName !== ""
  readonly property string layoutIcon: LayoutSwitcherModel.icon(names, layoutName)
  readonly property string layoutTitle: LayoutSwitcherModel.title(names, layoutName)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.layoutIcon
    fontFamily: "Material Symbols Rounded"
    labelVisible: false
    fixedWidth: root.vertical ? root.barSize : Style.bar.iconSlot
    fixedHeight: root.vertical ? Style.bar.iconSlot : root.barSize
    dimmed: !root.available
    pressable: root.available
    tooltipText: !S.Tiling.active ? "Layout: tiling is paused or off"
      : !root.available ? "Layout: no focused workspace"
      : "Layout: " + root.layoutTitle + " (click: next, right click: previous)"
    onPressed: function(button) {
      if (!root.available) return
      if (button === Qt.LeftButton) S.Tiling.cycleLayout(1)
      else if (button === Qt.RightButton) S.Tiling.cycleLayout(-1)
    }

    // Material Symbols are centered in their font cell, not their reported tight-ink bounds.
    Text {
      anchors.centerIn: parent
      text: root.layoutIcon
      font.family: button.fontFamily
      font.pixelSize: Style.bar.iconCanvas
      color: button.foreground
      scale: button.pressScale
      renderType: Text.QtRendering
    }
  }
}
