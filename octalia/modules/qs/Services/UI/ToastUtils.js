.pragma library

function showNotice(root, title, description = "", icon = "", duration = 3000, actionLabel = "", actionCallback = null) {
  root.notify(title, description, icon, "notice", duration, actionLabel, actionCallback);
}

function showWarning(root, title, description = "", duration = 4000, actionLabel = "", actionCallback = null) {
  root.notify(title, description, "", "warning", duration, actionLabel, actionCallback);
}

function showError(root, title, description = "", duration = 6000, actionLabel = "", actionCallback = null) {
  root.notify(title, description, "", "error", duration, actionLabel, actionCallback);
}
