.pragma library

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

function registerButton(button, registry, Logger) {
    if (!button || !button.ipcIdentifier) {
      Logger.w("CustomButtonIPCService", "Cannot register button without ipcIdentifier");
      return false;
    }

    registry[button.ipcIdentifier] = button;
    Logger.d("CustomButtonIPCService", `Registered button with identifier: ${button.ipcIdentifier}`);
    return true;
}

function unregisterButton(button, registry, Logger) {
    if (!button || !button.ipcIdentifier) {
      return false;
    }

    if (registry[button.ipcIdentifier] === button) {
      delete registry[button.ipcIdentifier];
      Logger.d("CustomButtonIPCService", `Unregistered button with identifier: ${button.ipcIdentifier}`);
      return true;
    }
    return false;
}

function resolveCommand(config, prop, BarWidgetRegistry) {
    if (config[prop])
      return config[prop];
    var meta = BarWidgetRegistry.widgetMetadata["CustomButton"];
    return meta ? (meta[prop] || "") : "";
}

function left(identifier, root, Logger, Quickshell) {
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

function right(identifier, root, Logger, Quickshell) {
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

function middle(identifier, root, Logger, Quickshell) {
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

function up(identifier, root, Logger, BarWidgetRegistry, Quickshell) {
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

function down(identifier, root, Logger, BarWidgetRegistry, Quickshell) {
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

function wheel(identifier, root, Logger, BarWidgetRegistry, Quickshell) {
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

function refresh(identifier, root, Logger) {
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
