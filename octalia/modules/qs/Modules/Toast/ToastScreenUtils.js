.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function arrayLength(value) {
  return value && typeof value.length === "number" ? value.length : 0;
}

function hideToast(item) {
  if (item && typeof item.hideToast === "function")
    item.hideToast();
}

function showToast(item, toast) {
  if (!item || typeof item.showToast !== "function" || !toast)
    return;
  item.showToast(field(toast, "title"), field(toast, "description"), field(toast, "icon"), field(toast, "type"), field(toast, "duration"), field(toast, "actionLabel"), field(toast, "actionCallback"));
}
