import QtQuick
import waku.services as S
import qs.Commons
import qs.Ui
import "LayoutSwitcherModel.js" as LayoutSwitcherModel

// Windows port: the layout of waku's built-in tiler for the focused workspace (each desktop and
// monitor keeps its own). Left click: next layout. Right click: previous. Hidden while the tiler
// is off.
BarWidget {
  id: root
  moduleName: "nomarchy.layout-switcher"

  readonly property var names: ({
    "mainStack": { "label": "Main", "title": "Main and stack" },
    "mainStackTop": { "label": "Top", "title": "Main on top" },
    "columns": { "label": "Cols", "title": "Columns" },
    "rows": { "label": "Rows", "title": "Rows" },
    "bsp": { "label": "BSP", "title": "Binary split" },
    "grid": { "label": "Grid", "title": "Grid" },
    "centerMain": { "label": "Ctr", "title": "Centered main" }
  })

  readonly property string layoutName: S.Tiling.currentLayout
  readonly property string layoutLabel: LayoutSwitcherModel.label(names, layoutName)
  readonly property string layoutTitle: LayoutSwitcherModel.title(names, layoutName)

  visible: S.Tiling.active && layoutName !== ""
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.layoutLabel
    fontSize: Style.font.caption
    horizontalMargin: 6
    tooltipText: "Layout: " + root.layoutTitle + " (click: next, right click: previous)"
    onPressed: function(button) {
      S.Tiling.cycleLayout(button === Qt.RightButton ? -1 : 1)
    }
  }
}
