.pragma library

function loadToModel(root, model, settings, logger) {
  if (root._saving) return;
  model.clear();
  let entries = [];
  try {
    entries = JSON.parse(settings.data.idle.customCommands);
  } catch (e) {
    logger.w("CustomSubTab", "Failed to parse customCommands:", e);
  }
  for (let i = 0; i < entries.length; i++) {
    model.append({
      name: String(entries[i].name || ""),
      timeout: parseInt(entries[i].timeout) || 60,
      command: String(entries[i].command || ""),
      resumeCommand: String(entries[i].resumeCommand || "")
    });
  }
}

function saveFromModel(root, model, settings) {
  root._saving = true;
  const entries = [];
  for (let i = 0; i < model.count; i++) {
    const item = model.get(i);
    entries.push({ name: item.name, timeout: item.timeout, command: item.command, resumeCommand: item.resumeCommand });
  }
  settings.data.idle.customCommands = JSON.stringify(entries);
  root._saving = false;
}

function connectSaved(popup, index, model, root) {
  try { popup.saved.disconnect(popup._savedSlot); } catch (e) {}
  popup._savedSlot = function (timeout, command, resumeCommand, name) {
    if (index >= 0 && index < model.count) {
      model.setProperty(index, "name", name);
      model.setProperty(index, "timeout", timeout);
      model.setProperty(index, "command", command);
      model.setProperty(index, "resumeCommand", resumeCommand);
    } else {
      model.append({ name: name, timeout: timeout, command: command, resumeCommand: resumeCommand });
    }
    root._saveFromModel();
  };
  popup.saved.connect(popup._savedSlot);
}
