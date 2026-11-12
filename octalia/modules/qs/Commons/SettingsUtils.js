.pragma library

function _findScreenOverride(screenName, overridesInput) {
    var i;
    var overrides = overridesInput;
    if (!screenName || !overrides || overrides.length === undefined) {
      return null;
    }
    for (i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName) {
        return overrides[i];
      }
    }
    return null;
}

function _findScreenOverrideIndex(screenName, overridesInput) {
    var i;
    var overrides = overridesInput;
    if (!screenName || !overrides || overrides.length === undefined) {
      return -1;
    }
    for (i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName) {
        return i;
      }
    }
    return -1;
}

function stringifyCurrentValue(currentValue) {
  return JSON.stringify(currentValue && typeof currentValue.length === "number" ? Array.from(currentValue) : currentValue);
}

function deleteOverride(override, property) { delete override[property]; }

function generateDefaultSettings(Logger, Quickshell, QtObj2JS, settingsAdapter) {
    var defaultPath, jsonData, plainAdapter;
    try {
      Logger.d("Settings", "Generating settings-default.json");

      // Prepare a clean JSON
      plainAdapter = QtObj2JS.qtObjectToPlainObject(settingsAdapter);
      jsonData = JSON.stringify(plainAdapter, null, 2);

      defaultPath = Quickshell.shellDir + "/Assets/settings-default.json";

      Quickshell.execDetached(["sh", "-c", `cat > "${defaultPath}" << 'OCTALIA_EOF'\n${jsonData}\nOCTALIA_EOF`]);
    } catch (error) {
      Logger.e("Settings", "Failed to generate default settings file: " + error);
    }
}

function generateWidgetDefaultSettings(Logger, Quickshell, QtObj2JS, BarWidgetRegistry, ControlCenterWidgetRegistry, DesktopWidgetRegistry) {
    var defaultPath, jsonData, output;
    try {
      Logger.d("Settings", "Generating settings-widgets-default.json");

      output = {
        "bar": QtObj2JS.qtObjectToPlainObject(BarWidgetRegistry.widgetMetadata),
        "controlCenter": QtObj2JS.qtObjectToPlainObject(ControlCenterWidgetRegistry.widgetMetadata),
        "desktop": QtObj2JS.qtObjectToPlainObject(DesktopWidgetRegistry.widgetMetadata)
      };
      jsonData = JSON.stringify(output, null, 2);

      defaultPath = Quickshell.shellDir + "/Assets/settings-widgets-default.json";

      Quickshell.execDetached(["sh", "-c", `cat > "${defaultPath}" << 'OCTALIA_EOF'\n${jsonData}\nOCTALIA_EOF`]);
    } catch (error) {
      Logger.e("Settings", "Failed to generate widget default settings file: " + error);
    }
}

function upgradeWidget(widget, BarWidgetRegistry) {
    var i;
    // Backup the widget definition before altering
    const widgetBefore = JSON.stringify(widget);

    // Get all existing custom settings keys
    const keys = Object.keys(BarWidgetRegistry.widgetMetadata[widget.id]);

    // Delete deprecated user settings from the wiget
    for (const k of Object.keys(widget)) {
      if (k === "id") {
        continue;
      }
      if (!keys.includes(k)) {
        delete widget[k];
      }
    }

    // Inject missing default setting (metaData) from BarWidgetRegistry
    for (i = 0; i < keys.length; i++) {
      const k = keys[i];
      if (k === "id") {
        continue;
      }

      if (widget[k] === undefined) {
        widget[k] = BarWidgetRegistry.widgetMetadata[widget.id][k];
      }
    }

    // Compare settings, to detect if something has been upgraded
    const widgetAfter = JSON.stringify(widget);
    return (widgetAfter !== widgetBefore);
}

function parseRawSettings(settingsFileView, Logger) {
  try {
    return JSON.parse(settingsFileView.text());
  } catch (e) {
    Logger.w("Settings", "Could not parse raw JSON for migrations");
    return null;
  }
}

function loadDefaultSettings(root, defaultSettingsFileView, Logger) {
      try {
        root._defaultSettings = JSON.parse(defaultSettingsFileView.text());
      } catch (e) {
        Logger.w("Settings", "Failed to parse default settings file: " + e);
        root._defaultSettings = null;
      }
}

function sortedMigrationVersions(migrations) { return Object.keys(migrations).map(v => parseInt(v)).sort((a, b) => a - b); }

function upgradeSettings(root, settingsAdapter, BarWidgetRegistry, ControlCenterWidgetRegistry, DesktopWidgetRegistry, Logger) {
    var desktopWidget, i, m, s, shortcut, widget;
    // -----------------
    const sections = ["left", "center", "right"];

    // 1. remove any non existing bar widget type
    var removedWidget = false;
    for (s = 0; s < sections.length; s++) {
      const sectionName = sections[s];
      const widgets = Array.from(settingsAdapter.bar.widgets[sectionName]);
      let sectionChanged = false;
      // Iterate backward through the widgets array, so it does not break when removing a widget
      for (i = widgets.length - 1; i >= 0; i--) {
        widget = widgets[i];
        if (!BarWidgetRegistry.hasWidget(widget.id)) {
          Logger.w(`Settings`, `!!! Deleted invalid bar widget ${widget.id} !!!`);
          widgets.splice(i, 1);
          sectionChanged = true;
          removedWidget = true;
        }
      }
      if (sectionChanged) settingsAdapter.bar.widgets[sectionName] = widgets;
    }

    // -----------------
    // 2. remove any non existing control center widget type
    const ccSections = ["left", "right"];
    for (s = 0; s < ccSections.length; s++) {
      const sectionName = ccSections[s];
      const shortcuts = Array.from(settingsAdapter.controlCenter.shortcuts[sectionName]);
      let sectionChanged = false;
      for (i = shortcuts.length - 1; i >= 0; i--) {
        shortcut = shortcuts[i];
        if (!ControlCenterWidgetRegistry.hasWidget(shortcut.id)) {
          Logger.w(`Settings`, `!!! Deleted invalid control center widget ${shortcut.id} !!!`);
          shortcuts.splice(i, 1);
          sectionChanged = true;
          removedWidget = true;
        }
      }
      if (sectionChanged) settingsAdapter.controlCenter.shortcuts[sectionName] = shortcuts;
    }

    // -----------------
    // 3. remove any non existing desktop widget type
    const monitorWidgets = Array.from(settingsAdapter.desktopWidgets.monitorWidgets);
    let monitorsChanged = false;
    for (m = 0; m < monitorWidgets.length; m++) {
      const monitor = monitorWidgets[m];
      if (!monitor.widgets)
        continue;
      const widgets = Array.from(monitor.widgets);
      let monitorChanged = false;
      for (i = widgets.length - 1; i >= 0; i--) {
        desktopWidget = widgets[i];
        if (!DesktopWidgetRegistry.hasWidget(desktopWidget.id)) {
          Logger.w(`Settings`, `!!! Deleted invalid desktop widget ${desktopWidget.id} !!!`);
          widgets.splice(i, 1);
          monitorChanged = true;
          removedWidget = true;
        }
      }
      if (monitorChanged) {
        monitorWidgets[m] = Object.assign({}, monitor, { widgets: widgets });
        monitorsChanged = true;
      }
    }
    if (monitorsChanged) settingsAdapter.desktopWidgets.monitorWidgets = monitorWidgets;

    // -----------------
    // 4. upgrade user widget settings
    for (s = 0; s < sections.length; s++) {
      const sectionName = sections[s];
      const widgets = Array.from(settingsAdapter.bar.widgets[sectionName]);
      let sectionChanged = false;
      for (i = 0; i < widgets.length; i++) {
        widget = Object.assign({}, widgets[i]);

        // Check if widget registry supports user settings, if it does not, then there is nothing to do
        if (BarWidgetRegistry.widgetMetadata[widget.id] === undefined) {
          continue;
        }

        if (upgradeWidget(widget, BarWidgetRegistry)) {
          widgets[i] = widget;
          sectionChanged = true;
          Logger.d("Settings", `Upgraded ${widget.id} widget:`, JSON.stringify(widget));
        }
      }
      if (sectionChanged) settingsAdapter.bar.widgets[sectionName] = widgets;
    }
}

function applicationFontFamily() {
  return Qt.application.font.family;
}

function isScreenOverrideEnabled(screenName, overrides) {
  var override = _findScreenOverride(screenName, overrides);
  return !!override && override.enabled !== false;
}

function getBarOverride(screenName, bar, property, fallback) {
  var override = _findScreenOverride(screenName, bar.screenOverrides);
  if (override && override.enabled !== false && override[property] !== undefined)
    return override[property];
  if (property === "widgets")
    return bar.widgets;
  return bar[property] || fallback;
}

function hasScreenOverride(screenName, overrides, property) {
  var override = _findScreenOverride(screenName, overrides);
  if (!override)
    return false;
  if (property)
    return override[property] !== undefined;
  var keys = Object.keys(override);
  return keys.length > 1 || (keys.length === 1 && keys[0] !== "name");
}
