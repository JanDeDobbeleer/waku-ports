.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function previewData(provider, data) {
  const getPreviewData = field(provider, "getPreviewData");
  return getPreviewData ? getPreviewData(data) : data;
}

function setCurrentItem(item, data) {
  if (item)
    item.currentItem = data;
}

function setSearchText(launcher, text) {
  const setText = field(launcher, "setSearchText");
  if (setText)
    setText(text);
}
