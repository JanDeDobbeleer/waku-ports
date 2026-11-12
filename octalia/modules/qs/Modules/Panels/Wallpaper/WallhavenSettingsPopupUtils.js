.pragma library

function centerPosition(parentItem, screen, popupWidth, popupHeight) {
  if (!screen || !parentItem)
    return null;
  const parentPosition = parentItem.mapToItem(null, 0, 0);
  return {
    "x": Math.round((screen.width - popupWidth) / 2 - parentPosition.x),
    "y": Math.round((screen.height - popupHeight) / 2 - parentPosition.y)
  };
}

function inputItem(input) {
  return input ? input.inputItem : null;
}

function focusInput(input) {
  const item = inputItem(input);
  if (item)
    item.forceActiveFocus();
}

function setInputEchoMode(input, mode) {
  const item = inputItem(input);
  if (item)
    item.echoMode = mode;
}

function configureInputFocus(input, focusPolicy) {
  const item = inputItem(input);
  if (!item)
    return;
  item.focusPolicy = focusPolicy;
  item.activeFocusOnPress = true;
}
