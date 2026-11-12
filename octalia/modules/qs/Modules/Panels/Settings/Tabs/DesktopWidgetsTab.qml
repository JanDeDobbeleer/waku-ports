pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Compositor
import qs.Services.UI
import qs.Widgets
import qs.compat
import "DesktopWidgetsTab.js" as DesktopWidgetsData

ColumnLayout {
  id: root

  spacing: Style.marginL

  // Available widgets model - declared early so Repeater delegates can access it
  property alias availableWidgetsModel: availableWidgets
  ListModel {
    id: availableWidgets
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.enabled-label")
    description: I18n.tr("panels.desktop-widgets.enabled-description")
    checked: Settings.data.desktopWidgets.enabled
    defaultValue: Settings.getDefaultValue("desktopWidgets.enabled")
    onToggled: checked => Settings.data.desktopWidgets.enabled = checked
  }

  ColumnLayout {
    enabled: Settings.data.desktopWidgets.enabled

    NLabel {
      description: I18n.tr("panels.desktop-widgets.cpu-intensive-note")
    }

    NButton {
      Layout.fillWidth: true
      Layout.topMargin: Style.marginM
      Layout.bottomMargin: Style.marginM
      text: DesktopWidgetRegistry.editMode ? I18n.tr("panels.desktop-widgets.edit-mode-exit-button") : I18n.tr("panels.desktop-widgets.edit-mode-button-label")
      icon: "edit"
      onClicked: {
        DesktopWidgetRegistry.editMode = !DesktopWidgetRegistry.editMode;
        if (DesktopWidgetRegistry.editMode && Settings.data.ui.settingsPanelMode !== "window") {
          DesktopWidgetsData.closeNearestOwner(root.parent);
        }
      }
    }

    // One NSectionEditor per monitor
    Repeater {
      model: Quickshell.screens

      NSectionEditor {
        required property var modelData
        readonly property real compositorScale: DesktopWidgetsData.compositorScale(CompositorService.displayScales, modelData)

        Layout.fillWidth: true
        sectionName: DesktopWidgetsData.screenProperty(modelData, "name")
        sectionSubtitle: DesktopWidgetsData.screenSubtitle(modelData, compositorScale)

        sectionId: DesktopWidgetsData.screenProperty(modelData, "name")
        screen: modelData
        settingsDialogComponent: Qt.resolvedUrl(ShellUrl.dir + "/modules/qs/Modules/Panels/Settings/DesktopWidgets/DesktopWidgetSettingsDialog.qml")
        widgetRegistry: DesktopWidgetRegistry
        widgetModel: root.getWidgetsForMonitor(DesktopWidgetsData.screenProperty(modelData, "name"))
        availableWidgets: root.availableWidgetsModel
        availableSections: root.getScreenNames()
        sectionLabels: root.getScreenLabels()
        sectionIcons: root.getScreenIcons()
        draggable: false // Desktop widgets are positioned by X,Y, not list order
        crossSectionDraggable: true
        maxWidgets: -1
        onAddWidget: (widgetId, section) => root._addWidgetToMonitor(DesktopWidgetsData.screenProperty(modelData, "name"), widgetId)
        onRemoveWidget: (section, index) => root._removeWidgetFromMonitor(DesktopWidgetsData.screenProperty(modelData, "name"), index)
        onMoveWidget: (fromSection, index, toSection) => root._moveWidgetToMonitor(fromSection, index, toSection)
        onUpdateWidgetSettings: (section, index, settings) => root._updateWidgetSettingsForMonitor(DesktopWidgetsData.screenProperty(modelData, "name"), index, settings)
      }
    }
  }

  Component.onCompleted: {
    // Use Qt.callLater to ensure DesktopWidgetRegistry is ready
    Qt.callLater(updateAvailableWidgetsModel);
  }

  function getScreenNames(): var {
    return DesktopWidgetsData.getScreenNames(Quickshell.screens);
  }

  function getScreenLabels(): var {
    return DesktopWidgetsData.getScreenLabels(Quickshell.screens);
  }

  function getScreenIcons(): var {
    return DesktopWidgetsData.getScreenIcons(Quickshell.screens);
  }

  function desktopWidgetRegistry(): var {
    return typeof DesktopWidgetRegistry === "undefined" || !DesktopWidgetRegistry ? null : DesktopWidgetRegistry;
  }

  function updateAvailableWidgetsModel(): void {
    DesktopWidgetsData.updateAvailableWidgetsModel(root, availableWidgets, Color.mSecondary, Logger);
  }

  function getWidgetsForMonitor(monitorName: string): var {
    return DesktopWidgetsData.getWidgetsForMonitor(Settings.data.desktopWidgets.monitorWidgets || [], monitorName);
  }

  function setWidgetsForMonitor(monitorName: string, widgets: var): void {
    Settings.data.desktopWidgets.monitorWidgets = DesktopWidgetsData.setWidgetsForMonitor(Settings.data.desktopWidgets.monitorWidgets || [], monitorName, widgets);
  }

  function _addWidgetToMonitor(monitorName: string, widgetId: string): void {
    Settings.data.desktopWidgets.monitorWidgets = DesktopWidgetsData.addWidget(Settings.data.desktopWidgets.monitorWidgets || [], monitorName, widgetId, desktopWidgetRegistry());
  }

  function _removeWidgetFromMonitor(monitorName: string, index: int): void {
    const result = DesktopWidgetsData.removeWidget(Settings.data.desktopWidgets.monitorWidgets || [], monitorName, index);
    if (result !== null) {
      Settings.data.desktopWidgets.monitorWidgets = result;
    }
  }

  function _updateWidgetSettingsForMonitor(monitorName: string, index: int, settings: var): void {
    const result = DesktopWidgetsData.updateWidgetSettings(Settings.data.desktopWidgets.monitorWidgets || [], monitorName, index, settings);
    if (result !== null) {
      Settings.data.desktopWidgets.monitorWidgets = result;
    }
  }

  function _moveWidgetToMonitor(fromMonitor: string, index: int, toMonitor: string): void {
    const monitorWidgets = Settings.data.desktopWidgets.monitorWidgets || [];
    Logger.i("DesktopWidgetsTab", "Moving widget from", fromMonitor, "index", index, "to", toMonitor);
    if (!DesktopWidgetsData.validWidgetIndex(monitorWidgets, fromMonitor, index)) {
      Logger.e("DesktopWidgetsTab", "Invalid index", index, "for monitor", fromMonitor);
      return;
    }
    const moved = DesktopWidgetsData.moveWidget(monitorWidgets, fromMonitor, index, toMonitor);
    setWidgetsForMonitor(fromMonitor, moved.sourceWidgets);
    setWidgetsForMonitor(toMonitor, moved.destinationWidgets);
  }
}
