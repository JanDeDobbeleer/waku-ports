.pragma library

function move(currentList, forward) {
    if (!currentList)
        return;
    if (forward) currentList.incrementCurrentIndex();
    else currentList.decrementCurrentIndex();
}

function horizontal(currentList, showWallpapers, event, forward) {
    if (showWallpapers)
        move(currentList, forward);
    else
        event.accepted = false;
}

function accepted(currentList, showWallpapers, text, actionPrefix, scheme, actualWallpaper, wallpapers, apps, screenState) {
    const currentItem = currentList ? currentList.currentItem : null;
    if (!currentItem)
        return;
    const entry = currentItem.modelData;
    if (showWallpapers) {
        if (scheme === "dynamic" && entry.path !== actualWallpaper)
            wallpapers.previewColourLock = true;
        wallpapers.setWallpaper(entry.path);
        screenState.launcher = false;
    } else if (text.startsWith(actionPrefix)) {
        if (text.startsWith(actionPrefix + "calc "))
            currentItem.onClicked();
        else
            entry.onClicked(currentList);
    } else {
        apps.launch(entry);
        screenState.launcher = false;
    }
}

function keyPressed(event, currentList, showWallpapers, text, actionPrefix, vimKeybinds, scheme, actualWallpaper, wallpapers, apps, screenState, keyReturn, keyEnter, shiftModifier, controlModifier, keyJ, keyN, keyK, keyP, keyTab, keyBacktab) {
    if ((event.key === keyReturn || event.key === keyEnter) && (event.modifiers & shiftModifier) && showWallpapers) {
        const item = currentList ? currentList.currentItem : null;
        const entry = item ? item.modelData : null;
        if (entry) {
            if (scheme === "dynamic" && entry.path !== actualWallpaper)
                wallpapers.previewColourLock = true;
            if (wallpapers.setWallpaperAllDesktops(entry.path))
                screenState.launcher = false;
        }
        event.accepted = true;
        return;
    }
    if ((event.key === keyReturn || event.key === keyEnter) && (event.modifiers & shiftModifier) && !showWallpapers && !text.startsWith(actionPrefix)) {
        const item = currentList ? currentList.currentItem : null;
        const entry = item ? item.modelData : null;
        if (entry) {
            let started = true;
            if (event.modifiers & controlModifier)
                started = apps.launchAdmin(entry);
            else
                apps.launchNew(entry);
            if (started)
                screenState.launcher = false;
        }
        event.accepted = true;
        return;
    }
    if (!vimKeybinds)
        return;
    if (event.modifiers & controlModifier) {
        if (event.key === keyJ || event.key === keyN) {
            move(currentList, true);
            event.accepted = true;
        } else if (event.key === keyK || event.key === keyP) {
            move(currentList, false);
            event.accepted = true;
        }
    } else if (event.key === keyTab) {
        move(currentList, true);
        event.accepted = true;
    } else if (event.key === keyBacktab || (event.key === keyTab && (event.modifiers & shiftModifier))) {
        move(currentList, false);
        event.accepted = true;
    }
}
