.pragma library

function invokeDefault(notif, NotificationService) {

      var actions = JSON.parse(notif.actionsJson || "[]");
      if (actions.length === 0)
        return false;

      var actionId = actions.find(a => a.identifier === "default")?.identifier ?? actions[0].identifier;
      return NotificationService.invokeAction(notif.id, actionId);
}

function invokeDefaultAndDismiss(notif, NotificationService) {

      var actions = JSON.parse(notif.actionsJson || "[]");
      if (actions.length === 0) {
        NotificationService.dismissPopup(notif.id);
        return false;
      }

      var actionId = actions.find(a => a.identifier === "default")?.identifier ?? actions[0].identifier;
      var result = NotificationService.invokeAction(notif.id, actionId);
      NotificationService.dismissPopup(notif.id);
      return result;
}

function notificationActions(notif) { return notif.actionsJson || "[]"; }

function sendToast(json, ToastService, Logger) {
      var body, data, duration, icon, title, type;
      try {
        data = JSON.parse(json);
        title = data.title || "";
        body = data.body || "";
        icon = data.icon || "";
        type = data.type || "notice";
        duration = data.duration;

        switch (type) {
        case "warning":
          ToastService.showWarningDetailed(title, body, duration ?? 4000, undefined, undefined);
          break;
        case "error":
          ToastService.showErrorDetailed(title, body, duration ?? 6000, undefined, undefined);
          break;
        default:
          ToastService.showNoticeDetailed(title, body, icon, duration ?? 3000, undefined, undefined);
        }
      } catch (error) {
        Logger.e("IPC", "Failed to parse toast JSON: " + error);
      }
}

function toggleSettings(root, parsed) { root._settingsToggle(parsed.tab, parsed.subTab); }
function openSettings(root, parsed) { root._settingsOpen(parsed.tab, parsed.subTab); }

function modelCount(model) { return model.count; }
function modelGet(model, index) { return model.get(index); }
function lockScreenActive(lockScreen) { return lockScreen.active; }
function findScreen(screens, screen) { return screens.find(s => s.name === screen); }

function isValidScheme(schemeTypes, method) {
      var i;
      var valid = false;
      for (i = 0; i < schemeTypes.length; i++) {
        if (schemeTypes[i].key === method) {
          valid = true;
          break;
        }
      }
      return valid;
}

function stateAsJson(ShellState, Logger) {
      var snapshot;
      try {
        snapshot = ShellState.buildStateSnapshot();
        if (!snapshot) {
          throw new Error("State snapshot unavailable");
        }
        return JSON.stringify(snapshot, null, 2);
      } catch (error) {
        Logger.e("IPC", "Failed to serialize state:", error);
        return JSON.stringify({
                                "error": "Failed to serialize state: " + error
                              }, null, 2);
      }
}

function invokePanel(panel, method, args) {
  if (panel)
    panel[method](...args);
}
