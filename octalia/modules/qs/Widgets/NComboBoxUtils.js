.pragma library

function itemCount(root) {
    if (!root.model)
      return 0;
    if (typeof root.model.count === 'number')
      return root.model.count;
    if (Array.isArray(root.model))
      return root.model.length;
    return 0;
}

function getItem(index, root) {
    if (!root.model)
      return null;
    if (typeof root.model.get === 'function')
      return root.model.get(index);
    if (Array.isArray(root.model))
      return root.model[index];
    return null;
}

function findIndexByKey(key, root) {
    var i, item;
    for (i = 0; i < root.itemCount(); i++) {
      item = getItem(i, root);
      if (item && item.key === key)
        return i;
    }
    return -1;
}

function closePopup(popup) {
  popup.close();
}

function select(index, root) {
  var item = getItem(index, root);
  if (!item || item.key === undefined)
    return false;
  root.selected(item.key);
  return true;
}

function currentText(index, root) {
  var item = getItem(index, root);
  return item ? item.name : root.placeholder;
}

function delegateText(index, root) {
  var item = getItem(index, root);
  return item && item.name ? item.name : "";
}
