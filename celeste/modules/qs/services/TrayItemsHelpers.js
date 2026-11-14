.pragma library

function fakeItems(root, count, component) {
    const items = [];
    for (let i = 0; i < count; i++)
        items.push(component.createObject(root, { fakeIndex: i }));
    return items;
}

function items(debugFake, fakeItems, systemTray, trayConfig, passiveStatus) {
    if (debugFake > 0)
        return fakeItems;
    const values = systemTray.items.values;
    const result = [];
    for (let i = 0; i < values.length; i++) {
        const item = values[i];
        if (item.status !== passiveStatus && !trayConfig.hiddenIcons.includes(item.id))
            result.push(item);
    }
    return result;
}

function count(items) {
    return items.length;
}

function fakeGlyph(root, index) {
    return root.fakeNames[index % root.fakeNames.length];
}

function record(root, id, action) {
    root.lastAction = action + " " + id;
}
