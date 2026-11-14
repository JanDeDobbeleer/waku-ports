.pragma library

function activePlayer(items, active) {
    for (var i = 0; i < items.length; i++) {
        if (items[i].modelData === active)
            return items[i];
    }
    return items.length > 0 ? items[0] : null;
}
function minimumLeftWidth(width, expandButton, spacing) { return width - expandButton.implicitWidth - spacing; }
function maximumLabelWidth(minimum, iconLabel, textRow, horizontalPadding) {
    return minimum - iconLabel.implicitWidth - textRow.spacing - textRow.anchors.horizontalCenterOffset / 2 - horizontalPadding * 2;
}
