.pragma library

// Plain-data side of the bar workspaces list (Workspaces.qml and its dots).

function sameIds(a, b) {
    return a.join(",") === b.join(",");
}

function workspaceCount(list, mon) {
    let n = 0;
    for (let i = 0; i < list.length; i++)
        if (list[i].monitor === mon)
            n++;
    return n;
}

function used(w, activeWsId) {
    if (w.id === activeWsId)
        return true;
    for (let i = 0; i < w.toplevels.length; i++)
        if (w.toplevels[i].appClass)
            return true;
    return false;
}

// Every occupied workspace, the active one and the first empty one after the last of those (a
// slot to move to an empty desktop), in workspace order.
function dynamicIds(list, mon, activeWsId) {
    const mine = list.filter(w => w.monitor === mon);
    const ids = mine.filter(w => used(w, activeWsId)).map(w => w.id);
    const last = ids.length > 0 ? Math.max(...ids) : 0;
    const spare = mine.find(w => w.id > last);
    if (spare)
        ids.push(spare.id);
    return ids;
}

function range(n) {
    return Array.from({
        length: n
    }, (_, i) => i + 1);
}

function shownIds(list, mon, activeWsId, allMonitors, shown) {
    const mine = list.filter(w => w.id > 0 && (allMonitors || w.monitor === mon) && used(w, activeWsId));
    const currentIdx = mine.findIndex(w => w.id === activeWsId);
    if (currentIdx < 0)
        return [];
    const lo = Math.min(shown, mine.length);
    const end = Math.min(Math.max(currentIdx + 1, lo), mine.length);
    const start = Math.max(0, end - shown);
    return mine.slice(start, end).map(w => w.id);
}

function itemWs(item) {
    return item?.ws ?? 0;
}
