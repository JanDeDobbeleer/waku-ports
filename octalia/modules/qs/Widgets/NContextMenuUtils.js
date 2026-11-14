.pragma library

function filteredModel(model) {
    var i;
    if (!model || model.length === 0)
      return [];
    var filtered = [];
    for (i = 0; i < model.length; i++) {
      if (model[i].visible !== false) {
        filtered.push(model[i]);
      }
    }
    return filtered;
}

function openAt(x, y, root, spacing) {
    var constraint, itemCount, menuHeight, menuWidth, tl;
    if (root.parent) {
      menuWidth = root.width;
      itemCount = root.filteredModel.length;
      menuHeight = Math.max(itemCount * root.itemHeight + Math.max(0, itemCount - 1) * spacing, root.itemHeight) + root.topPadding + root.bottomPadding;
      constraint = root.constrainTo || root._detectedConstraint;
      if (constraint) {
        tl = constraint.mapToItem(root.parent, 0, 0);
        x = Math.max(tl.x, Math.min(x, tl.x + constraint.width - menuWidth));
        y = Math.max(tl.y, Math.min(y, tl.y + constraint.height - menuHeight));
      } else {
        x = Math.max(0, Math.min(x, root.parent.width - menuWidth));
        y = Math.max(0, Math.min(y, root.parent.height - menuHeight));
      }
    }
    root.x = x;
    root.y = y;
    root.open();
}

function openAtItem(item, mouseX, mouseY, root) {
    var p;
    if (!root.constrainTo) {
      root._detectedConstraint = null;
      p = item;
      while (p && p !== root.parent) {
        if (p.clip && p.width > 0 && p.height > 0) {
          root._detectedConstraint = p;
          break;
        }
        p = p.parent;
      }
    }
    var pos = item.mapToItem(root.parent, mouseX || 0, mouseY || 0);
    root.openAt(pos.x, pos.y);
}

function field(item, name) {
  return item[name];
}

function label(item) {
  return item.label || item.text || "";
}

function action(item, index) {
  return item.action || item.key || index.toString();
}
