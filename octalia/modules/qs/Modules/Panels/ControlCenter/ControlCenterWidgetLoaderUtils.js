.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function implicitSize(item, propertyName) {
  return field(item, "visible") ? field(item, propertyName) : 0;
}

function configureWidget(item, properties, screen) {
  if (!item)
    return;
  if (properties) {
    for (const propertyName in properties) {
      if (item.hasOwnProperty(propertyName))
        item[propertyName] = properties[propertyName];
    }
  }
  if (item.hasOwnProperty("screen"))
    item.screen = screen;
  const onLoaded = field(item, "onLoaded");
  if (typeof onLoaded === "function")
    onLoaded.call(item);
}
