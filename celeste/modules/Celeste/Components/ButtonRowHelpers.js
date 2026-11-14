.pragma library

function signature(width, spacing, children) {
    let result = width + "|" + spacing;
    for (let i = 0; i < children.length; i++) {
        const child = children[i];
        result += "|" + child.visible + ":" + child.implicitWidth + ":" + child.implicitHeight + ":" + child.fillWidth + ":" + child.shapeMorphExpansion;
    }
    return result;
}

function isRepeater(item) {
    return item.delegate !== undefined && item.model !== undefined && item.count !== undefined;
}

function morph(item) {
    return item.shapeMorphExpansion === undefined || item.shapeMorphExpansion === null ? 0 : item.shapeMorphExpansion;
}

function relayout(root) {
    const kids = [];
    const children = root.children;
    for (let i = 0; i < children.length; i++) {
        const child = children[i];
        if (child.visible && !isRepeater(child))
            kids.push(child);
    }
    const count = kids.length;
    const totalSpacing = (count - 1) * root.spacing;
    let reserved = 0;
    let unreserved = 0;
    let fillCount = 0;
    let maxHeight = 0;
    for (let i = 0; i < count; i++) {
        const child = kids[i];
        maxHeight = Math.max(maxHeight, child.implicitHeight);
        if (child.fillWidth === undefined)
            continue;
        if (child.fillWidth) {
            fillCount++;
            unreserved += child.implicitWidth;
        } else {
            reserved += child.implicitWidth;
        }
    }
    if (fillCount === 0)
        fillCount = 1;
    const perItem = (root.width - totalSpacing - reserved) / fillCount;
    const base = [];
    for (let i = 0; i < count; i++)
        base.push(kids[i].fillWidth ? perItem : kids[i].implicitWidth);
    let accumulated = 0;
    for (let i = 0; i < count; i++) {
        let previous = i > 0 ? morph(kids[i - 1]) : 0;
        let next = i < count - 1 ? morph(kids[i + 1]) : 0;
        if (i > 1)
            previous /= 2;
        if (i < count - 2)
            next /= 2;
        const child = kids[i];
        child.width = base[i] + morph(child) - previous - next;
        child.height = maxHeight;
        child.x = accumulated;
        child.y = 0;
        accumulated += child.width + root.spacing;
    }
    root.implicitWidth = reserved + unreserved + totalSpacing;
    root.implicitHeight = maxHeight;
}
