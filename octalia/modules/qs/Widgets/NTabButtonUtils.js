.pragma library

function selectInParent(root) {
  if (root.parent && root.parent.parent && root.parent.parent.currentIndex !== undefined) {
    root.parent.parent.currentIndex = root.tabIndex;
  }
}
