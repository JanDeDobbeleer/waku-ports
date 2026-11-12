import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Octalia
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: 0

  // Helper functions to update arrays immutably
  function addMonitor(list, name) {
    const arr = (list || []).slice();
    if (!arr.includes(name))
      arr.push(name);
    return arr;
  }
  function removeMonitor(list, name) {
    return (list || []).filter(function (n) {
      return n !== name;
    });
  }

  // Signal functions for widgets sub-tab (global widgets only).
  // These intentionally edit Settings.data.bar.widgets (global defaults),
  // not per-screen overrides. Per-screen editing is handled by MonitorWidgetsConfig.qml.
  function _addWidgetToSection(widgetId, section) {
    var metadata;
    var newWidget = {
      "id": widgetId
    };
    if (BarWidgetRegistry.widgetHasUserSettings(widgetId)) {
      metadata = BarWidgetRegistry.widgetMetadata[widgetId];
      if (metadata) {
        Object.keys(metadata).forEach(function (key) {
          newWidget[key] = metadata[key];
        });
      }
    }
    Settings.data.bar.widgets[section].push(newWidget);
    BarService.widgetsRevision++;
  }

  function _removeWidgetFromSection(section, index) {
    var newArray, removedWidgets;
    var widgets = Settings.data.bar.widgets;
    if (index >= 0 && index < widgets[section].length) {
      newArray = widgets[section].slice();
      removedWidgets = newArray.splice(index, 1);
      widgets[section] = newArray;
      BarService.widgetsRevision++;

      if (removedWidgets[0].id === "ControlCenter" && BarService.lookupWidget("ControlCenter") === undefined) {
        ToastService.showWarning(I18n.tr("toast.missing-control-center.label"), I18n.tr("toast.missing-control-center.description"), 6000);
      }
    }
  }

  function _reorderWidgetInSection(section, fromIndex, toIndex) {
    var item, newArray;
    var widgets = Settings.data.bar.widgets;
    if (fromIndex >= 0 && fromIndex < widgets[section].length && toIndex >= 0 && toIndex < widgets[section].length) {
      newArray = widgets[section].slice();
      item = newArray[fromIndex];
      newArray.splice(fromIndex, 1);
      newArray.splice(toIndex, 0, item);
      widgets[section] = newArray;
      BarService.widgetsRevision++;
    }
  }

  // Note: _updateWidgetSettingsInSection does NOT increment revision
  // because it only changes settings, not widget structure
  function _updateWidgetSettingsInSection(section, index, settings) {
    Settings.data.bar.widgets[section][index] = settings;
  }

  function _moveWidgetBetweenSections(fromSection, index, toSection) {
    var sourceArray, targetArray, widget;
    var widgets = Settings.data.bar.widgets;
    if (index >= 0 && index < widgets[fromSection].length) {
      widget = widgets[fromSection][index];
      sourceArray = widgets[fromSection].slice();
      sourceArray.splice(index, 1);
      widgets[fromSection] = sourceArray;
      targetArray = widgets[toSection].slice();
      targetArray.push(widget);
      widgets[toSection] = targetArray;
      BarService.widgetsRevision++;
      Logger.d("BarTab", "_moveWidgetBetweenSections: revision now", BarService.widgetsRevision);
    }
  }

  function getWidgetLocations(widgetId) {
    var i;
    if (!BarService)
      return [];
    const instances = BarService.getAllRegisteredWidgets();
    const locations = {};
    for (i = 0; i < instances.length; i++) {
      if (instances[i].widgetId === widgetId) {
        const section = instances[i].section;
        if (section === "left")
          locations["arrow-bar-to-left"] = true;
        else if (section === "center")
          locations["layout-columns"] = true;
        else if (section === "right")
          locations["arrow-bar-to-right"] = true;
      }
    }
    return Object.keys(locations);
  }

  function createBadges(locations) {
    const badges = [];
    locations.forEach(function (location) {
      badges.push({
                    "icon": location,
                    "color": Color.mOnSurfaceVariant
                  });
    });
    return badges;
  }

  function updateAvailableWidgetsModel() {
    availableWidgets.clear();
    const widgets = BarWidgetRegistry.getAvailableWidgets();
    widgets.forEach(entry => {
                      const displayName = entry;
                      availableWidgets.append({
                                                "key": entry,
                                                "name": displayName,
                                                "badges": createBadges(getWidgetLocations(entry))
                                              });
                    });
  }

  ListModel {
    id: availableWidgets
  }

  Component.onCompleted: {
    Qt.callLater(updateAvailableWidgetsModel);
  }

  Connections {
    target: BarService
    function onActiveWidgetsChanged() {
      updateAvailableWidgetsModel();
    }
  }

  NTabBar {
    id: subTabBar
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    NTabButton {
      text: I18n.tr("common.appearance")
      tabIndex: 0
      checked: subTabBar.currentIndex === 0
    }
    NTabButton {
      text: I18n.tr("common.widgets")
      tabIndex: 1
      checked: subTabBar.currentIndex === 1
    }
    NTabButton {
      text: I18n.tr("common.behavior")
      tabIndex: 2
      checked: subTabBar.currentIndex === 2
    }
    NTabButton {
      text: I18n.tr("common.monitors")
      tabIndex: 3
      checked: subTabBar.currentIndex === 3
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: Style.marginS
  }

  NTabView {
    id: tabView
    currentIndex: subTabBar.currentIndex

    AppearanceSubTab {}
    WidgetsSubTab {
      availableWidgets: availableWidgets
      addWidgetToSection: root._addWidgetToSection
      removeWidgetFromSection: root._removeWidgetFromSection
      reorderWidgetInSection: root._reorderWidgetInSection
      updateWidgetSettingsInSection: root._updateWidgetSettingsInSection
      moveWidgetBetweenSections: root._moveWidgetBetweenSections
    }
    BehaviorSubTab {}
    MonitorsSubTab {
      addMonitor: root.addMonitor
      removeMonitor: root.removeMonitor
    }
  }
}
