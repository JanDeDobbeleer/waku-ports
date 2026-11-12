.pragma library

function screensForNotifications(screens, monitors) {
  var selected = [];
  for (var i = 0; i < screens.length; ++i) {
    if (monitors.includes(screens[i].name))
      selected.push(screens[i]);
  }
  return selected.length === 0 ? screens : selected;
}

function modelCount(model) {
  return model ? model.count : 0;
}

function role(record, name) {
  return record ? record[name] : undefined;
}

function hasTextField(record, name) {
  return (role(record, name) || "").length > 0;
}

function parseActions(actions) {
  try {
    return actions ? JSON.parse(actions) : [];
  } catch (e) {
    return [];
  }
}

function actionCount(actions) {
  return actions ? actions.length : 0;
}

function hasDefaultAction(actions) {
  for (var i = 0; actions && i < actions.length; ++i) {
    if (actions[i].identifier === "default")
      return true;
  }
  return false;
}

function animateNotification(repeater, notificationId, service) {
  var delegate = null;
  try {
    if (repeater) {
      for (var i = 0; i < repeater.count; ++i) {
        var item = repeater.itemAt(i);
        if (item && item.notificationId === notificationId) {
          delegate = item;
          break;
        }
      }
    }
    if (delegate && typeof delegate.animateOut === "function" && !delegate.isRemoving)
      delegate.animateOut();
  } catch (e) {
    service.dismissPopup(notificationId);
  }
}
