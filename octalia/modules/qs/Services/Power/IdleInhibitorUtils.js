.pragma library

function addInhibitor(root, Logger, id, reason = "Application request") {
  if (root.activeInhibitors.includes(id)) {
    Logger.w("IdleInhibitor", "Inhibitor already active:", id);
    return false;
  }
  root.activeInhibitors.push(id);
  root.updateInhibition(reason);
  Logger.d("IdleInhibitor", "Added inhibitor:", id);
  return true;
}

function removeInhibitor(root, Logger, id) {
  const index = root.activeInhibitors.indexOf(id);
  if (index === -1) {
    Logger.w("IdleInhibitor", "Inhibitor not found:", id);
    return false;
  }
  root.activeInhibitors.splice(index, 1);
  root.updateInhibition();
  Logger.d("IdleInhibitor", "Removed inhibitor:", id);
  return true;
}

function updateInhibition(root, newReason) {
  if (newReason === undefined) newReason = root.reason;
  const shouldInhibit = root.activeInhibitors.length > 0;
  if (shouldInhibit === root.isInhibited) return;
  if (shouldInhibit) root.startInhibition(newReason);
  else root.stopInhibition();
}
