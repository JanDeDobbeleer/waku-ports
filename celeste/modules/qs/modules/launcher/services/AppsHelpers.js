.pragma library

function launch(appDb, entry) {
    appDb.incrementFrequency(entry.id);
    entry.execute();
}

function launchNew(appDb, entry) {
    appDb.incrementFrequency(entry.id);
    if (entry.executeNew)
        entry.executeNew();
    else
        entry.execute();
}

function launchAdmin(appDb, entry) {
    const actions = entry.actions || [];
    let action = null;
    for (let i = 0; i < actions.length; i++) {
        if (actions[i].id === "admin") {
            action = actions[i];
            break;
        }
    }
    if (!action)
        return false;
    appDb.incrementFrequency(entry.id);
    action.execute();
    return true;
}

function search(root, searchText, prefix) {
    if (searchText.startsWith(prefix + "i ")) {
        root.keys = ["id", "name"];
        root.weights = [0.9, 0.1];
    } else if (searchText.startsWith(prefix + "c ")) {
        root.keys = ["categories", "name"];
        root.weights = [0.9, 0.1];
    } else if (searchText.startsWith(prefix + "d ")) {
        root.keys = ["comment", "name"];
        root.weights = [0.9, 0.1];
    } else if (searchText.startsWith(prefix + "e ")) {
        root.keys = ["execString", "name"];
        root.weights = [0.9, 0.1];
    } else if (searchText.startsWith(prefix + "w ")) {
        root.keys = ["startupClass", "name"];
        root.weights = [0.9, 0.1];
    } else if (searchText.startsWith(prefix + "g ")) {
        root.keys = ["genericName", "name"];
        root.weights = [0.9, 0.1];
    } else if (searchText.startsWith(prefix + "k ")) {
        root.keys = ["keywords", "name"];
        root.weights = [0.9, 0.1];
    } else {
        root.keys = ["name"];
        root.weights = [1];
        if (!searchText.startsWith(prefix + "t ")) {
            const defaultResults = root.query(searchText);
            const mapped = [];
            for (let i = 0; i < defaultResults.length; i++)
                mapped.push(defaultResults[i].entry);
            return mapped;
        }
    }
    const results = root.query(searchText.slice(prefix.length + 2));
    const mapped = [];
    for (let i = 0; i < results.length; i++) {
        const entry = results[i].entry;
        if (!searchText.startsWith(prefix + "t ") || entry.runInTerminal)
            mapped.push(entry);
    }
    return mapped;
}

function selector(keys, item) {
    const values = [];
    for (let i = 0; i < keys.length; i++)
        values.push(item[keys[i]]);
    return values.join(" ");
}

function visibleEntries(applications, hiddenApps, strings) {
    const entries = applications.values;
    const visible = [];
    for (let i = 0; i < entries.length; i++) {
        if (!strings.testRegexList(hiddenApps, entries[i].id))
            visible.push(entries[i]);
    }
    return visible;
}
