.pragma library

function applicationFontFamily() {
  return Qt.application.font.family;
}

function sortFontNames(fontSet) {
  return Object.keys(fontSet).sort(function (a, b) { return a.localeCompare(b); });
}

function clearModel(model) {
  model.clear();
}

function appendItem(model, item) {
  model.append(item);
}

function count(model) {
  return model.count;
}

function isMonospace(family) {
  return /mono|code|consol|courier|cascadia|fixed|terminal|hack|lucida console|inconsolata|iosevka|menlo/i.test(family);
}
