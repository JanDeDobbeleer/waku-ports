import QtQuick 6.10
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Compositor
import qs.Services.UI
import qs.Widgets
import qs.compat

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
          var item = root.parent;
          while (item) {
            if (item.closeRequested !== undefined) {
              item.closeRequested();
              break;
            }
            item = item.parent;
          }
        }
      }
    }

    // One NSectionEditor per monitor
    Repeater {
      model: Quickshell.screens

      NSectionEditor {
        required property var modelData
        readonly property real compositorScale: {
          const info = CompositorService.displayScales[modelData.name];
          return (info && info.scale) ? info.scale : 1.0;
        }

        Layout.fillWidth: true
        sectionName: modelData.name
        sectionSubtitle: {
          // Format scale to 2 decimal places to prevent overly long text
          var formattedScale = compositorScale.toFixed(2);
          return "(" + modelData.width + "x" + modelData.height + " @ " + formattedScale + "x)";
        }

        sectionId: modelData.name
        screen: modelData
        settingsDialogComponent: Qt.resolvedUrl(ShellUrl.dir + "/modules/qs/Modules/Panels/Settings/DesktopWidgets/DesktopWidgetSettingsDialog.qml")
        widgetRegistry: DesktopWidgetRegistry
        widgetModel: getWidgetsForMonitor(modelData.name)
        availableWidgets: root.availableWidgetsModel
        availableSections: root.getScreenNames()
        sectionLabels: root.getScreenLabels()
        sectionIcons: root.getScreenIcons()
        draggable: false // Desktop widgets are positioned by X,Y, not list order
        crossSectionDraggable: true
        maxWidgets: -1
        onAddWidget: (widgetId, section) => _addWidgetToMonitor(modelData.name, widgetId)
        onRemoveWidget: (section, index) => _removeWidgetFromMonitor(modelData.name, index)
        onMoveWidget: (fromSection, index, toSection) => _moveWidgetToMonitor(fromSection, index, toSection)
        onUpdateWidgetSettings: (section, index, settings) => _updateWidgetSettingsForMonitor(modelData.name, index, settings)
      }
    }
  }

  Component.onCompleted: {
    // Use Qt.callLater to ensure DesktopWidgetRegistry is ready
    Qt.callLater(updateAvailableWidgetsModel);
  }

  // Helper to get screen names array
  function getScreenNames() {
    var i;
    var names = [];
    for (i = 0; i < Quickshell.screens.length; i++) {
      names.push(Quickshell.screens[i].name);
    }
    return names;
  }

  // Helper to get screen labels map (just screen names, NSectionEditor adds "Move to" prefix)
  function getScreenLabels() {
    var i, screen;
    var labels = {};
    for (i = 0; i < Quickshell.screens.length; i++) {
      screen = Quickshell.screens[i];
      labels[screen.name] = screen.name;
    }
    return labels;
  }

  // Helper to get screen icons map
  function getScreenIcons() {
    var i;
    var icons = {};
    for (i = 0; i < Quickshell.screens.length; i++) {
      icons[Quickshell.screens[i].name] = "device-desktop";
    }
    return icons;
  }

  function updateAvailableWidgetsModel() {
    var displayName, i, widgetId, widgetIds;
    availableWidgets.clear();
    try {
      if (typeof DesktopWidgetRegistry === "undefined" || !DesktopWidgetRegistry) {
        Logger.e("DesktopWidgetsTab", "DesktopWidgetRegistry is not available");
        // Retry after a short delay
        Qt.callLater(function () {
          if (typeof DesktopWidgetRegistry !== "undefined" && DesktopWidgetRegistry) {
            updateAvailableWidgetsModel();
          }
        });
        return;
      }
      widgetIds = DesktopWidgetRegistry.getAvailableWidgets();
      Logger.d("DesktopWidgetsTab", "Found widgets:", widgetIds, "count:", widgetIds ? widgetIds.length : 0);
      if (!widgetIds || widgetIds.length === 0) {
        Logger.w("DesktopWidgetsTab", "No widgets found in registry");
        return;
      }
      for (i = 0; i < widgetIds.length; i++) {
        widgetId = widgetIds[i];
        displayName = widgetId;

        const badges = [];
        if (DesktopWidgetRegistry.isCpuIntensive(widgetId)) {
          badges.push({
                        "icon": "cpu-intensive",
                        "color": Color.mSecondary
                      });
        }

        availableWidgets.append({
                                  "key": widgetId,
                                  "name": displayName,
                                  "badges": badges
                                });
      }
      Logger.d("DesktopWidgetsTab", "Available widgets model count:", availableWidgets.count);
    } catch (e) {
      Logger.e("DesktopWidgetsTab", "Error updating available widgets:", e, e.stack);
    }
  }

  // Get widgets for a specific monitor
  function getWidgetsForMonitor(monitorName) {
    var i;
    var monitorWidgets = Settings.data.desktopWidgets.monitorWidgets || [];
    for (i = 0; i < monitorWidgets.length; i++) {
      if (monitorWidgets[i].name === monitorName) {
        return monitorWidgets[i].widgets || [];
      }
    }
    return [];
  }

  // Set widgets for a specific monitor
  function setWidgetsForMonitor(monitorName, widgets) {
    var i;
    var monitorWidgets = Settings.data.desktopWidgets.monitorWidgets || [];
    var newMonitorWidgets = monitorWidgets.slice();
    var found = false;
    for (i = 0; i < newMonitorWidgets.length; i++) {
      if (newMonitorWidgets[i].name === monitorName) {
        newMonitorWidgets[i] = {
          "name": monitorName,
          "widgets": widgets
        };
        found = true;
        break;
      }
    }
    if (!found) {
      newMonitorWidgets.push({
                               "name": monitorName,
                               "widgets": widgets
                             });
    }
    Settings.data.desktopWidgets.monitorWidgets = newMonitorWidgets;
  }

  function _addWidgetToMonitor(monitorName, widgetId) {
    var metadata;
    var newWidget = {
      "id": widgetId
    };
    if (DesktopWidgetRegistry.widgetHasUserSettings(widgetId)) {
      metadata = DesktopWidgetRegistry.widgetMetadata[widgetId];
      if (metadata) {
        Object.keys(metadata).forEach(function (key) {
          newWidget[key] = metadata[key];
        });
      }
    }
    // Set default positions
    if (widgetId === "Clock") {
      newWidget.x = 50;
      newWidget.y = 50;
    } else if (widgetId === "MediaPlayer") {
      newWidget.x = 100;
      newWidget.y = 200;
    } else if (widgetId === "Weather") {
      newWidget.x = 100;
      newWidget.y = 300;
    } else {
      // Default position for other widgets
      newWidget.x = 150;
      newWidget.y = 150;
    }
    var widgets = getWidgetsForMonitor(monitorName).slice();
    widgets.push(newWidget);
    setWidgetsForMonitor(monitorName, widgets);
  }

  function _removeWidgetFromMonitor(monitorName, index) {
    var newArray;
    var widgets = getWidgetsForMonitor(monitorName);
    if (index >= 0 && index < widgets.length) {
      newArray = widgets.slice();
      newArray.splice(index, 1);
      setWidgetsForMonitor(monitorName, newArray);
    }
  }

  function _updateWidgetSettingsForMonitor(monitorName, index, settings) {
    var newArray;
    var widgets = getWidgetsForMonitor(monitorName);
    if (index >= 0 && index < widgets.length) {
      newArray = widgets.slice();
      newArray[index] = Object.assign({}, newArray[index], settings);
      setWidgetsForMonitor(monitorName, newArray);
    }
  }

  function _moveWidgetToMonitor(fromMonitor, index, toMonitor) {
    Logger.i("DesktopWidgetsTab", "Moving widget from", fromMonitor, "index", index, "to", toMonitor);
    var sourceWidgets = getWidgetsForMonitor(fromMonitor);
    if (index < 0 || index >= sourceWidgets.length) {
      Logger.e("DesktopWidgetsTab", "Invalid index", index, "for monitor", fromMonitor);
      return;
    }

    // Get the widget to move
    var newSourceWidgets = sourceWidgets.slice();
    var widget = Object.assign({}, newSourceWidgets.splice(index, 1)[0]);

    // Reset position and scale to ensure widget is accessible on new screen
    widget.x = 100;
    widget.y = 100;
    widget.scale = 1.0;

    // Add to destination monitor
    var destWidgets = getWidgetsForMonitor(toMonitor).slice();
    destWidgets.push(widget);

    // Update both monitors
    setWidgetsForMonitor(fromMonitor, newSourceWidgets);
    setWidgetsForMonitor(toMonitor, destWidgets);
  }
}
