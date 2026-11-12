.pragma library

function unregister(components, componentId) {
  delete components[componentId];
}
