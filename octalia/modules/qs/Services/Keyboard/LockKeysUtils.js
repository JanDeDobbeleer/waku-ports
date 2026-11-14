.pragma library

function unregister(registered, id) {
  delete registered[id];
}
