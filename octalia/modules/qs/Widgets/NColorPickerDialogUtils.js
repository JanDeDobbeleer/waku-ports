.pragma library

function field(item, name) {
  return item[name];
}

function center(root) {
    var parentPos;
    // Center on screen after popup is opened and parent position is known
    if (root.screen && root.parent) {
      parentPos = root.parent.mapToItem(null, 0, 0);
      root.x = Math.round((root.screen.width - root.width) / 2 - parentPos.x);
      root.y = Math.round((root.screen.height - root.height) / 2 - parentPos.y);
    }
}
