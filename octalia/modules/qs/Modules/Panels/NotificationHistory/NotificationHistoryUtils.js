.pragma library

function parseActions(actions) {
  try {
    return JSON.parse(actions || "[]");
  } catch (e) {
    return [];
  }
}

function role(record, name) {
  return record ? record[name] : undefined;
}

function hasSafeScheme(value) {
  return value.startsWith("http://") || value.startsWith("https://") || value.startsWith("mailto:");
}

function hasDefaultAction(actions) {
  for (var i = 0; i < actions.length; ++i) {
    if (actions[i].identifier === "default")
      return true;
  }
  return false;
}

function modelCount(model) {
  return model ? model.count : 0;
}

function modelRecord(model, index) {
  return model ? model.get(index) : null;
}

function actionCount(actions) {
  return actions ? actions.length : 0;
}

function actionIdentifier(actions, index) {
  var action = actions && index >= 0 && index < actions.length ? actions[index] : null;
  return action ? action.identifier : undefined;
}

function canExpand(delegate) {
  return delegate && (delegate.canExpand || delegate.isExpanded);
}

function scrollToItem(flickable, item, margin) {
  if (!flickable || !flickable.contentItem || !item || !item.visible)
    return;

  var itemY = flickable.contentItem.mapFromItem(item, 0, 0).y;
  var itemHeight = item.height;
  var currentContentY = flickable.contentY;
  var viewHeight = flickable.height;

  if (itemY < currentContentY)
    flickable.contentY = Math.max(0, itemY - margin);
  else if (itemY + itemHeight > currentContentY + viewHeight)
    flickable.contentY = (itemY + itemHeight) - viewHeight + margin;
}
