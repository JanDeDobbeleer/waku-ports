.pragma library

function getButtonGeometry(buttonItem) {
  if (!buttonItem || typeof buttonItem.mapToItem !== "function")
    return { valid: false };
  try {
    var position = buttonItem.mapToItem(null, 0, 0);
    return {
      valid: true,
      x: position.x,
      y: position.y,
      width: buttonItem.width,
      height: buttonItem.height
    };
  } catch (error) {
    return { valid: true, error: error };
  }
}function getClickPoint(buttonName) {
  if (!buttonName || typeof buttonName !== "object" || buttonName.x === undefined || buttonName.y === undefined)
    return null;
  return { x: buttonName.x, y: buttonName.y };
}function getProperty(object, name) {
  return object === null || object === undefined ? undefined : object[name];
}