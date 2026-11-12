.pragma library

function calculateWidth(root, textMeasure, iconMeasure, Style) {
    let maxWidth = 0;
    if (root.model && root.model.length) {
      for (let i = 0; i < root.model.length; i++) {
        const item = root.model[i];
        if (item && item.visible !== false) {
          const label = item.label || item.text || "";
          textMeasure.text = label;
          textMeasure.forceLayout();

          let itemWidth = textMeasure.contentWidth + 8;

          if (item.icon !== undefined) {
            itemWidth += iconMeasure.width + Style.marginS;
          }

          itemWidth += Style.margin2M;

          if (itemWidth > maxWidth) {
            maxWidth = itemWidth;
          }
        }
      }
    }
    root.calculatedWidth = Math.max(maxWidth + Style.margin2S, root.minWidth);
}

function setTarget(root, item, centerOnItem) {
    if (centerOnItem && centerOnItem !== item) {
      const relPos = centerOnItem.mapToItem(item, 0, 0);
      root.targetOffsetX = relPos.x;
      root.targetOffsetY = relPos.y;
      root.targetWidth = centerOnItem.width;
      root.targetHeight = centerOnItem.height;
    } else {
      root.targetOffsetX = 0;
      root.targetOffsetY = 0;
      root.targetWidth = 0;
      root.targetHeight = 0;
    }

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

function updateAnchor(anchor) {
  if (anchor) anchor.updateAnchor();
}
