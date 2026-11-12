.pragma library

function name(loader) {
  return loader.name;
}

function status(loader) {
  return loader.status;
}

function destroy(loader) { loader.destroy(); }
function connectStatusChanged(loader, callback) { loader.statusChanged.connect(callback); }
