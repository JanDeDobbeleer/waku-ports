import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets
import qs.compat
import "WidgetsSubTab.js" as WidgetsSubTabData

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  property var availableWidgets
  property var addWidgetToSection
  property var removeWidgetFromSection
  property var reorderWidgetInSection
  property var updateWidgetSettingsInSection
  property var moveWidgetBetweenSections

  // This sub-tab edits the global default widget configuration (Settings.data.bar.widgets).
  // Per-screen widget overrides are edited in MonitorWidgetsConfig.qml (Monitors sub-tab).

  // determine bar orientation
  readonly property string barPosition: Settings.data.bar.position
  readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"

  function getSectionIcons(): var {
    return {
      "left": "arrow-bar-to-up",
      "center": "layout-distribute-horizontal",
      "right": "arrow-bar-to-down"
    };
  }

  NText {
    text: I18n.tr("panels.bar.widgets-desc")
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  // Left Section
  NSectionEditor {
    sectionName: root.barIsVertical ? I18n.tr("positions.top") : I18n.tr("positions.left")
    sectionId: "left"
    barIsVertical: root.barIsVertical
    settingsDialogComponent: Qt.resolvedUrl(ShellUrl.dir + "/modules/qs/Modules/Panels/Settings/Bar/BarWidgetSettingsDialog.qml")
    widgetRegistry: BarWidgetRegistry
    widgetModel: Settings.data.bar.widgets.left
    sectionIcons: root.getSectionIcons()
    availableWidgets: root.availableWidgets
    onAddWidget: (widgetId, section) => WidgetsSubTabData.invoke(root, "addWidgetToSection", widgetId, section)
    onRemoveWidget: (section, index) => WidgetsSubTabData.invoke(root, "removeWidgetFromSection", section, index)
    onReorderWidget: (section, fromIndex, toIndex) => WidgetsSubTabData.invoke(root, "reorderWidgetInSection", section, fromIndex, toIndex)
    onUpdateWidgetSettings: (section, index, settings) => WidgetsSubTabData.invoke(root, "updateWidgetSettingsInSection", section, index, settings)
    onMoveWidget: (fromSection, index, toSection) => WidgetsSubTabData.invoke(root, "moveWidgetBetweenSections", fromSection, index, toSection)
  }

  // Center Section
  NSectionEditor {
    sectionName: I18n.tr("positions.center")
    sectionId: "center"
    barIsVertical: root.barIsVertical
    settingsDialogComponent: Qt.resolvedUrl(ShellUrl.dir + "/modules/qs/Modules/Panels/Settings/Bar/BarWidgetSettingsDialog.qml")
    widgetRegistry: BarWidgetRegistry
    widgetModel: Settings.data.bar.widgets.center
    sectionIcons: root.getSectionIcons()
    availableWidgets: root.availableWidgets
    onAddWidget: (widgetId, section) => WidgetsSubTabData.invoke(root, "addWidgetToSection", widgetId, section)
    onRemoveWidget: (section, index) => WidgetsSubTabData.invoke(root, "removeWidgetFromSection", section, index)
    onReorderWidget: (section, fromIndex, toIndex) => WidgetsSubTabData.invoke(root, "reorderWidgetInSection", section, fromIndex, toIndex)
    onUpdateWidgetSettings: (section, index, settings) => WidgetsSubTabData.invoke(root, "updateWidgetSettingsInSection", section, index, settings)
    onMoveWidget: (fromSection, index, toSection) => WidgetsSubTabData.invoke(root, "moveWidgetBetweenSections", fromSection, index, toSection)
  }

  // Right Section
  NSectionEditor {
    sectionName: root.barIsVertical ? I18n.tr("positions.bottom") : I18n.tr("positions.right")
    sectionId: "right"
    barIsVertical: root.barIsVertical
    settingsDialogComponent: Qt.resolvedUrl(ShellUrl.dir + "/modules/qs/Modules/Panels/Settings/Bar/BarWidgetSettingsDialog.qml")
    widgetRegistry: BarWidgetRegistry
    widgetModel: Settings.data.bar.widgets.right
    sectionIcons: root.getSectionIcons()
    availableWidgets: root.availableWidgets
    onAddWidget: (widgetId, section) => WidgetsSubTabData.invoke(root, "addWidgetToSection", widgetId, section)
    onRemoveWidget: (section, index) => WidgetsSubTabData.invoke(root, "removeWidgetFromSection", section, index)
    onReorderWidget: (section, fromIndex, toIndex) => WidgetsSubTabData.invoke(root, "reorderWidgetInSection", section, fromIndex, toIndex)
    onUpdateWidgetSettings: (section, index, settings) => WidgetsSubTabData.invoke(root, "updateWidgetSettingsInSection", section, index, settings)
    onMoveWidget: (fromSection, index, toSection) => WidgetsSubTabData.invoke(root, "moveWidgetBetweenSections", fromSection, index, toSection)
  }
}
