.pragma library

function winFocused(g, addr) {
    return g.windows.some(t => t.address === addr);
}

function onActiveWs(g) {
    return g.windows.some(t => t.wsActive !== false && !t.minimized);
}

function allMinimized(g) {
    return g.windows.length > 0 && g.windows.every(t => t.minimized);
}

function busy(g) {
    return g.windows.some(t => t.progressState === "indeterminate");
}

function windowCount(g) {
    return g.windows.length;
}

function shown(all, overflow, capacity, addr) {
    if (!overflow)
        return all;
    const keep = Math.max(1, capacity - 1);
    const out = all.slice(0, keep);
    const f = all.find(g => winFocused(g, addr));
    if (f && !out.includes(f))
        out[keep - 1] = f;
    return out;
}

function focusedIndex(shown, addr) {
    return shown.findIndex(g => winFocused(g, addr));
}

function groupAt(list, i) {
    return list[i] ?? null;
}

function avail(bar, fullCell) {
    const others = bar.children.filter(c => c.entryId && c.entryId !== "activeWindow" && c.entryId !== "spacer");
    const otherHeight = others.reduce((acc, curr) => acc + (curr.item?.nonAnimHeight ?? curr.height), 0);
    return Math.max(0, bar.height - otherHeight - bar.spacing * (bar.children.length - 1) - bar.vPadding * 2 - fullCell * 2);
}

function closePopout(bar) {
    bar.popouts.hasCurrent = false;
}

function appForKey(children, key) {
    for (let i = 0; i < children.length; i++) {
        const c = children[i];
        if (c.isApp && c.modelData?.key === key)
            return c;
    }
    return null;
}

function appAt(column, x, y) {
    const c = column.childAt(x, y);
    return c?.isApp ? c : null;
}