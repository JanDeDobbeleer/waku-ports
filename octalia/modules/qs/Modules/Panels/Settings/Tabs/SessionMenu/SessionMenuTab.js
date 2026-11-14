.pragma library

function saveEntries(entriesModel) {
  const toSave = [];
  let enabledNumber = 1;
  for (let i = 0; i < entriesModel.length; i++) {
    let keybind = entriesModel[i].keybind || "";
    if (entriesModel[i].enabled) {
      if (keybind === "" || /^\d+$/.test(keybind)) keybind = String(enabledNumber);
      enabledNumber++;
    } else if (/^\d+$/.test(keybind)) {
      keybind = "";
    }
    toSave.push({
      action: entriesModel[i].id,
      enabled: entriesModel[i].enabled,
      countdownEnabled: entriesModel[i].countdownEnabled !== undefined ? entriesModel[i].countdownEnabled : true,
      command: entriesModel[i].command || "",
      keybind: keybind
    });
  }
  const newModel = [];
  for (let i = 0; i < entriesModel.length; i++) {
    newModel.push(Object.assign({}, entriesModel[i], { keybind: toSave[i].keybind }));
  }
  return { model: newModel, settings: toSave };
}

function updateEntry(entriesModel, index, properties) {
  const newModel = entriesModel.slice();
  newModel[index] = Object.assign({}, newModel[index], properties);
  return newModel;
}

function reorderEntries(entriesModel, fromIndex, toIndex) {
  const newModel = entriesModel.slice();
  const item = newModel.splice(fromIndex, 1)[0];
  newModel.splice(toIndex, 0, item);
  return newModel;
}

function initializeEntries(powerOptions, entriesDefault) {
  let entry;
  let found;
  const entries = [];
  for (let i = 0; i < powerOptions.length; i++) {
    const settingEntry = powerOptions[i];
    for (let j = 0; j < entriesDefault.length; j++) {
      if (settingEntry.action === entriesDefault[j].id) {
        entry = entriesDefault[j];
        entry.enabled = settingEntry.enabled;
        entry.countdownEnabled = settingEntry.countdownEnabled !== undefined ? settingEntry.countdownEnabled : true;
        entry.command = settingEntry.command || "";
        entry.keybind = settingEntry.keybind || "";
        entries.push(entry);
      }
    }
  }
  for (let i = 0; i < entriesDefault.length; i++) {
    found = false;
    for (let j = 0; j < entries.length; j++) {
      if (entries[j].id === entriesDefault[i].id) {
        found = true;
        break;
      }
    }
    if (!found) {
      entry = entriesDefault[i];
      entry.countdownEnabled = true;
      entry.command = "";
      entry.keybind = "";
      entries.push(entry);
    }
  }
  return entries;
}

function closeActiveDialog(root) {
  let dialog;
  if (root._activeDialog && root._activeDialog.close) {
    dialog = root._activeDialog;
    root._activeDialog = null;
    dialog.close();
    dialog.destroy();
  }
}

function openEntrySettingsDialog(root, index, entries, shellDir, overlay, logger, readyStatus, errorStatus) {
  if (index < 0 || index >= entries.length) return;
  const entry = entries[index];
  const component = Qt.createComponent(shellDir + "/modules/qs/Modules/Panels/Settings/Tabs/SessionMenu/SessionMenuEntrySettingsDialog.qml");
  function instantiateAndOpen() {
    if (root._activeDialog) {
      root._activeDialog.close();
      root._activeDialog.destroy();
      root._activeDialog = null;
    }
    const dialog = component.createObject(overlay, {
      entryIndex: index,
      entryData: entry,
      entryId: entry.id,
      entryText: entry.text
    });
    if (dialog) {
      root._activeDialog = dialog;
      dialog.updateEntryProperties.connect((idx, properties) => root.updateEntry(idx, properties));
      dialog.closed.connect(() => {
        if (root._activeDialog === dialog) {
          root._activeDialog = null;
          dialog.destroy();
        }
      });
      dialog.open();
    } else {
      logger.e("SessionMenuTab", "Failed to create entry settings dialog");
    }
  }
  if (component.status === readyStatus) {
    instantiateAndOpen();
  } else if (component.status === errorStatus) {
    logger.e("SessionMenuTab", "Error loading entry settings dialog:", component.errorString());
  } else {
    component.statusChanged.connect(function () {
      if (component.status === readyStatus) {
        instantiateAndOpen();
      } else if (component.status === errorStatus) {
        logger.e("SessionMenuTab", "Error loading entry settings dialog:", component.errorString());
      }
    });
  }
}
