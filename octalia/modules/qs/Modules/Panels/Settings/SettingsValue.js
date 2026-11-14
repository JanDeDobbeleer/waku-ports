.pragma library

function undefinedFallback(data, metadata, key, metadataKey) {
  return data[key] !== undefined ? data[key] : metadata[metadataKey || key];
}

function nestedNullishFallback(data, metadata, key, nestedKey) {
  return data?.[key]?.[nestedKey] ?? metadata?.[key]?.[nestedKey];
}

function truthyFallback(data, metadata, key) {
  return data?.[key] || metadata[key];
}

function truthyOptionalFallback(data, metadata, key) {
  return data?.[key] || metadata?.[key];
}

function nullishFallback(data, metadata, key) {
  return data?.[key] ?? metadata[key];
}

function nullishOptionalFallback(data, metadata, key) {
  return data?.[key] ?? metadata?.[key];
}

function read(target, key) {
  return target[key];
}

function readNested(target, key, nestedKey) {
  return target[key][nestedKey];
}

function stringWhenDefined(target, key) {
  return target && target[key] !== undefined ? String(target[key]) : "";
}

function optionalRead(target, key) {
  return target?.[key];
}

function diskPathOptions(diskPercents) {
  const paths = Object.keys(diskPercents).sort();
  return paths.map(path => ({
    key: path,
    name: path
  }));
}

function valueOrDefault(target, key, fallback) {
  return target ? target[key] ?? fallback : fallback;
}

function windowIsVisible(window) {
  return window.visible;
}

function populateModel(values, model) {
  for (let i = 0; i < values.length; i++) {
    model.append({ rule: values[i] });
  }
}

function watchInput(input, root, targetInput) {
  if (input) {
    input.activeFocusChanged.connect(function () {
      if (input.activeFocus) {
        root.focusedInput = targetInput;
      }
    });
  }
}

function insertToken(root, fallbackInput, token) {
  let focusedInput = root.focusedInput;
  if (!focusedInput || !focusedInput.inputItem) {
    if (fallbackInput.inputItem) {
      fallbackInput.inputItem.focus = true;
      focusedInput = fallbackInput;
      root.focusedInput = focusedInput;
    }
  }
  if (focusedInput && focusedInput.inputItem) {
    const input = focusedInput.inputItem;
    const cursorPos = input.cursorPosition;
    const currentText = input.text;
    input.text = currentText.substring(0, cursorPos) + token + currentText.substring(cursorPos) + " ";
    input.cursorPosition = cursorPos + token.length + 1;
    input.focus = true;
  }
}


function hasCoordinates(value) {
  return typeof value === "object" && value.x !== undefined && value.y !== undefined;
}

function itemGeometry(item) {
  const position = item.mapToItem(null, 0, 0);
  return { x: position.x, y: position.y, width: item.width, height: item.height };
}


function pointFromCoordinates(value) {
  return Qt.point(value.x, value.y);
}

function initializeOpen(root) {
  const content = root._settingsContent;
  if (content) {
    if (root.requestedEntry) {
      content.requestedTab = root.requestedEntry.tab;
      content.initialize();
      const entry = root.requestedEntry;
      root.requestedEntry = null;
      Qt.callLater(() => content.navigateToResult(entry));
    } else {
      content.requestedTab = root.requestedTab;
      if (root.requestedSubTab >= 0) {
        content._pendingSubTab = root.requestedSubTab;
        root.requestedSubTab = -1;
      }
      content.initialize();
    }
  }
}

function callIfPresent(target, method) {
  if (target) {
    target[method]();
  }
}

function hasSearchText(target) {
  return target && target.searchText.trim() !== "";
}


function undefinedFallbackDefault(data, metadata, key, fallback) {
  return data[key] !== undefined ? data[key] : metadata[key] !== undefined ? metadata[key] : fallback;
}

function hasMultipleMonitors(screens) {
  return (screens || []).length > 1;
}

function acceptFirstFile(root, paths) {
  if (paths.length > 0) {
    root.valueCustomIconPath = paths[0];
    root.saveSettings();
  }
}

function addUniqueValue(list, value) {
  const values = (list || []).slice();
  if (!values.includes(value)) values.push(value);
  return values;
}

function removeValue(list, value) {
  return (list || []).filter(function (candidate) { return candidate !== value; });
}

function applySelectedPaths(paths, target, keys) {
  if (paths.length > 0) {
    for (let i = 0; i < keys.length; i++) target[keys[i]] = paths[0];
  }
}

function invoke(target, method, ...args) {
  return target[method](...args);
}

function addMediaBlacklistEntry(input, audioSettings, mediaService) {
  const value = (input.text || "").trim();
  if (value !== "") {
    const entries = audioSettings.mprisBlacklist || [];
    if (!entries.find(entry => String(entry).toLowerCase() === value.toLowerCase())) {
      audioSettings.mprisBlacklist = [...entries, value];
      input.text = "";
      mediaService.updateCurrentPlayer();
    }
  }
}

function removeMediaBlacklistEntry(audioSettings, mediaService, value) {
  const entries = audioSettings.mprisBlacklist || [];
  const index = entries.findIndex(entry => String(entry) === value);
  if (index >= 0) {
    entries.splice(index, 1);
    audioSettings.mprisBlacklist = entries;
    mediaService.updateCurrentPlayer();
  }
}

function languageOptions(availableLanguages, systemLanguage, automaticLabel) {
  const options = [{ key: "", name: automaticLabel + " (" + systemLanguage + ")" }];
  for (let i = 0; i < availableLanguages.length; i++) {
    const language = availableLanguages[i];
    options.push({ key: language, name: language });
  }
  return options;
}

function selectLanguage(key, settings, i18n) {
  Qt.callLater(function () {
    settings.data.general.language = key;
    if (key === "") i18n.detectLanguage();
    else i18n.setLanguage(key);
  });
}

function firstOrEmpty(values) {
  return values.length > 0 ? values[0] : "";
}

function assignFirstPath(paths, target, key) {
  if (paths.length > 0) target[key] = paths[0];
}

function openSetupWizard(panelService, screens, openedPanel) {
  const targetScreen = openedPanel ? openedPanel.screen : (screens.length > 0 ? screens[0] : null);
  if (!targetScreen) return;
  const setupPanel = panelService.getPanel("setupWizardPanel", targetScreen);
  if (setupPanel) {
    setupPanel.telemetryOnlyMode = false;
    setupPanel.open();
  } else {
    Qt.callLater(function () {
      const panel = panelService.getPanel("setupWizardPanel", targetScreen);
      if (panel) {
        panel.telemetryOnlyMode = false;
        panel.open();
      }
    });
  }
}

function audioNodeSelected(activeNode, node) {
  return activeNode?.id === node.id;
}

function audioOutput(sink) {
  return sink?.audio ? sink.audio : null;
}

function attachButtonGroup(nodes, group) {
  const result = [];
  for (let i = 0; i < nodes.length; i++) result.push({ device: nodes[i], groupRef: group });
  return result;
}

function mapOptions(options) {
  const keys = Object.keys(options);
  return keys.map(function (key) { return { key: key, name: options[key].name }; });
}

function insertTokenIntoInput(control, token) {
  if (control.inputItem) {
    const input = control.inputItem;
    const cursorPosition = input.cursorPosition;
    const currentText = input.text;
    input.text = currentText.substring(0, cursorPosition) + token + currentText.substring(cursorPosition) + " ";
    input.cursorPosition = cursorPosition + token.length + 1;
    input.forceActiveFocus();
  }
}

function selectSettingsPanelMode(key, settings, panelService, settingsPanelService, tab, subTab) {
  Qt.callLater(function () { settings.data.ui.settingsPanelMode = key; });
  if (settings.data.ui.settingsPanelMode === "window" || key === "window") {
    const openedPanel = panelService.openedPanel;
    const window = settingsPanelService.settingsWindow;
    const screen = (openedPanel && openedPanel.screen) || (window && window.screen) || panelService.findScreenForPanels();
    settingsPanelService.close(screen);
    Qt.callLater(function () { settingsPanelService.openToTab(tab, subTab, screen); });
  }
}

function setMonitorDirectoryFromPaths(paths, service, monitorName) {
  if (paths.length > 0) service.setMonitorDirectory(monitorName, paths[0]);
}

function automaticBacklightLabel(baseLabel, devices, service) {
  const path = devices && devices.length > 0 ? devices[0] : "";
  if (path === "") return baseLabel;
  const name = service.getBacklightDeviceName(path) || path;
  return baseLabel + "(" + name + ")";
}

function backlightDeviceOptions(devices, service, automaticLabel) {
  const options = [{ key: "", name: automaticLabel }];
  const available = devices || [];
  for (let i = 0; i < available.length; i++) {
    const path = available[i];
    const name = service.getBacklightDeviceName(path) || path;
    options.push({ key: path, name: name });
  }
  return options;
}

function invokeParent(item, method, ...args) {
  return item.parent[method](...args);
}
