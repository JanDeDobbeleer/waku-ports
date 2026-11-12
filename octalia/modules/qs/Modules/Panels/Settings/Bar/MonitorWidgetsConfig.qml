import QtQuick 6.10
import QtQuick.Layouts
import "../../../../Helpers/QtObj2JS.js" as QtObj2JS
import qs.Commons
import "../SettingsValue.js" as SettingsValue
import "MonitorWidgetsConfig.js" as MonitorWidgetsData
import qs.Services.UI
import qs.Widgets
import qs.compat

// Monitor Widgets Configuration (inline)
NBox {
  id: root

  required property var screen
  readonly property string screenName: SettingsValue.optionalRead(screen, "name") || ""
  // determine bar orientation
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"

  color: Color.mSurfaceVariant
  Layout.fillWidth: true
  implicitHeight: content.implicitHeight + Style.margin2L

  function _getWidgetsContainer(): var {
    return MonitorWidgetsData.getWidgetsContainer(root, Settings, QtObj2JS);
  }

  function _saveWidgets(widgets: var): void {
    MonitorWidgetsData.saveWidgets(root, Settings, widgets);
  }

  function _addWidgetToSection(widgetId: string, section: string): void {
    MonitorWidgetsData.addWidget(root, Settings, QtObj2JS, BarWidgetRegistry, BarService, widgetId, section);
  }

  function _removeWidgetFromSection(section: string, index: int): void {
    MonitorWidgetsData.removeWidget(root, Settings, QtObj2JS, BarService, ToastService, I18n, section, index);
  }

  function _reorderWidgetInSection(section: string, fromIndex: int, toIndex: int): void {
    MonitorWidgetsData.reorderWidget(root, Settings, QtObj2JS, BarService, section, fromIndex, toIndex);
  }

  function _updateWidgetSettingsInSection(section: string, index: int, settings: var): void {
    MonitorWidgetsData.updateWidgetSettings(root, Settings, QtObj2JS, section, index, settings);
  }

  function _moveWidgetBetweenSections(fromSection: string, index: int, toSection: string): void {
    MonitorWidgetsData.moveWidget(root, Settings, QtObj2JS, BarService, fromSection, index, toSection);
  }

  function updateAvailableWidgetsModel(): void {
    MonitorWidgetsData.updateAvailableWidgetsModel(availableWidgetsModel, BarWidgetRegistry, Color);
  }

  // Available widgets ListModel
  Component.onCompleted: Qt.callLater(root.updateAvailableWidgetsModel)

  ListModel {
    id: availableWidgetsModel
  }

  // Get effective widgets for this screen
  readonly property var effectiveWidgets: Settings.getBarWidgetsForScreen(screenName)

  ColumnLayout {
    id: content
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginM

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
      screen: root.screen
      settingsDialogComponent: Qt.resolvedUrl(ShellUrl.dir + "/modules/qs/Modules/Panels/Settings/Bar/BarWidgetSettingsDialog.qml")
      widgetRegistry: BarWidgetRegistry
      widgetModel: SettingsValue.read(root.effectiveWidgets, "left")
      availableWidgets: availableWidgetsModel
      onAddWidget: (widgetId, section) => root._addWidgetToSection(widgetId, section)
      onRemoveWidget: (section, index) => root._removeWidgetFromSection(section, index)
      onReorderWidget: (section, fromIndex, toIndex) => root._reorderWidgetInSection(section, fromIndex, toIndex)
      onUpdateWidgetSettings: (section, index, settings) => root._updateWidgetSettingsInSection(section, index, settings)
      onMoveWidget: (fromSection, index, toSection) => root._moveWidgetBetweenSections(fromSection, index, toSection)
    }

    // Center Section
    NSectionEditor {
      sectionName: I18n.tr("positions.center")
      sectionId: "center"
      barIsVertical: root.barIsVertical
      screen: root.screen
      settingsDialogComponent: Qt.resolvedUrl(ShellUrl.dir + "/modules/qs/Modules/Panels/Settings/Bar/BarWidgetSettingsDialog.qml")
      widgetRegistry: BarWidgetRegistry
      widgetModel: SettingsValue.read(root.effectiveWidgets, "center")
      availableWidgets: availableWidgetsModel
      onAddWidget: (widgetId, section) => root._addWidgetToSection(widgetId, section)
      onRemoveWidget: (section, index) => root._removeWidgetFromSection(section, index)
      onReorderWidget: (section, fromIndex, toIndex) => root._reorderWidgetInSection(section, fromIndex, toIndex)
      onUpdateWidgetSettings: (section, index, settings) => root._updateWidgetSettingsInSection(section, index, settings)
      onMoveWidget: (fromSection, index, toSection) => root._moveWidgetBetweenSections(fromSection, index, toSection)
    }

    // Right Section
    NSectionEditor {
      sectionName: root.barIsVertical ? I18n.tr("positions.bottom") : I18n.tr("positions.right")
      sectionId: "right"
      barIsVertical: root.barIsVertical
      screen: root.screen
      settingsDialogComponent: Qt.resolvedUrl(ShellUrl.dir + "/modules/qs/Modules/Panels/Settings/Bar/BarWidgetSettingsDialog.qml")
      widgetRegistry: BarWidgetRegistry
      widgetModel: SettingsValue.read(root.effectiveWidgets, "right")
      availableWidgets: availableWidgetsModel
      onAddWidget: (widgetId, section) => root._addWidgetToSection(widgetId, section)
      onRemoveWidget: (section, index) => root._removeWidgetFromSection(section, index)
      onReorderWidget: (section, fromIndex, toIndex) => root._reorderWidgetInSection(section, fromIndex, toIndex)
      onUpdateWidgetSettings: (section, index, settings) => root._updateWidgetSettingsInSection(section, index, settings)
      onMoveWidget: (fromSection, index, toSection) => root._moveWidgetBetweenSections(fromSection, index, toSection)
    }
  }
}
