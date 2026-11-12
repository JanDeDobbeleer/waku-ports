.pragma library

function incrementFrequency(root, id) {
    root.counts[id] = (root.counts[id] || 0) + 1;
    for (let i = 0; i < root.sorted.length; i++) {
        const app = root.sorted[i];
        if (app.appId === id)
            app.frequency = root.counts[id];
    }
    resort(root);
}

function isFavourite(patterns, id) {
    const list = patterns || [];
    for (let i = 0; i < list.length; i++) {
        try {
            if (new RegExp(list[i]).test(id))
                return true;
        } catch (error) {
        }
    }
    return false;
}

function rebuild(root) {
    const next = {};
    const list = [];
    const entries = root.entries || [];
    for (let i = 0; i < entries.length; i++) {
        const entry = entries[i];
        if (!entry)
            continue;
        const id = entry.id;
        let app = root.cache[id];
        if (!app || app.entry !== entry)
            app = root.entryComponent.createObject(root, {
                entry: entry,
                frequency: root.counts[id] || 0
            });
        next[id] = app;
        list.push(app);
    }
    for (const id in root.cache) {
        if (next[id] !== root.cache[id])
            root.cache[id].destroy();
    }
    root.cache = next;
    root.sorted = list;
    resort(root);
}

function resort(root) {
    const list = root.sorted.slice();
    const favourites = {};
    for (let i = 0; i < list.length; i++)
        favourites[list[i].appId] = isFavourite(root.favouriteApps, list[i].appId);
    list.sort(function (a, b) {
        if (favourites[a.appId] !== favourites[b.appId])
            return favourites[a.appId] ? -1 : 1;
        if (a.frequency !== b.frequency)
            return b.frequency - a.frequency;
        return a.name.localeCompare(b.name);
    });
    root.sorted = list;
}
