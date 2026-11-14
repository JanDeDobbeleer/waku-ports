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

function enabledEntries(entries) {
    return entries.values.filter(e => e.enabled);
}
function showPopout(root, popouts, name, child) {
    popouts.currentName = name;
    popouts.currentCenter = child.mapToItem(root, 0, child.height / 2).y;
    popouts.hasCurrent = true;
}

function checkPopout(root, y, hypr, config, qt) {
    const popouts = root.popouts;
    const child = root.childAt(root.width / 2, y);
    const id = entryId(child);
    if (id !== "clock" && popouts.currentName === "clock") popouts.hasCurrent = false;
    if (id !== "layout" && popouts.currentName === "layout") popouts.hasCurrent = false;
    if (id !== "tray" && popouts.currentName === "tray") popouts.hasCurrent = false;
    if (!child) { popouts.hasCurrent = false; return; }
    if (id === "clock") {
        if (root.screenState.dashboard) {
            if (popouts.currentName === "clock") popouts.hasCurrent = false;
        } else showPopout(root, popouts, "clock", child);
    } else if (id === "layout") {
        if (root.layoutItem && root.layoutItem.active) showPopout(root, popouts, "layout", child);
    } else if (id === "statusIcons" && config.bar.popouts.statusIcons) {
        const items = root.statusItem.items;
        const icon = items.childAt(items.width / 2, root.mapToItem(items, 0, y).y);
        if (icon) {
            popouts.currentName = iconName(icon);
            popouts.currentCenter = qt.binding(function () { return icon.mapToItem(root, 0, icon.implicitHeight / 2).y; });
            popouts.hasCurrent = true;
        }
    } else if (id === "tray" && config.bar.popouts.tray) {
        if (child.visible && root.trayItem && root.trayItem.active) showPopout(root, popouts, "tray", child);
    } else if (id === "activeWindow" && config.bar.popouts.activeWindow && config.bar.activeWindow.showOnHover) {
        const apps = root.appsItem;
        const app = apps.appAt(apps.mapFromItem(root, 0, y).y);
        if (app) {
            hypr.hoverGroupKey = groupKey(app);
            popouts.currentName = "appgroup";
            popouts.currentCenter = app.mapToItem(root, 0, app.height / 2).y;
            popouts.hasCurrent = true;
        } else popouts.hasCurrent = false;
    }
}

function debugEntries(repeater, statusItem) {
    const output = [];
    for (let i = 0; i < repeater.count; i++) {
        const id = entryId(repeater.itemAt(i));
        output.push(id === "statusIcons" ? id + "[" + childNames(statusItem.items).join(",") + "]" : id);
    }
    return output.join(" ");
}

function openPopoutNamed(root, name, repeater, statusItem, appsItem, hypr, qt) {
    for (let i = 0; i < repeater.count; i++) {
        const child = repeater.itemAt(i);
        if (!child) continue;
        const id = entryId(child);
        if (id === "clock" && name === "clock") { showPopout(root, root.popouts, name, child); return true; }
        if (id === "tray" && name === "tray") {
            if (!child.visible || !root.trayItem || !root.trayItem.active) return false;
            showPopout(root, root.popouts, name, child); return true;
        }
        if (id === "layout" && name === "layout") { showPopout(root, root.popouts, name, child); return true; }
        if (id === "activeWindow" && name.toLowerCase().startsWith("appgroup:")) {
            const key = name.slice("appgroup:".length);
            const app = appsItem.appForKey(key);
            if (!app) return false;
            hypr.hoverGroupKey = key;
            root.popouts.currentName = "appgroup";
            root.popouts.currentCenter = app.mapToItem(root, 0, app.height / 2).y;
            root.popouts.hasCurrent = true;
            return true;
        }
        if (id === "statusIcons") {
            const items = statusItem.items;
            for (let j = 0; j < items.children.length; j++) {
                const icon = items.children[j];
                if (iconName(icon) === name) {
                    root.popouts.currentName = name;
                    root.popouts.currentCenter = qt.binding(function () { return icon.mapToItem(root, 0, icon.implicitHeight / 2).y; });
                    root.popouts.hasCurrent = true;
                    return true;
                }
            }
        }
        if (id === "activeWindow" && name === "activewindow") {
            hypr.hoverToplevel = null;
            root.popouts.currentName = name;
            root.popouts.currentCenter = appsItem.mapToItem(root, 0, appsItem.implicitHeight / 2).y;
            root.popouts.hasCurrent = true;
            return true;
        }
    }
    return false;
}

function handleWheel(root, y, angleDelta, hypr, paths, config, audio, brightness, globalConfig) {
    const id = entryId(root.childAt(root.width / 2, y));
    if (id === "layout") {
        root.layoutItem.cycle(angleDelta.y > 0 ? "previous" : "next", paths.dryRun);
    } else if (id === "workspaces" && config.bar.scrollActions.workspaces) {
        const monitor = hypr.monitorFor(root.screen);
        const special = monitor ? (monitor.specialName || "") : "";
        if (special.length > 0) {
            hypr.dispatch(hypr.usingLua ? `hl.dsp.workspace.toggle_special("${special.slice(8)}")` : `togglespecialworkspace ${special.slice(8)}`);
        } else if (root.workspacesItem && root.workspacesItem.wsIds.length > 0) {
            const ids = root.workspacesItem.wsIds;
            const at = Math.max(0, ids.indexOf(monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 0));
            hypr.dispatch(`workspace ${ids[(at + (angleDelta.y > 0 ? -1 : 1) + ids.length) % ids.length]}`);
        }
    } else if (y < root.screen.height / 2 && config.bar.scrollActions.volume) {
        if (angleDelta.y > 0) audio.incrementVolume(0);
        else if (angleDelta.y < 0) audio.decrementVolume(0);
    } else if (config.bar.scrollActions.brightness) {
        if (angleDelta.y > 0) brightness.adjustForScreen(root.screen, globalConfig.services.brightnessIncrement);
        else if (angleDelta.y < 0) brightness.adjustForScreen(root.screen, -globalConfig.services.brightnessIncrement);
    }
}

function implicitWidth(item) { return item ? item.implicitWidth : 0; }
function implicitHeight(item) { return item ? item.implicitHeight : 0; }
