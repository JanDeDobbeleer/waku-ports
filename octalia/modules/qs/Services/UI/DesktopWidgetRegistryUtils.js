.pragma library

function prepare(root, screen, widgetId, PanelService, Logger) {
    if (!widgetId || !screen) {
      return null;
    }

    if (root.currentSettingsDialog) {
      root.currentSettingsDialog.close();
      root.currentSettingsDialog.destroy();
      root.currentSettingsDialog = null;
    }

    var hasSettings = root.widgetSettingsMap[widgetId] !== undefined;

    if (!hasSettings) {
      Logger.w("DesktopWidgetRegistry", "Widget does not have settings:", widgetId);
      return null;
    }

    var popupMenuWindow = PanelService.getPopupMenuWindow(screen);
    if (!popupMenuWindow) {
      Logger.e("DesktopWidgetRegistry", "No popup menu window found for screen");
      return null;
    }

    if (popupMenuWindow.hideDynamicMenu) {
      popupMenuWindow.hideDynamicMenu();
    }

    return popupMenuWindow;
}

function open(root, component, popupMenuWindow, screen, widgetIndex, widgetId, widgetData, ready, error, Logger) {
    function instantiateAndOpen() {
      var dialog = component.createObject(popupMenuWindow.dialogParent, {
                                            "widgetIndex": widgetIndex,
                                            "widgetData": widgetData,
                                            "widgetId": widgetId,
                                            "sectionId": screen.name,
                                            "screen": screen
                                          });

      if (dialog) {
        root.currentSettingsDialog = dialog;
        dialog.updateWidgetSettings.connect((sec, idx, settings) => {
                                              root.updateWidgetData(sec, idx, settings);
                                            });
        popupMenuWindow.hasDialog = true;
        dialog.closed.connect(() => {
                                popupMenuWindow.hasDialog = false;
                                popupMenuWindow.close();
                                if (root.currentSettingsDialog === dialog) {
                                  root.currentSettingsDialog = null;
                                }
                                dialog.destroy();
                              });
        dialog.open();
      } else {
        Logger.e("DesktopWidgetRegistry", "Failed to create widget settings dialog");
      }
    }

    if (component.status === ready) {
      instantiateAndOpen();
    } else if (component.status === error) {
      Logger.e("DesktopWidgetRegistry", "Error loading settings dialog component:", component.errorString());
    } else {
      component.statusChanged.connect(() => {
                                        if (component.status === ready) {
                                          instantiateAndOpen();
                                        } else if (component.status === error) {
                                          Logger.e("DesktopWidgetRegistry", "Error loading settings dialog component:", component.errorString());
                                        }
                                      });
    }
}
