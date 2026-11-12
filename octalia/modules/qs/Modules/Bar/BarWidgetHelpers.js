.pragma library

function hasProperty(object, name) {
  return object !== null && object !== undefined && object.hasOwnProperty(name);
}

function readProperty(object, name) {
  return object[name];
}

function callWithTwoArguments(object, name, first, second) {
  return object[name](first, second);
}

function workspaceLabel(workspace, labelMode, isVertical, characterCount) {
  if (workspace.name && workspace.name.length > 0) {
    if (labelMode === "name")
      return workspace.name.substring(0, characterCount);
    if (labelMode === "index+name") {
      if (isVertical)
        return workspace.idx.toString() + workspace.name.substring(0, 1);
      return workspace.idx.toString() + " " + workspace.name.substring(0, characterCount);
    }
  }
  return workspace.idx.toString();
}

function getProperty(object, name) {
  return object === null || object === undefined ? undefined : object[name];
}

function callIfFunction(object, name) {
  if (object && typeof object[name] === "function")
    object[name]();
}

function callProperty(object, name) {
  if (hasProperty(object, name))
    object[name]();
}
function getActiveWindowIcon(compositor, toplevelManager, themeIcons, fallbackIcon, logger) {
  try {
    var focusedWindow = compositor.getFocusedWindow();
    if (focusedWindow && focusedWindow.appId) {
      try {
        var idValue = focusedWindow.appId;
        var normalizedId = typeof idValue === "string" ? idValue : String(idValue);
        var iconResult = themeIcons.iconForAppId(normalizedId.toLowerCase());
        if (iconResult && iconResult !== "")
          return iconResult;
      } catch (iconError) {
        logger.w("ActiveWindow", "Error getting icon from CompositorService:", iconError);
      }
    }
    if (compositor.isHyprland && toplevelManager && toplevelManager.activeToplevel) {
      try {
        var activeToplevel = toplevelManager.activeToplevel;
        if (activeToplevel.appId) {
          var idValue2 = activeToplevel.appId;
          var normalizedId2 = typeof idValue2 === "string" ? idValue2 : String(idValue2);
          var iconResult2 = themeIcons.iconForAppId(normalizedId2.toLowerCase());
          if (iconResult2 && iconResult2 !== "")
            return iconResult2;
        }
      } catch (fallbackError) {
        logger.w("ActiveWindow", "Error getting icon from ToplevelManager:", fallbackError);
      }
    }
    return themeIcons.iconFromName(fallbackIcon);
  } catch (error) {
    logger.w("ActiveWindow", "Error in getAppIcon:", error);
    return themeIcons.iconFromName(fallbackIcon);
  }
}

function wildcardMatch(str, rule, logger) {
  if (!str || !rule)
    return false;
  var placeholder = "\uE000";
  var processedRule = rule.replace(/\*/g, placeholder);
  var escapedRule = processedRule.replace(/[.+?^${}()|[\]\\]/g, "\\$&");
  var pattern = "^" + escapedRule.replace(new RegExp(placeholder, "g"), ".*") + "$";
  try {
    return new RegExp(pattern, "i").test(str);
  } catch (error) {
    logger.w("Tray", "Invalid regex pattern for wildcard match:", rule, error.message);
    return false;
  }
}

function runCustomCommand(Qt, parent, command, toastService, i18n, logger) {
  if (!command || command.trim() === "")
    return;
  var processString = "import QtQuick; import Quickshell.Io; Process { command: [\"sh\", \"-lc\", \"\"] }";
  try {
    var processObj = Qt.createQmlObject(processString, parent, "BarCommandProcess_" + Date.now());
    processObj.command = ["cmd", "/c", command];
    processObj.exited.connect(function (exitCode) {
      if (exitCode !== 0) {
        toastService.showError(i18n.tr("toast.custom-command-failed.title"), i18n.trArgs("toast.custom-command-failed.description", {
          command: command,
          code: exitCode
        }));
      }
      processObj.destroy();
    });
    processObj.running = true;
  } catch (error) {
    logger.e("Bar", "Failed to start custom command:", error);
    toastService.showError(i18n.tr("toast.custom-command-failed.title"), i18n.trArgs("toast.custom-command-failed.description", {
      command: command,
      code: "start_error"
    }));
  }
}
function updateWindowIcons(windowIcon, verticalIcon, Qt, getIcon, logger, eventName) {
  try {
    windowIcon.source = Qt.binding(getIcon);
    verticalIcon.source = Qt.binding(getIcon);
  } catch (error) {
    logger.w("ActiveWindow", "Error in " + eventName + ":", error);
  }
}
function optionalProperty(object, name) {
  return object?.[name];
}

function lowerCaseAppId(object) {
  return object?.appId?.toLowerCase();
}

function writeProperty(object, name, value) {
  object[name] = value;
}

function firstChild(item) {
  return item?.children[0] || null;
}

function includesScreen(monitors, screenName) {
  return monitors.length === 0 || monitors.includes(screenName);
}

function syncWidgetModel(model, validWidgets, logger) {
  var currentIds = [];
  for (var i = 0; i < model.count; i++)
    currentIds.push(model.get(i).id);
  var newIds = validWidgets.map(function (w) { return w.id; });
  var structureChanged = currentIds.length !== newIds.length;
  if (!structureChanged) {
    for (i = 0; i < currentIds.length; i++) {
      if (currentIds[i] !== newIds[i]) {
        structureChanged = true;
        break;
      }
    }
  }
  logger.d("Bar", "syncWidgetModel:", currentIds.join("|"), "→", newIds.join("|"), "changed:", structureChanged);
  if (structureChanged) {
    model.clear();
    for (i = 0; i < validWidgets.length; i++)
      model.append(validWidgets[i]);
  }
}

function switchWorkspaceByOffset(compositor, screen, wrap, offset) {
  if (!screen || compositor.workspaces.count === 0)
    return;
  var screenName = screen.name.toLowerCase();
  var candidates = [];
  for (var i = 0; i < compositor.workspaces.count; i++) {
    var ws = compositor.workspaces.get(i);
    var matchesScreen = compositor.globalWorkspaces || (ws.output && ws.output.toLowerCase() === screenName);
    if (matchesScreen)
      candidates.push(ws);
  }
  if (candidates.length <= 1)
    return;
  var current = -1;
  for (var j = 0; j < candidates.length; j++) {
    if (candidates[j].isFocused) {
      current = j;
      break;
    }
  }
  if (current < 0)
    current = 0;
  var next = current + offset;
  if (wrap) {
    next = next % candidates.length;
    if (next < 0)
      next = candidates.length - 1;
  } else if (next < 0 || next >= candidates.length) {
    return;
  }
  if (next !== current)
    compositor.switchToWorkspace(candidates[next]);
}

function countControllableMonitors(monitors) {
  var count = 0;
  for (var i = 0; i < monitors.length; i++) {
    if (monitors[i] && monitors[i].brightnessControlAvailable)
      count++;
  }
  return count;
}

function unreadNotificationCount(model, since) {
  var count = 0;
  for (var i = 0; i < model.count; i++) {
    var item = model.get(i);
    var ts = item.timestamp instanceof Date ? item.timestamp.getTime() : item.timestamp;
    if (ts > since)
      count++;
  }
  return count;
}

function toggleIfPresent(object, argument) {
  if (object !== null && object !== undefined)
    object.toggle(argument);
}

function triggerWidgetInSection(barService, sectionName, screenName, reverse) {
  var widgets = barService.getWidgetsBySection(sectionName, screenName);
  for (var i = reverse ? widgets.length - 1 : 0; reverse ? i >= 0 : i < widgets.length; reverse ? i-- : i++) {
    var widget = widgets[i];
    if (widget && widget.visible && widget.widgetId !== "Spacer") {
      if (typeof widget.clicked === "function")
        widget.clicked();
      return;
    }
  }
}

function syncFromSettings(root, settings, screenName) {
  var widgets = settings.getBarWidgetsForScreen(screenName);
  if (widgets) {
    root.syncWidgetModel(root.leftWidgetsModel, widgets.left);
    root.syncWidgetModel(root.centerWidgetsModel, widgets.center);
    root.syncWidgetModel(root.rightWidgetsModel, widgets.right);
  }
}

function isPointOverWidget(bar, root, barService, margin, x, y) {
  var widgets = barService.getAllWidgetInstances(null, root.screen.name);
  for (var i = 0; i < widgets.length; i++) {
    var widget = widgets[i];
    if (!widget || !widget.visible || widget.widgetId === "Spacer")
      continue;
    var local = bar.mapToItem(widget, x, y);
    if (root.barIsVertical) {
      if (local.y >= -margin && local.y <= widget.height + margin)
        return true;
    } else if (local.x >= -margin && local.x <= widget.width + margin) {
      return true;
    }
  }
  return false;
}

function togglePanel(panel, buttonItem, buttonName) {
  panel.toggle(buttonItem, buttonName);
}
