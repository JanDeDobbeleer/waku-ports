.pragma library

function openDialog(component, root, overlay) {
  const dialog = component.createObject(root, {
    "selectedColor": root.selectedColor,
    "parent": overlay,
    "screen": root.screen
  });
  dialog.colorSelected.connect(function (color) {
    root.selectedColor = color;
    root.colorSelected(color);
  });
  dialog.open();
}
