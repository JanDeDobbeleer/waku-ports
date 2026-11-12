.pragma library

function numItems(window, panels, screenState, content, border, maxWallpapers, itemWidth, itemCount) {
    const screen = window ? window.screen : null;
    if (!screen)
        return 0;
    const barMargins = Math.max(border.thickness, panels.bar.implicitWidth);
    let outerMargins = 0;
    if (panels.popouts.hasCurrent && panels.popouts.currentCenter + panels.popouts.nonAnimHeight / 2 > screen.height - content.implicitHeight - border.thickness * 2)
        outerMargins = panels.popouts.nonAnimWidth;
    if ((screenState.utilities || screenState.sidebar) && panels.utilities.implicitWidth > outerMargins)
        outerMargins = panels.utilities.implicitWidth;
    const maxWidth = screen.width - border.rounding * 4 - (barMargins + outerMargins) * 2;
    if (maxWidth <= 0)
        return 0;
    const visible = Math.min(Math.floor(maxWidth / itemWidth), maxWallpapers, itemCount);
    if (visible === 2)
        return 1;
    if (visible > 1 && visible % 2 === 0)
        return visible - 1;
    return visible;
}

function search(searchBar) {
    return searchBar.text.split(" ").slice(1).join(" ");
}

function query(service, searchText) {
    const results = service.query(searchText);
    const filtered = [];
    for (let i = 0; i < results.length; i++) {
        if (results[i])
            filtered.push(results[i]);
    }
    return filtered;
}

function queryIndex(values, searchText, actualCurrent) {
    if (searchText)
        return 0;
    for (let i = 0; i < values.length; i++) {
        if (values[i].path === actualCurrent)
            return i;
    }
    return -1;
}

function currentIndex(wallpapers, actualCurrent) {
    for (let i = 0; i < wallpapers.length; i++) {
        if (wallpapers[i] && wallpapers[i].path === actualCurrent)
            return i;
    }
    return -1;
}

function preview(service, currentItem) {
    const data = currentItem ? currentItem.modelData : null;
    const path = data ? data.path : null;
    if (path)
        service.preview(path);
}
