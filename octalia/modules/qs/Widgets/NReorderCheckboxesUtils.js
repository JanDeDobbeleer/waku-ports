.pragma library

function length(model) {
  return model.length;
}

function field(item, name) {
  return item[name];
}

function toggleItem(root, index) {
    if (index < 0 || index >= root.model.length)
      return;
    var item = root.model[index];
    if (item.required)
      return;

    // Create a new array to trigger binding update
    var newModel = root.model.slice();
    newModel[index] = Object.assign({}, item, {
                                      "enabled": !item.enabled
                                    });
    root.model = newModel;

    root.itemToggled(index, newModel[index].enabled);
}

function moveItem(root, fromIndex, toIndex) {
    if (fromIndex === toIndex)
      return;
    if (fromIndex < 0 || fromIndex >= root.model.length)
      return;
    if (toIndex < 0 || toIndex >= root.model.length)
      return;

    // Create a new array with item moved
    var newModel = root.model.slice();
    var item = newModel.splice(fromIndex, 1)[0];
    newModel.splice(toIndex, 0, item);
    root.model = newModel;

    root.itemsReordered(fromIndex, toIndex);
}
