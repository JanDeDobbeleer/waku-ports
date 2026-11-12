.pragma library

function verticalOverflow(item) {
  return item.contentHeight > item.height;
}

function horizontalOverflow(item) {
  return item.contentWidth > item.width;
}

function scrollRange(flickable) {
  return flickable.contentHeight - flickable.height;
}

function contentY(flickable) {
  return flickable.contentY;
}

function setContentY(flickable, y) {
  flickable.contentY = y;
}

function dragging(flickable) {
  return flickable.dragging;
}

function flicking(flickable) {
  return flickable.flicking;
}

function configureFirstFlickable(root, children, verticalFlick) {
  for (let i = 0; i < children.length; i++) {
    const child = children[i];
    if (child.toString().indexOf("Flickable") !== -1) {
      child.boundsBehavior = root.boundsBehavior;
      root._internalFlickable = child;
      if (root.preventHorizontalScroll) child.flickableDirection = verticalFlick;
      return true;
    }
  }
  return false;
}

function bindContentWidth(child, binding) {
  child.contentWidth = binding;
}

function widthBinding(child) {
  return function () { return child.width; };
}
