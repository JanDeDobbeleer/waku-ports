pragma Singleton

import "DesktopWidgetRegistryUtils.js" as RegistryUtils

import QtQuick 6.10
import Quickshell
import qs.Commons
import qs.Modules.DesktopWidgets.Widgets
import qs.compat

Singleton {
  id: root

  // Transient state - not persisted, resets on shell restart
  property bool editMode: false

  // Component definitions
  property Component clockComponent: Component {
    DesktopClock {}
  }
  property Component mediaPlayerComponent: Component {
    DesktopMediaPlayer {}
  }
  property Component weatherComponent: Component {
    DesktopWeather {}
  }
  property Component systemStatComponent: Component {
    DesktopSystemStat {}
  }

  // Widget registry object mapping widget names to components
  // Created in Component.onCompleted to ensure Components are ready
  property var widgets: ({})

  // Explicit URLs for core widgets. Inline Component.url returns the parent
  // file's URL, so we need these for Loader.setSource() with initial properties.
  readonly property string _widgetsDir: ShellUrl.dir + "/modules/qs/Modules/DesktopWidgets/Widgets/"
  property var widgetUrls: ({})

  Component.onCompleted: {
    // Initialize widgets object after Components are ready
    var widgetsObj = {};
    widgetsObj["Clock"] = clockComponent;
    widgetsObj["MediaPlayer"] = mediaPlayerComponent;
    widgetsObj["Weather"] = weatherComponent;
    widgetsObj["SystemStat"] = systemStatComponent;
    widgets = widgetsObj;

    var urlsObj = {};
    urlsObj["Clock"] = _widgetsDir + "DesktopClock.qml";
    urlsObj["MediaPlayer"] = _widgetsDir + "DesktopMediaPlayer.qml";
    urlsObj["Weather"] = _widgetsDir + "DesktopWeather.qml";
    urlsObj["SystemStat"] = _widgetsDir + "DesktopSystemStat.qml";
    widgetUrls = urlsObj;

    Logger.i("DesktopWidgetRegistry", "Service started");
  }

  property var widgetSettingsMap: ({
                                     "Clock": "WidgetSettings/ClockSettings.qml",
                                     "MediaPlayer": "WidgetSettings/MediaPlayerSettings.qml",
                                     "Weather": "WidgetSettings/WeatherSettings.qml",
                                     "SystemStat": "WidgetSettings/SystemStatSettings.qml"
                                   })

  property var widgetMetadata: ({
                                  "Clock": {
                                    "showBackground": true,
                                    "roundedCorners": true,
                                    "clockStyle": "digital",
                                    "clockColor": "none",
                                    "useCustomFont": false,
                                    "customFont": "",
                                    "format": "HH:mm\\nd MMMM yyyy"
                                  },
                                  "MediaPlayer": {
                                    "showBackground": true,
                                    "roundedCorners": true,
                                    "visualizerType": "linear",
                                    "hideMode": "visible",
                                    "showButtons": true,
                                    "showAlbumArt": true,
                                    "showVisualizer": false
                                  },
                                  "Weather": {
                                    "showBackground": true,
                                    "roundedCorners": true
                                  },
                                  "SystemStat": {
                                    "showBackground": true,
                                    "roundedCorners": true,
                                    "statType": "CPU",
                                    "diskPath": "/",
                                    "layout": "bottom"
                                  }
                                })

  property var cpuIntensiveWidgets: ["SystemStat"]

  function init() {
    Logger.i("DesktopWidgetRegistry", "Service started");
  }

  // Helper function to get widget component by name
  function getWidget(id: var): Component {
    return widgets[id] || null;
  }

  // Helper function to check if widget exists
  function hasWidget(id: var): bool {
    return id in widgets;
  }

  // Get list of available widget ids
  function getAvailableWidgets(): var {
    var keys = Object.keys(widgets);
    Logger.d("DesktopWidgetRegistry", "getAvailableWidgets() called, returning:", keys);
    return keys;
  }

  // Helper function to check if widget has user settings
  function widgetHasUserSettings(id: var): bool {
    return widgetMetadata[id] !== undefined;
  }

  function isCpuIntensive(id: var): bool {
    return cpuIntensiveWidgets.indexOf(id) >= 0;
  }

  // Get display name for a widget ID
  function getWidgetDisplayName(widgetId: var): var {
    // Widgets are returned as-is (Clock, MediaPlayer, Weather, SystemStat)
    return widgetId;
  }

  function updateWidgetData(monitorName: var, widgetIndex: var, properties: var): void {
    var i, widgets;
    if (widgetIndex < 0 || !monitorName) {
      return;
    }

    var monitorWidgets = Settings.data.desktopWidgets.monitorWidgets || [];
    var newMonitorWidgets = monitorWidgets.slice();

    for (i = 0; i < newMonitorWidgets.length; i++) {
      if (newMonitorWidgets[i].name === monitorName) {
        widgets = (newMonitorWidgets[i].widgets || []).slice();
        if (widgetIndex < widgets.length) {
          widgets[widgetIndex] = Object.assign({}, widgets[widgetIndex], properties);
          newMonitorWidgets[i] = Object.assign({}, newMonitorWidgets[i], {
                                                 "widgets": widgets
                                               });
          Settings.data.desktopWidgets.monitorWidgets = newMonitorWidgets;
        }
        break;
      }
    }
  }

  property var currentSettingsDialog: null

  function openWidgetSettings(screen: var, widgetIndex: var, widgetId: var, widgetData: var): void {
    var popupMenuWindow = RegistryUtils.prepare(root, screen, widgetId, PanelService, Logger);
    if (!popupMenuWindow)
      return;

    var component = Qt.createComponent(ShellUrl.dir + "/modules/qs/Modules/Panels/Settings/DesktopWidgets/DesktopWidgetSettingsDialog.qml");

    RegistryUtils.open(root, component, popupMenuWindow, screen, widgetIndex, widgetId, widgetData, Component.Ready, Component.Error, Logger);
  }
}
