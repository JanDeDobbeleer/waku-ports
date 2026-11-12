.pragma library

function getPillDirection(widgetInstance, Logger) {
    try {
      if (widgetInstance.section === "left") {
        return false;
      } else if (widgetInstance.section === "right") {
        return true;
      } else {
        // middle section
        if (widgetInstance.sectionWidgetIndex < widgetInstance.sectionWidgetsCount / 2) {
          return true;
        } else {
          return false;
        }
      }
    } catch (e) {
      Logger.e(e);
    }
    return true;
}

function closeExistingDialogs(popupMenuWindow) {
    var child, i;
    if (!popupMenuWindow || !popupMenuWindow.dialogParent)
      return;

    var dialogParent = popupMenuWindow.dialogParent;
    for (i = dialogParent.children.length - 1; i >= 0; i--) {
      child = dialogParent.children[i];
      if (child && typeof child.close === "function") {
        child.close();
      }
    }
    popupMenuWindow.hasDialog = false;
}

function openWidgetSettings(component, popupMenuWindow, screen, section, index, widgetId, widgetData, Settings, Logger, readyStatus, errorStatus) {
    function instantiateAndOpen() {
      // Use dialogParent (Item) instead of window directly for proper Popup anchoring
      var dialog = component.createObject(popupMenuWindow.dialogParent, {
                                            "widgetIndex": index,
                                            "widgetData": widgetData,
                                            "widgetId": widgetId,
                                            "sectionId": section,
                                            "screen": screen
                                          });

      if (dialog) {
        dialog.updateWidgetSettings.connect((sec, idx, settings) => {
          var overrideWidgets, widgets;
                                              var screenName = screen?.name || "";
                                              if (Settings.hasScreenOverride(screenName, "widgets")) {
                                                overrideWidgets = Settings.getBarWidgetsForScreen(screenName);
                                                if (overrideWidgets && overrideWidgets[sec] && idx < overrideWidgets[sec].length) {
                                                  overrideWidgets[sec][idx] = Object.assign({}, overrideWidgets[sec][idx], settings);
                                                  Settings.setScreenOverride(screenName, "widgets", overrideWidgets);
                                                }
                                              } else {
                                                widgets = Settings.data.bar.widgets[sec];
                                                if (widgets && idx < widgets.length) {
                                                  widgets[idx] = Object.assign({}, widgets[idx], settings);
                                                  Settings.data.bar.widgets[sec] = widgets;
                                                  Settings.saveImmediate();
                                                }
                                              }
                                            });
        // Enable keyboard focus for the popup menu window when dialog is open
        popupMenuWindow.hasDialog = true;
        // Close the popup menu window when dialog closes
        dialog.closed.connect(() => {
                                popupMenuWindow.hasDialog = false;
                                popupMenuWindow.close();
                                dialog.destroy();
                              });
        // Show the popup menu window and open the dialog
        popupMenuWindow.open();
        dialog.open();
      } else {
        Logger.e("BarService", "Failed to create widget settings dialog");
      }
    }

    if (component.status === readyStatus) {
      instantiateAndOpen();
    } else if (component.status === errorStatus) {
      Logger.e("BarService", "Error loading widget settings dialog:", component.errorString());
    } else {
      component.statusChanged.connect(function () {
        if (component.status === readyStatus) {
          instantiateAndOpen();
        } else if (component.status === errorStatus) {
          Logger.e("BarService", "Error loading widget settings dialog:", component.errorString());
        }
      });
    }
}

function lookupWidget(widgetInstances, widgetId, screenName = null, section = null, index = null) {
    var key;
    var widget;
    // If looking for a specific instance
    if (screenName && section !== null) {
      for (key in widgetInstances) {
        widget = widgetInstances[key];
        if (!widget)
          continue;
        if (widget.widgetId === widgetId && widget.screenName === screenName && widget.section === section) {
          if (index === null) {
            return widget.instance;
          } else if (widget.index == index) {
            return widget.instance;
          }
        }
      }
    }

    // Return first match if no specific screen/section specified
    for (key in widgetInstances) {
      widget = widgetInstances[key];
      if (!widget)
        continue;
      if (widget.widgetId === widgetId) {
        if (!screenName || widget.screenName === screenName) {
          if (section === null || widget.section === section) {
            return widget.instance;
          }
        }
      }
    }

    return undefined;
}

function getAllWidgetInstances(widgetInstances, widgetId = null, screenName = null, section = null) {
    var key;
    var matches, widget;
    var instances = [];

    for (key in widgetInstances) {
      widget = widgetInstances[key];
      if (!widget)
        continue;

      matches = true;
      if (widgetId && widget.widgetId !== widgetId)
        matches = false;
      if (screenName && widget.screenName !== screenName)
        matches = false;
      if (section !== null && widget.section !== section)
        matches = false;

      if (matches) {
        instances.push(widget.instance);
      }
    }

    return instances;
}

function getWidgetWithMetadata(widgetInstances, widgetId, screenName = null, section = null) {
    var key;
    var widget;
    for (key in widgetInstances) {
      widget = widgetInstances[key];
      if (!widget)
        continue;
      if (widget.widgetId === widgetId) {
        if (!screenName || widget.screenName === screenName) {
          if (section === null || widget.section === section) {
            return widget;
          }
        }
      }
    }
    return undefined;
}

function getWidgetsBySection(widgetInstances, section, screenName = null) {
    var key;
    var widget;
    var widgetEntries = [];

    for (key in widgetInstances) {
      widget = widgetInstances[key];
      if (!widget)
        continue;
      if (widget.section === section) {
        if (!screenName || widget.screenName === screenName) {
          widgetEntries.push(widget);
        }
      }
    }

    // Sort by index to maintain order
    widgetEntries.sort(function (a, b) {
      return (a.index || 0) - (b.index || 0);
    });

    // Return just the instances
    return widgetEntries.map(function (w) {
      return w.instance;
    });
}

function getAllRegisteredWidgets(widgetInstances) {
    var key;
    var widget;
    var result = [];
    for (key in widgetInstances) {
      widget = widgetInstances[key];
      if (!widget)
        continue;
      result.push({
                    "key": key,
                    "widgetId": widget.widgetId,
                    "section": widget.section,
                    "screenName": widget.screenName,
                    "index": widget.index
                  });
    }
    return result;
}

function hasWidget(widgetInstances, widgetId, section = null, screenName = null) {
    var key;
    var widget;
    for (key in widgetInstances) {
      widget = widgetInstances[key];
      if (!widget)
        continue;
      if (widget.widgetId === widgetId) {
        if (section === null || widget.section === section) {
          if (!screenName || widget.screenName === screenName) {
            return true;
          }
        }
      }
    }
    return false;
}

function unregisterWidget(widgetInstances, key) {
  delete widgetInstances[key];
}

function onWorkspaceChanged(root, Settings, CompositorService, Logger, workspaceDebounceTimer) {
      if (!Settings.data.bar.showOnWorkspaceSwitch)
        return;
      if (Settings.data.bar.displayMode !== "auto_hide")
        return;

      var ws = CompositorService.getCurrentWorkspace();
      if (!ws || !ws.output) {
        return;
      }

      // Only trigger if workspace actually changed
      var currentWsId = ws.id;
      if (currentWsId === root.lastWorkspaceId) {
        return;
      }
      root.lastWorkspaceId = currentWsId;

      var screenName = ws.output || "";
      Logger.d("BarService", "Workspace switched to:", currentWsId, "on screen:", screenName);

      // Debounce: rapid switches (e.g. external monitor ↔ laptop) cause overlapping
      // bar load/unload; 80ms delay coalesces them and reduces QV4 incubation races
      root._pendingWorkspaceScreen = screenName;
      workspaceDebounceTimer.restart();
}

function getOrCreateAutoHideState(root, Settings, screenName) {
  if (!root.screenAutoHideState[screenName]) {
    root.screenAutoHideState[screenName] = {
      "hovered": false,
      "hidden": Settings.getBarDisplayModeForScreen(screenName) === "auto_hide"
    };
  }
  return root.screenAutoHideState[screenName];
}

function setAutoHideState(root, Settings, screenName, field, value) {
  var state = getOrCreateAutoHideState(root, Settings, screenName);
  if (state[field] !== value) {
    state[field] = value;
    root.screenAutoHideState = Object.assign({}, root.screenAutoHideState);
    if (field === "hovered")
      root.barHoverStateChanged(screenName, value);
    else
      root.barAutoHideStateChanged(screenName, value);
  }
}
