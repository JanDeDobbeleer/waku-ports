.pragma library

function positionX(item, parent, attachSide, thisSide, leftSide, rightSide, width, margin) {
    var offset = attachSide === leftSide ? 0 : item.width;
    if (thisSide === rightSide)
        offset -= width;
    return item.mapToItem(parent, offset, 0).x + margin;
}
function positionY(item, parent, attachSide, thisSide, topSide, bottomSide, height, margin) {
    var offset = attachSide === topSide ? 0 : item.height;
    if (thisSide === bottomSide)
        offset -= height;
    return item.mapToItem(parent, 0, offset).y + margin;
}
function click(item) { item.clicked(); }

function parentItem(window) { return window ? (window.interactionWrapper || window.contentItem || null) : null; }
