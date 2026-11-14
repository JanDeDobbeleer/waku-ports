.pragma library

function stateChecksJson(data, metadata) {
  return data && data.stateChecksJson !== undefined ? data.stateChecksJson : (metadata && metadata.stateChecksJson ? metadata.stateChecksJson : "[]");
}

function populateStateChecks(json, model, logger) {
  try {
    const initialChecks = JSON.parse(json);
    if (initialChecks && Array.isArray(initialChecks)) {
      for (let i = 0; i < initialChecks.length; i++) {
        const item = initialChecks[i];
        if (item && typeof item === "object") {
          model.append({ command: item.command || "", icon: item.icon || "" });
        } else {
          logger.w("CustomButtonSettings", "Invalid stateChecks entry at index " + i + ":", item);
        }
      }
    }
  } catch (e) {
    logger.e("CustomButtonSettings", "Failed to parse stateChecksJson:", e.message);
  }
}

function updateStateCheck(model, index, command, icon) {
  model.set(index, { command: command, icon: icon });
}

function removeStateCheck(model, index) {
  model.remove(index);
}

function addStateCheck(model) {
  model.append({ command: "", icon: "" });
}

function serializeStateChecks(model) {
  const items = [];
  for (let i = 0; i < model.count; i++) {
    items.push(model.get(i));
  }
  return JSON.stringify(items);
}
