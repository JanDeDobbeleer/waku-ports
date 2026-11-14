.pragma library

function maxHeight(bar, activeWindow) {
    const children = bar.children;
    let otherHeight = 0;
    for (let i = 0; i < children.length; i++) {
        const child = children[i];
        if (!child.entryId || child.item === activeWindow || child.entryId === "spacer")
            continue;
        const item = child.item;
        otherHeight += item ? (item.nonAnimHeight === undefined ? child.height : item.nonAnimHeight) : child.height;
    }
    return bar.height - otherHeight - bar.spacing * (children.length - 1) - bar.vPadding * 2;
}

function positionChanged(bar) {
    const popouts = bar.popouts;
    if (popouts.hasCurrent && popouts.currentName !== "activewindow")
        popouts.hasCurrent = false;
}

function clicked(activeWindow, bar) {
    const popouts = bar.popouts;
    if (popouts.hasCurrent) {
        popouts.hasCurrent = false;
    } else {
        popouts.currentName = "activewindow";
        popouts.currentCenter = activeWindow.mapToItem(bar, 0, activeWindow.implicitHeight / 2).y;
        popouts.hasCurrent = true;
    }
}
