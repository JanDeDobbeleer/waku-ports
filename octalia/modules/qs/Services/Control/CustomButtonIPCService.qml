pragma Singleton

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
  function registerButton(button): bool {
    if (!button || !button.ipcIdentifier) {
      Logger.w("CustomButtonIPCService", "Cannot register button without ipcIdentifier");
      return false;
    }

    customButtonRegistry[button.ipcIdentifier] = button;
    Logger.d("CustomButtonIPCService", `Registered button with identifier: ${button.ipcIdentifier}`);
    return true;
  }

  // Unregister a custom button instance
  function unregisterButton(button): bool {
    if (!button || !button.ipcIdentifier) {
      return false;
    }

    if (customButtonRegistry[button.ipcIdentifier] === button) {
      delete customButtonRegistry[button.ipcIdentifier];
      Logger.d("CustomButtonIPCService", `Unregistered button with identifier: ${button.ipcIdentifier}`);
      return true;
    }
    return false;
  }

  // Find a button by identifier
  function findButton(identifier) {
    return customButtonRegistry[identifier] || null;
  }

  // Find button config from Settings for when the live widget is not loaded
  function findButtonConfig(identifier) {
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

  function _searchWidgetsForIdentifier(widgets, identifier) {
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
  function resolveCommand(config, prop) {
    if (config[prop])
      return config[prop];
    var meta = BarWidgetRegistry.widgetMetadata["CustomButton"];
    return meta ? (meta[prop] || "") : "";
  }

  // Substitute $delta expressions in a command string
  function substituteWheelDelta(command, delta) {
    var normalizedDelta = delta > 0 ? 1 : -1;
    return command.replace(/\$delta([+\-*/]\d+)?/g, function (match, operation) {
      var result;
      var operand, operator;
      if (operation) {
        try {
          operator = operation.charAt(0);
          operand = parseInt(operation.substring(1));

          switch (operator) {
          case '+':
            result = normalizedDelta + operand;
            break;
          case '-':
            result = normalizedDelta - operand;
            break;
          case '*':
            result = normalizedDelta * operand;
            break;
          case '/':
            result = Math.floor(normalizedDelta / operand);
            break;
          default:
            result = normalizedDelta;
          }
          return result.toString();
        } catch (e) {
          return normalizedDelta.toString();
        }
      } else {
        return normalizedDelta.toString();
      }
    });
  }

  // IpcHandler for custom button commands using short alias 'cb'
  IpcHandler {
    target: "cb"

    // Handle left click: cb left "identifier"
    function left(identifier: string) {
      const button = root.findButton(identifier);
      if (button) {
        if (button.leftClickExec || button.textCommand) {
          button.clicked();
          Logger.i("CustomButtonIPCService", `Triggered left click on button '${identifier}'`);
        } else {
          Logger.w("CustomButtonIPCService", `Button '${identifier}' has no left click action configured`);
        }
        return;
      }

      // Fallback: read from Settings
      const config = root.findButtonConfig(identifier);
      if (!config) {
        Logger.w("CustomButtonIPCService", `Button with identifier '${identifier}' not found`);
        return;
      }
      const cmd = root.resolveCommand(config, "leftClickExec");
      if (cmd) {
        Quickshell.execDetached(["cmd", "/c", cmd]);
        Logger.i("CustomButtonIPCService", `Triggered left click on button '${identifier}' (from settings)`);
      } else {
        Logger.w("CustomButtonIPCService", `Button '${identifier}' has no left click action configured`);
      }
    }

    // Handle right click: cb right "identifier"
    function right(identifier: string) {
      const button = root.findButton(identifier);
      if (button) {
        if (button.rightClickExec) {
          button.rightClicked();
          Logger.i("CustomButtonIPCService", `Triggered right click on button '${identifier}'`);
        } else {
          Logger.w("CustomButtonIPCService", `Button '${identifier}' has no right click action configured`);
        }
        return;
      }

      const config = root.findButtonConfig(identifier);
      if (!config) {
        Logger.w("CustomButtonIPCService", `Button with identifier '${identifier}' not found`);
        return;
      }
      const cmd = root.resolveCommand(config, "rightClickExec");
      if (cmd) {
        Quickshell.execDetached(["cmd", "/c", cmd]);
        Logger.i("CustomButtonIPCService", `Triggered right click on button '${identifier}' (from settings)`);
      } else {
        Logger.w("CustomButtonIPCService", `Button '${identifier}' has no right click action configured`);
      }
    }

    // Handle middle click: cb middle "identifier"
    function middle(identifier: string) {
      const button = root.findButton(identifier);
      if (button) {
        if (button.middleClickExec) {
          button.middleClicked();
          Logger.i("CustomButtonIPCService", `Triggered middle click on button '${identifier}'`);
        } else {
          Logger.w("CustomButtonIPCService", `Button '${identifier}' has no middle click action configured`);
        }
        return;
      }

      const config = root.findButtonConfig(identifier);
      if (!config) {
        Logger.w("CustomButtonIPCService", `Button with identifier '${identifier}' not found`);
        return;
      }
      const cmd = root.resolveCommand(config, "middleClickExec");
      if (cmd) {
        Quickshell.execDetached(["cmd", "/c", cmd]);
        Logger.i("CustomButtonIPCService", `Triggered middle click on button '${identifier}' (from settings)`);
      } else {
        Logger.w("CustomButtonIPCService", `Button '${identifier}' has no middle click action configured`);
      }
    }

    // Handle wheel up: cb up "identifier"
    function up(identifier: string) {
      const button = root.findButton(identifier);
      if (button) {
        if (button.wheelMode === "separate" && button.wheelUpExec) {
          button.wheeled(1);
          Logger.i("CustomButtonIPCService", `Triggered wheel up on button '${identifier}'`);
        } else {
          Logger.w("CustomButtonIPCService", `Button '${identifier}' has no separate wheel up action configured or is not in separate mode`);
        }
        return;
      }

      const config = root.findButtonConfig(identifier);
      if (!config) {
        Logger.w("CustomButtonIPCService", `Button with identifier '${identifier}' not found`);
        return;
      }
      const mode = config.wheelMode || BarWidgetRegistry.widgetMetadata["CustomButton"].wheelMode;
      const cmd = root.resolveCommand(config, "wheelUpExec");
      if (mode === "separate" && cmd) {
        const resolved = root.substituteWheelDelta(cmd, 1);
        Quickshell.execDetached(["cmd", "/c", resolved]);
        Logger.i("CustomButtonIPCService", `Triggered wheel up on button '${identifier}' (from settings)`);
      } else {
        Logger.w("CustomButtonIPCService", `Button '${identifier}' has no separate wheel up action configured or is not in separate mode`);
      }
    }

    // Handle wheel down: cb down "identifier"
    function down(identifier: string) {
      const button = root.findButton(identifier);
      if (button) {
        if (button.wheelMode === "separate" && button.wheelDownExec) {
          button.wheeled(-1);
          Logger.i("CustomButtonIPCService", `Triggered wheel down on button '${identifier}'`);
        } else {
          Logger.w("CustomButtonIPCService", `Button '${identifier}' has no separate wheel down action configured or is not in separate mode`);
        }
        return;
      }

      const config = root.findButtonConfig(identifier);
      if (!config) {
        Logger.w("CustomButtonIPCService", `Button with identifier '${identifier}' not found`);
        return;
      }
      const mode = config.wheelMode || BarWidgetRegistry.widgetMetadata["CustomButton"].wheelMode;
      const cmd = root.resolveCommand(config, "wheelDownExec");
      if (mode === "separate" && cmd) {
        const resolved = root.substituteWheelDelta(cmd, -1);
        Quickshell.execDetached(["cmd", "/c", resolved]);
        Logger.i("CustomButtonIPCService", `Triggered wheel down on button '${identifier}' (from settings)`);
      } else {
        Logger.w("CustomButtonIPCService", `Button '${identifier}' has no separate wheel down action configured or is not in separate mode`);
      }
    }

    // Handle wheel action: cb wheel "identifier"
    function wheel(identifier: string) {
      const button = root.findButton(identifier);
      if (button) {
        if (button.wheelMode === "unified" && button.wheelExec) {
          button.wheeled(1);
          Logger.i("CustomButtonIPCService", `Triggered wheel action on button '${identifier}'`);
        } else {
          Logger.w("CustomButtonIPCService", `Button '${identifier}' has no unified wheel action configured or is not in unified mode`);
        }
        return;
      }

      const config = root.findButtonConfig(identifier);
      if (!config) {
        Logger.w("CustomButtonIPCService", `Button with identifier '${identifier}' not found`);
        return;
      }
      const mode = config.wheelMode || BarWidgetRegistry.widgetMetadata["CustomButton"].wheelMode;
      const cmd = root.resolveCommand(config, "wheelExec");
      if (mode === "unified" && cmd) {
        const resolved = root.substituteWheelDelta(cmd, 1);
        Quickshell.execDetached(["cmd", "/c", resolved]);
        Logger.i("CustomButtonIPCService", `Triggered wheel action on button '${identifier}' (from settings)`);
      } else {
        Logger.w("CustomButtonIPCService", `Button '${identifier}' has no unified wheel action configured or is not in unified mode`);
      }
    }

    // Handle refresh: cb refresh "identifier"
    function refresh(identifier: string) {
      const button = root.findButton(identifier);
      if (!button) {
        Logger.w("CustomButtonIPCService", `Button '${identifier}' is not currently loaded — refresh requires a live widget instance`);
        return;
      }

      if (button.textCommand && button.textCommand.length > 0 && !button.textStream) {
        button.runTextCommand();
        Logger.i("CustomButtonIPCService", `Triggered refresh (text command) on button '${identifier}'`);
      } else if (button.textStream) {
        Logger.w("CustomButtonIPCService", `Button '${identifier}' uses streaming, manual refresh disabled`);
      } else {
        Logger.w("CustomButtonIPCService", `Button '${identifier}' has no text command to refresh`);
      }
    }
  }
}
