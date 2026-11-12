.pragma library

function length(value) {
  return value.length;
}

function loadEvents(root, daysAhead = 31, daysBehind = 14) {
  if (!root.available || !root.dataProvider) {
    return;
  }
  root.dataProvider.loadEvents(daysAhead, daysBehind);
}
