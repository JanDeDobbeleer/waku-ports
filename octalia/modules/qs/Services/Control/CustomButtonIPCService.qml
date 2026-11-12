pragma Singleton
import "CustomButtonUtils.js" as CustomButtonUtils

import QtQuick 6.10
import Quickshell
import qs.Commons
import qs.Services.UI

Singleton {
  id: root

  // Must be called at startup to force singleton instantiation,
  // which registers the IpcHandler with the IPC system.
  function init() {
    Logger.i("CustomButtonIPCService", "Service started");
  }

  // Registry to store references to active custom buttons by their user-defined identifier
  property var customButtonRegistry: ({})

  // Register a custom button instance
  function registerButton(button: var): bool {
    return CustomButtonUtils.registerButton(button, customButtonRegistry, Logger);
  }

  // Unregister a custom button instance
  function unregisterButton(button: var): bool {
    return CustomButtonUtils.unregisterButton(button, customButtonRegistry, Logger);
  }

  // Find a button by identifier
  function findButton(identifier: var): var {
    return customButtonRegistry[identifier] || null;
  }

  // Find button config from Settings for when the live widget is not loaded
  function findButtonConfig(identifier: var): var {
    var config, i, widgets;
    var screens = Quickshell.screens;
    for (i = 0; i < screens.length; i++) {
      widgets = Settings.getBarWidgetsForScreen(screens[i].name);
      config = _searchWidgetsForIdentifier(widgets, identifier);
      if (config)
        return config;
    }
    // Also check global widgets as a final fallback
    var globalConfig = _searchWidgetsForIdentifier(Settings.data.bar.widgets, identifier);
    if (globalConfig)
      return globalConfig;
    return null;
  }

  function _searchWidgetsForIdentifier(widgets: var, identifier: var): var {
    var j, list, s, w;
    var sections = ["left", "center", "right"];
    for (s = 0; s < sections.length; s++) {
      list = widgets[sections[s]];
      if (!list)
        continue;
      for (j = 0; j < list.length; j++) {
        w = list[j];
        if (w.id === "CustomButton" && w.ipcIdentifier === identifier) {
          return w;
        }
      }
    }
    return null;
  }

  // Resolve a command property from config with fallback to widgetMetadata defaults
  function resolveCommand(config: var, prop: var): var {
    return CustomButtonUtils.resolveCommand(config, prop, BarWidgetRegistry);
  }

  // Substitute $delta expressions in a command string
  function substituteWheelDelta(command: var, delta: var): var {
    return CustomButtonUtils.substituteWheelDelta(command, delta);
  }

  // IpcHandler for custom button commands using short alias 'cb'
  IpcHandler {
    target: "cb"

    // Handle left click: cb left "identifier"
    function left(identifier: string) {
      CustomButtonUtils.left(identifier, root, Logger, Quickshell);
    }

    // Handle right click: cb right "identifier"
    function right(identifier: string) {
      CustomButtonUtils.right(identifier, root, Logger, Quickshell);
    }

    // Handle middle click: cb middle "identifier"
    function middle(identifier: string) {
      CustomButtonUtils.middle(identifier, root, Logger, Quickshell);
    }

    // Handle wheel up: cb up "identifier"
    function up(identifier: string) {
      CustomButtonUtils.up(identifier, root, Logger, BarWidgetRegistry, Quickshell);
    }

    // Handle wheel down: cb down "identifier"
    function down(identifier: string) {
      CustomButtonUtils.down(identifier, root, Logger, BarWidgetRegistry, Quickshell);
    }

    // Handle wheel action: cb wheel "identifier"
    function wheel(identifier: string) {
      CustomButtonUtils.wheel(identifier, root, Logger, BarWidgetRegistry, Quickshell);
    }

    // Handle refresh: cb refresh "identifier"
    function refresh(identifier: string) {
      CustomButtonUtils.refresh(identifier, root, Logger);
    }
  }
}
