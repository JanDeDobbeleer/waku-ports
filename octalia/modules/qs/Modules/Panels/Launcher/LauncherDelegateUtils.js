.pragma library

function field(record, name) {
  return record ? record[name] : undefined;
}

function setField(record, name, value) {
  if (record)
    record[name] = value;
}

function prepareItem(item) {
  var provider = field(item, "provider");
  if (provider && provider.prepareItem)
    provider.prepareItem(item);
}

function imageRevision(item) {
  var provider = field(item, "provider");
  return provider && provider.imageRevision ? provider.imageRevision : 0;
}

function imageUrl(item, revision) {
  void revision;
  var provider = field(item, "provider");
  return provider && provider.getImageUrl ? provider.getImageUrl(item) : "";
}

function itemActions(item, launcher) {
  var provider = field(item, "provider") || field(launcher, "currentProvider");
  return provider && provider.getItemActions ? provider.getItemActions(item) : [];
}

function arrayLength(items) {
  return items ? items.length : 0;
}

function activate(launcher) {
  if (launcher)
    launcher.activate();
}

function runAction(actionData) {
  var action = field(actionData, "action");
  if (action)
    action();
}

function firstLetter(value) {
  return value ? value.charAt(0).toUpperCase() : "?";
}

function formatLabel(description) {
  var parts = (description || "").split(" • ");
  return parts[0] || "IMG";
}

function gridCellWidth(view) {
  return view.cellWidth;
}

function gridCellHeight(view) {
  return view.cellHeight;
}
