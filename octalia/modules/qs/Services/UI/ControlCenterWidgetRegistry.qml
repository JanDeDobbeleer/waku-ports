pragma Singleton

import QtQuick 6.10
import Quickshell
import qs.Commons
import qs.Modules.Panels.ControlCenter.Widgets

Singleton {
  id: root

  // Widget registry object mapping widget names to components
  property var widgets: ({
                           "Bluetooth": bluetoothComponent,
                           "CustomButton": customButtonComponent,
                           "DarkMode": darkModeComponent,
                           "KeepAwake": keepAwakeComponent,
                           "Notifications": notificationsComponent,
                           "PowerProfile": powerProfileComponent,
                           "WiFi": networkComponent,
                           "Network": networkComponent,
                           "OctaliaPerformance": octaliaPerformanceComponent,
                           "WallpaperSelector": wallpaperSelectorComponent
                         })

  property var widgetMetadata: ({
                                  "CustomButton": {
                                    "icon": "heart",
                                    "onClicked": "",
                                    "onRightClicked": "",
                                    "onMiddleClicked": "",
                                    "stateChecksJson": "[]",
                                    "enableOnStateLogic": false
                                  }
                                })

  property var cpuIntensiveWidgets: ["SystemStat"]

  // Component definitions - these are loaded once at startup
  property Component bluetoothComponent: Component {
    Bluetooth {}
  }
  property Component customButtonComponent: Component {
    CustomButton {}
  }
  property Component darkModeComponent: Component {
    DarkMode {}
  }
  property Component keepAwakeComponent: Component {
    KeepAwake {}
  }
  property Component notificationsComponent: Component {
    Notifications {}
  }
  property Component powerProfileComponent: Component {
    PowerProfile {}
  }
  property Component networkComponent: Component {
    Network {}
  }
  property Component octaliaPerformanceComponent: Component {
    OctaliaPerformance {}
  }
  property Component wallpaperSelectorComponent: Component {
    WallpaperSelector {}
  }

  function init() {
    Logger.i("ControlCenterWidgetRegistry", "Service started");
  }

  // ------------------------------
  // Helper function to get widget component by name
  function getWidget(id: var): Component {
    return widgets[id] || null;
  }

  // Helper function to check if widget exists
  function hasWidget(id: var): bool {
    return id in widgets;
  }

  // Get list of available widget id
  function getAvailableWidgets(): var {
    return Object.keys(widgets);
  }

  // Helper function to check if widget has user settings
  function widgetHasUserSettings(id: var): bool {
    return widgetMetadata[id] !== undefined;
  }

  function isCpuIntensive(id: var): bool {
    return cpuIntensiveWidgets.indexOf(id) >= 0;
  }
}
