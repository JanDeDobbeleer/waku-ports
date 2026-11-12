import Quickshell
import qs.Commons
import "../BarWidgetHelpers.js" as BarWidgetHelpers
import qs.Services.UI
import qs.Widgets
import waku.services as S

// Windows port: the layout of waku's built-in tiler for the focused workspace (each desktop and
// monitor keeps its own). Click: next layout. Right click: previous. Hidden while the tiler is off.
NIconButton {
  id: root

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] ?? {}
  readonly property string screenName: screen ? screen.name : ""
  property var widgetSettings: {
    var widgets;
    if (section && sectionWidgetIndex >= 0 && screenName) {
      widgets = Settings.getBarWidgetsForScreen(screenName)[section];
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex];
      }
    }
    return {};
  }

  readonly property string iconColorKey: BarWidgetHelpers.readProperty(widgetSettings, "iconColor") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "iconColor") : BarWidgetHelpers.readProperty(widgetMetadata, "iconColor")

  readonly property var layouts: ({
      "mainStack": { "icon": "layout-sidebar", "title": "Main and stack" },
      "mainStackTop": { "icon": "layout-navbar", "title": "Main on top" },
      "columns": { "icon": "layout-columns", "title": "Columns" },
      "rows": { "icon": "layout-rows", "title": "Rows" },
      "bsp": { "icon": "layout-board", "title": "Binary split" },
      "grid": { "icon": "layout-grid", "title": "Grid" },
      "centerMain": { "icon": "layout-dashboard", "title": "Centered main" }
    })
  readonly property string layoutName: S.Tiling.currentLayout
  readonly property var info: layouts[layoutName] || ({ "icon": "layout", "title": layoutName })

  visible: S.Tiling.active && layoutName !== ""
  icon: BarWidgetHelpers.readProperty(info, "icon")
  baseSize: Style.getCapsuleHeightForScreen(screen?.name)
  applyUiScale: false
  customRadius: Style.radiusL
  colorBg: Style.capsuleColor
  colorFg: Color.resolveColorKey(iconColorKey)
  border.color: Style.capsuleBorderColor
  border.width: Style.capsuleBorderWidth

  onClicked: S.Tiling.cycleLayout(1)
  onRightClicked: S.Tiling.cycleLayout(-1)
}
