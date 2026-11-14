.pragma library

function comps(env) {
    return env.ShellState.componentsFor(env.Screens.screens[0]);
}

function barEntry(env, id) {
    return comps(env)?.bar?.entryItem(id);
}

function searchField(env) {
    return comps(env)?.find("launcherSearch");
}

// The list the search drives: the wallpaper PathView or the app/action ListView.
function listOf(env) {
    const c = comps(env);
    const s = searchField(env);
    if (!c || !s)
        return null;
    const wall = s.text.startsWith(`${env.GlobalConfig.launcher.actionPrefix}wallpaper `);
    return c.find(wall ? "launcherWallpaperList" : "launcherAppList");
}

function visualIn(o, depth) {
    if (o.kind !== undefined && o.ready !== undefined)
        return o;
    if (depth > 6)
        return null;
    for (let i = 0; i < o.children.length; i++) {
        const r = visualIn(o.children[i], depth + 1);
        if (r)
            return r;
    }
    return null;
}

function rows(env) {
    const l = listOf(env);
    return l?.model?.values ?? [];
}

function rowName(v) {
    return v ? (v.relativePath ?? v.name ?? String(v)) : "null";
}

function popout(env, name) {
    const c = comps(env);
    if (!c?.bar)
        return "no bar";
    return c.bar.openPopoutNamed(name) ? "ok" : `no entry named ${name}`;
}

function popoutClose(env) {
    const c = comps(env);
    if (c?.panels)
        c.panels.popouts.hasCurrent = false;
}

function popoutState(env) {
    const screen = env.Screens.screens[0];
    const c = env.ShellState.componentsFor(screen);
    const p = c?.panels?.popouts;
    if (!p)
        return "none";
    const pt = p.mapToItem(null, 0, 0);
    const r = screen.devicePixelRatio;
    const f = v => Math.round(v * r);
    return `${p.currentName} ${p.hasCurrent} ${f(pt.x)} ${f(pt.y)} ${f(p.width)} ${f(p.height)}`;
}

function btDevices(env) {
    return env.Bluetooth.devices.values.map(d => `${d.connected} ${d.row?.type} ${env.Icons.getBluetoothIcon(d.icon)}`).join("; ");
}

function trayState(env) {
    const t = barEntry(env, "tray");
    const T = env.TrayItems;
    return `${T.count} ${t ? t.active : "no button"} ${t ? t.height : 0} [${T.lastAction}]`;
}

function trayClick(env, i, button) {
    const T = env.TrayItems;
    const it = T.debugFake > 0 ? T.items[i] : null;
    if (!it)
        return "none";
    if (button === "left")
        it.activate();
    else if (button === "middle")
        it.secondaryActivate();
    else
        it.display(null, 0, 0);
    return T.lastAction;
}

function entries(env) {
    return comps(env)?.bar?.debugEntries() ?? "none";
}

function clickWorkspace(env, n) {
    const w = barEntry(env, "workspaces");
    if (!w)
        return "no workspaces";
    if (env.Hypr.activeWsId !== n)
        return "refused: not the focused workspace";
    return w.clickWorkspace(n);
}

function clickClock(env) {
    const b = comps(env)?.bar;
    return b ? b.clickClock() : "no bar";
}

function dashState(env) {
    const s = env.ShellState.forScreen(env.Screens.screens[0]);
    return `${s.dashboard} ${s.dashboardTab} ${s.dashboardDate.getFullYear()}-${s.dashboardDate.getMonth() + 1}`;
}

function dashTab(env, i) {
    const s = env.ShellState.forScreen(env.Screens.screens[0]);
    if (i < 0) {
        s.dashboard = false;
        return "closed";
    }
    s.dashboardTab = i;
    s.dashboard = true;
    return `dashboard tab ${i}`;
}

function dashRect(env) {
    const screen = env.Screens.screens[0];
    const d = env.ShellState.componentsFor(screen)?.panels?.dashboard;
    if (!d)
        return "none";
    const pt = d.mapToItem(null, 0, 0);
    const f = v => Math.round(v * screen.devicePixelRatio);
    return `${f(pt.x)} ${f(pt.y)} ${f(d.width)} ${f(d.height)}`;
}

function utilitiesTab(env) {
    const U = env.UtilitiesActions;
    const shown = U.actions;
    return `${shown.length} of ${U.all.length} probed=${U.probed} missing=[${Object.keys(U.missing).join(",")}] ${shown.map(a => `${a.id}=${a.target}`).join(" ")}`;
}

function utilitiesAction(env, id) {
    if (!env.Paths.dryRun)
        return "refused: not a dry run";
    const target = env.UtilitiesActions.launch(id);
    return target ? `${target} [${env.UtilitiesActions.lastLogged}]` : `no action ${id}`;
}

function clickApp(env, i) {
    const l = barEntry(env, "activeWindow");
    if (!l)
        return "no apps list";
    const g = l.shown[i];
    if (!g || g.windows.length !== 1 || g.windows[0].address !== l.focusedAddress)
        return "refused: not a single focused window";
    return l.clickApp(i);
}

function activateGroupWindow(env, exe, i) {
    const g = env.Hypr.groupByKey(exe);
    if (!g?.windows[i])
        return "none";
    if (g.windows[i].address !== env.Hypr.focusedHwnd)
        return "refused: not the focused window";
    return env.Hypr.activateGroupWindow(exe, i);
}

function appGroups(env) {
    const H = env.Hypr;
    return H.appGroups.map(g => `${g.exe} ${g.windows.length} ${g.windows.map(t => H.workspaceLabel(t)).join("/")} [${g.windows.map(t => (t.srcHwnd || t.address) + (t.minimized ? "(min)" : "")).join(",")}]${g.windows.some(t => t.address === H.focusedHwnd) ? " *" : ""}`).join("; ");
}

function appProgress(env) {
    const H = env.Hypr;
    return JSON.stringify(H.appGroups.map(g => ({
        app: g.exe,
        state: g.progressState,
        value: g.progress,
        windows: g.windows.map(t => ({
            hwnd: t.address,
            focused: t.address === H.focusedHwnd,
            state: t.progressState,
            value: t.progress
        }))
    })));
}

function clickAppDry(env, i) {
    const l = barEntry(env, "activeWindow");
    const g = l?.shown[i];
    if (!g)
        return "none";
    const t = env.Hypr.clickTarget(g);
    return `${g.exe} ${t.address}${t.minimized ? "(min)" : ""} -> ${env.Hypr.previewActivate(t)}`;
}

function thumbState(env) {
    try {
        const p = comps(env)?.panels?.popouts;
        const g = p?.current ?? p?.content?.item?.currentPopout?.item ?? p?.content?.item?.current;
        return g && typeof g.thumbState === "function" ? g.thumbState() : `no group flyout (${p?.currentName} ${p?.hasCurrent} current=${g} type=${typeof g?.thumbState})`;
    } catch (e) {
        return "error " + e;
    }
}

function dots(env) {
    const w = barEntry(env, "workspaces");
    return w ? w.debugDots() : "no workspaces";
}

function layoutDry(env, direction) {
    const b = barEntry(env, "layout");
    return b ? b.cycle(direction, true) : "no layout button";
}

function clickLayout(env) {
    const b = barEntry(env, "layout");
    if (!b)
        return "no layout button";
    if (!env.Paths.dryRun)
        return "refused: not a dry run";
    return b.click(env.Paths.dryRun);
}

function layoutButton(env) {
    const b = barEntry(env, "layout");
    return b ? b.debugState() : "no layout button";
}

function apps(env) {
    try {
        const l = barEntry(env, "activeWindow");
        if (!l)
            return "no apps list";
        const H = env.Hypr;
        const marks = l.shown.map(g => g.windows.map(t => String(t.wsId) + (t.minimized ? "m" : "")).join("+") + (g.windows.some(t => t.address === l.focusedAddress) ? "*" : ""));
        return [l.count, l.shown.length, l.cell, l.focusedIndex(), "fg=" + l.focusedAddress, "avail=" + H.taskbarAvailable, "win=" + H.barWindow, "model=" + H.taskbarCount, "rows=" + Object.keys(H.taskbarRows).length, "wc=" + (typeof env.WindowControl !== "undefined"), marks.join(",")].join(" ");
    } catch (e) {
        return "error " + e;
    }
}

function winState(env) {
    const c = comps(env);
    const w = c?.rootWindow;
    if (!w)
        return "no window";
    const bw = w.backingWindow;
    const s = env.ShellState.forScreen(env.Screens.screens[0]);
    return `active=${bw.active} visible=${bw.visible} focusItem=${bw.activeFocusItem} keyboardFocus=${w.keyboardFocus} fg=${env.WindowControl.foreground()} launcher=${s.launcher} session=${s.session} lightDismiss=${c.panels ? "yes" : "no"}`;
}

function saveFg(env) {
    env.scope.savedFg = env.WindowControl.foreground();
    return String(env.scope.savedFg);
}

function restoreFg(env) {
    return String(env.WindowControl.activate(env.scope.savedFg)) + " fg=" + env.WindowControl.foreground();
}

function actions(env) {
    const names = [];
    const list = env.Actions.list;
    for (let i = 0; i < list.length; i++)
        names.push(list[i].name);
    return names.join(", ");
}

function pressAt(env, x, y) {
    const w = comps(env)?.interactionWrapper;
    return w ? String(w.dismissOnPress(x, y)) : "no window";
}

function setLauncher(env, on) {
    env.ShellState.forScreen(env.Screens.screens[0]).launcher = on;
    return "ok";
}

function search(env, text) {
    const s = searchField(env);
    if (!s)
        return "no search field (open the launcher first)";
    s.text = text;
    return "ok";
}

function list(env) {
    const l = listOf(env);
    if (!l)
        return "no list";
    return rows(env).map((v, i) => `${i === l.currentIndex ? "*" : " "}${i} ${rowName(v)}`).join("\n");
}

function walls(env) {
    const l = listOf(env);
    if (!l)
        return "no list";
    let ready = 0, shown = 0, items = 0;
    for (let i = 0; i < l.count; i++) {
        const item = l.itemAtIndex(i);
        if (!item)
            continue;
        items++;
        if (item.opacity < 0.01)
            continue;
        shown++;
        const v = visualIn(item, 0);
        const done = v ? v.ready === true : false;
        if (done)
            ready++;
    }
    return `ready=${ready} shown=${shown} items=${items}`;
}

function select(env, i) {
    const l = listOf(env);
    const s = searchField(env);
    if (!l || !s)
        return "no list";
    if (!s.text.startsWith(env.GlobalConfig.launcher.actionPrefix))
        return "refused: only the > lists (an app row would start the app)";
    if (i < 0 || i >= rows(env).length)
        return `no row ${i}`;
    l.currentIndex = i;
    s.accepted();
    return `ok ${rowName(rows(env)[i])}`;
}

function click(env, i) {
    const l = listOf(env);
    if (!l)
        return "no list";
    if (!searchField(env).text.startsWith(env.GlobalConfig.launcher.actionPrefix))
        return "refused: only the > lists (an app row would start the app)";
    const item = l.itemAtIndex(i);
    if (!item)
        return `row ${i} has no item`;
    let layer = null;
    for (let k = 0; k < item.children.length; k++)
        if (item.children[k].objectName === "rowClick")
            layer = item.children[k];
    if (!layer)
        return `row ${i} has no click target`;
    layer.clicked(null);
    return "ok";
}

function launcherState(env) {
    const s = searchField(env);
    const l = listOf(env);
    const G = env.GlobalConfig;
    const C = env.Colours;
    const W = env.WallpaperService;
    const open = env.ShellState.forScreen(env.Screens.screens[0]).launcher;
    const mode = !s ? "-" : s.text.startsWith(`${G.launcher.actionPrefix}wallpaper `) ? "wallpapers" : s.text.startsWith(G.launcher.actionPrefix) ? "actions" : "apps";
    return `scheme=${C.scheme} seed=${C.seed} variant=${C.flavour} light=${C.currentLight} wallpaper=${W.actualCurrent.slice(W.actualCurrent.lastIndexOf("/") + 1)} session=${env.SessionManager.lastLogged} | open=${open} search=[${s?.text ?? ""}] rows=${l ? rows(env).length : -1} count=${l?.count ?? -1} mode=${mode} index=${l?.currentIndex ?? -1} shown=${l?.pathItemCount ?? l?.count ?? -1} walls=${W.list.length} dir=${env.Paths.wallsdir}`;
}

function probeStart(env, mode, count) {
    for (const o of env.scope.probes)
        o.destroy();
    const next = [];
    const list = env.WallpaperService.list;
    for (let i = 0; i < count && i < list.length; i++) {
        const path = list[i].path;
        next.push(env.probeComp.createObject(env.scope, mode === "thumb" ? {
            source: env.Thumbnails.url(path, 640)
        } : {
            source: "file:///" + path,
            sourceSize: Qt.size(280, 158)
        }));
    }
    env.scope.probes = next;
    return `started ${next.length}`;
}

function probeResult(env) {
    const ms = env.scope.probes.map(o => o.ms);
    const ok = ms.filter(m => m >= 0);
    return `n=${ms.length} ready=${ok.length} error=${ms.filter(m => m === -2).length} first=${ok.length ? Math.min(...ok) : -1} last=${ok.length ? Math.max(...ok) : -1}`;
}

function coloursDump(env) {
    const C = env.Colours;
    const p = C.palette;
    return `currentLight=${C.currentLight} showPreview=${C.showPreview} lock=${env.WallpaperService.previewColourLock} wall=${env.WallpaperService.actualCurrent} surface=${p.m3surface} primary=${p.m3primary} background=${p.m3background} current.surface=${C.current.m3surface} preview.surface=${C.preview.m3surface} t.surface=${C.tPalette.m3surface}`;
}

function step(env, i) {
    const l = listOf(env);
    if (!l)
        return "no list";
    l.currentIndex = i;
    return `ok ${i}`;
}