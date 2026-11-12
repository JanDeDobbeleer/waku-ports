.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function arrayLength(value) {
  return value && typeof value.length === "number" ? value.length : 0;
}

function findChild(parent, objectName) {
  const children = field(parent, "children") || [];
  for (let i = 0; i < children.length; i++) {
    if (field(children[i], "objectName") === objectName)
      return children[i];
  }
  return null;
}
