.pragma library

function category(wallpaper, wallsDir) {
    let value = wallpaper.parentDir.slice(wallsDir.length + 1);
    if (value.includes("/"))
        value = value.slice(0, value.indexOf("/"));
    return value;
}

function prewarm(entries, current, thumbnails, width) {
    const n = entries.length;
    if (n === 0)
        return;
    let start = 0;
    for (let i = 0; i < n; i++) {
        if (entries[i].path === current) {
            start = i;
            break;
        }
    }
    const paths = [];
    for (let distance = 0; paths.length < n; distance++) {
        if (distance === 0) {
            paths.push(entries[start].path);
            continue;
        }
        if (distance <= n - 1 && paths.length < n)
            paths.push(entries[(start + distance) % n].path);
        if (paths.length < n && 2 * distance < n)
            paths.push(entries[(start - distance + n) % n].path);
    }
    thumbnails.cancelPrewarm();
    thumbnails.prewarm(paths, width);
}

function randomPath(entries, current) {
    const others = [];
    for (let i = 0; i < entries.length; i++) {
        if (entries[i].path !== current)
            others.push(entries[i]);
    }
    const pool = others.length > 0 ? others : entries;
    return pool[Math.floor(Math.random() * pool.length)].path;
}

function createEntries(text, base, paths, images, component, parent) {
    const next = [];
    const lines = text.split(/\r?\n/);
    for (let i = 0; i < lines.length; i++) {
        const path = paths.slash(lines[i].trim());
        if (!path || !images.isValidImageByName(path))
            continue;
        const slash = path.lastIndexOf("/");
        next.push(component.createObject(parent, {
            path: path,
            name: path.slice(slash + 1),
            parentDir: path.slice(0, slash),
            relativePath: path.startsWith(base + "/") ? path.slice(base.length + 1) : path
        }));
    }
    return next;
}

function destroyEntries(entries) {
    for (let i = 0; i < entries.length; i++)
        entries[i].destroy();
}

function pathsText(entries) {
    const paths = [];
    for (let i = 0; i < entries.length; i++)
        paths.push(entries[i].path);
    return paths.join("\n");
}

function startListerLater(qt, lister) {
    qt.callLater(function() { lister.running = true; });
}
