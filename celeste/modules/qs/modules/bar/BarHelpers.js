.pragma library

function entryId(ch) {
    return ch?.entryId ?? "";
}

function hasItem(ch) {
    return !!ch.item;
}

function itemOf(ch) {
    return ch?.item ?? null;
}

function field(obj, name) {
    return obj[name];
}

function iconName(icon) {
    return icon.name;
}

function groupKey(app) {
    return app.modelData.key;
}

function childNames(items) {
    return Array.from({
        length: items.children.length
    }, (_, j) => items.children[j].name);
}

function enabledEntries(values) {
    return values.filter(e => e.enabled);
}