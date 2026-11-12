.pragma library

// The plain-data side of the Hypr service: everything that reads `var` objects lives here so the
// QML stays typed. `root` is the Hypr singleton.

function appName(exe) {
    return (exe ?? "").replace(/\.exe$/i, "").toLowerCase();
}

function appIdentity(uniqueId) {
    const id = uniqueId ?? "";
    if (id.startsWith("explorer:"))
        return "explorer";
    if (id.startsWith("aumid:"))
        return id.slice(6).split("!")[0].split("_")[0].toLowerCase();
    const path = (id.startsWith("path:") ? id.slice(5) : id).split("|")[0];
    return path.split(/[\\/]/).pop().replace(/\.exe$/i, "").toLowerCase();
}

function desktopWindows(root, hwnds) {
    const out = [];
    for (const hwnd of hwnds ?? []) {
        const row = root.taskbarWindows[hwnd];
        if (!row)
            continue;
        out.push({
            hwnd: hwnd,
            exe: row.exe || "",
            title: row.title,
            windowClass: "",
            minimized: !!row.minimized,
            order: root.taskbarRows[hwnd] ?? 0
        });
    }
    out.sort((a, b) => a.order - b.order);
    return out;
}

// Property sets for the toplevel objects of desktop `wsIdx` on monitor `monIdx`.
function windowsOf(root, monIdx, wsIdx, wsActive, desktopHwnds) {
    const out = [];
    for (const h of desktopWindows(root, desktopHwnds)) {
        const row = root.taskbarWindows[h.hwnd] ?? {
            title: h.title,
            exe: h.exe,
            iconUrl: ""
        };
        const name = appName(h.exe || row.exe);
        const icon = row.iconUrl || root.appIconUrl(name);
        if (h.minimized && !name)
            continue;
        out.push({
            title: row.title,
            address: String(h.hwnd),
            wsId: wsIdx + 1,
            monId: monIdx,
            wsActive: wsActive,
            minimized: !!h.minimized,
            progressState: row.progressState ?? "none",
            progress: row.progress ?? 0,
            iconUrl: row.iconUrl ?? "",
            icon: icon,
            appClass: name,
            windowClass: h.windowClass,
            fullscreen: 0
        });
    }
    return out;
}

function sameList(a, b) {
    if (a.length !== b.length)
        return false;
    for (let i = 0; i < a.length; i++)
        if (a[i] !== b[i])
            return false;
    return true;
}

function later(o) {
    // A delegate may still show the object for a moment.
    if (o)
        o.destroy(1000);
}

function rebuild(root, wakuMons, screens) {
    const plan = [];
    for (let i = 0; i < screens.length; i++) {
        const screen = screens[i];
        let wmi = wakuMons.findIndex(m => m.name === screen.name);
        if (wmi < 0 && wakuMons.length === screens.length)
            wmi = i;
        if (wmi < 0)
            wmi = wakuMons.findIndex(m => m.handle === 0);
        const wm = wmi >= 0 ? wakuMons[wmi] : null;
        const wsPlan = [];
        const list = wm?.workspaces ?? [];
        for (let j = 0; j < list.length; j++) {
            const src = list[j];
            wsPlan.push({
                key: screen.name + "|" + src.id,
                srcId: String(src.id),
                index: j,
                label: src.label || String(j + 1),
                active: !!src.active,
                focused: !!src.focused,
                windows: windowsOf(root, wmi, j, !!src.active, src.windows)
            });
        }
        plan.push({
            name: screen.name,
            id: i,
            handle: wm?.handle ?? 0,
            workspaces: wsPlan
        });
    }
    const sig = JSON.stringify(plan);
    if (sig === root.rebuildSig)
        return;
    root.rebuildSig = sig;

    const mons = [];
    const wss = [];
    const newMonObjs = {};
    const newWsObjs = {};
    const newWinSigs = {};
    const oldObjs = [];
    let focusedMon = null;
    let windowsChanged = false;

    for (const mp of plan) {
        let mon = root.monObjs[mp.name];
        if (!mon) {
            mon = root.makeMonitor(mp.name, mp.id, mp.handle);
        } else {
            if (mon.id !== mp.id)
                mon.id = mp.id;
            if (mon.handle !== mp.handle)
                mon.handle = mp.handle;
        }
        newMonObjs[mp.name] = mon;
        mons.push(mon);
        let activeWs = null;
        for (const wp of mp.workspaces) {
            const winSig = JSON.stringify(wp.windows);
            let ws = root.wsObjs[wp.key];
            const isNew = !ws;
            if (isNew)
                ws = root.makeWorkspace(wp.srcId, mon);
            if (ws.id !== wp.index + 1)
                ws.id = wp.index + 1;
            if (ws.name !== wp.label)
                ws.name = wp.label;
            if (ws.monitor !== mon)
                ws.monitor = mon;
            if (ws.active !== wp.active)
                ws.active = wp.active;
            if (ws.focused !== wp.focused)
                ws.focused = wp.focused;
            if (isNew || root.wsWinSigs[wp.key] !== winSig) {
                windowsChanged = true;
                for (const o of ws.toplevels)
                    later(o);
                const tls = [];
                for (const d of wp.windows) {
                    const t = root.makeToplevel(d);
                    t.workspace = ws;
                    tls.push(t);
                }
                ws.toplevels = tls;
            }
            newWinSigs[wp.key] = winSig;
            newWsObjs[wp.key] = ws;
            wss.push(ws);
            if (wp.active)
                activeWs = ws;
            if (wp.focused)
                focusedMon = mon;
        }
        if (activeWs && mon.activeWorkspace !== activeWs)
            mon.activeWorkspace = activeWs;
    }
    if (!focusedMon && mons.length > 0)
        focusedMon = mons[0];
    for (const m of mons)
        if (m.focused !== (m === focusedMon))
            m.focused = m === focusedMon;

    for (const k of Object.keys(root.monObjs))
        if (!newMonObjs[k])
            oldObjs.push(root.monObjs[k]);
    for (const k of Object.keys(root.wsObjs))
        if (!newWsObjs[k]) {
            for (const o of root.wsObjs[k].toplevels)
                later(o);
            oldObjs.push(root.wsObjs[k]);
        }
    if (oldObjs.length > 0)
        windowsChanged = true;
    root.monObjs = newMonObjs;
    root.wsObjs = newWsObjs;
    root.wsWinSigs = newWinSigs;

    // A list that did not change is not assigned, so nothing downstream re-evaluates.
    if (!sameList(root.monitors.values, mons))
        root.monitors.values = mons;
    if (!sameList(root.workspaces.values, wss))
        root.workspaces.values = wss;
    if (windowsChanged) {
        // One entry per window: virtual desktops show the same windows on every screen.
        const all = [];
        const seen = {};
        for (const w of wss)
            for (const t of w.toplevels) {
                if (seen[t.address])
                    continue;
                seen[t.address] = true;
                all.push(t);
            }
        root.toplevels.values = all;
        updateGroups(root, all);
    }
    for (const o of oldObjs)
        o.destroy();
}

function groupKey(t) {
    return t.appClass || t.windowClass || t.address;
}

function groupProgress(windows) {
    const priority = { error: 0, paused: 1, normal: 2, indeterminate: 3, none: 4 };
    let state = "none";
    let value = 0;
    for (const t of windows) {
        const next = t.progressState ?? "none";
        const p = priority[next] ?? 4;
        const v = t.progress ?? 0;
        if (p < priority[state] || (p === priority[state] && v < value)) {
            state = next;
            value = v;
        }
    }
    return { state: state, value: value };
}

function updateGroups(root, real) {
    root.lastAll = real;
    for (const f of root.fakeObjs)
        later(f);
    const fakes = [];
    const all = real.slice();
    for (let i = 0; i < root.debugCopies && real.length > 0; i++) {
        const f = root.makeToplevel({
            title: "Fake window " + (i + 1),
            address: "fake" + i,
            srcHwnd: real[0].address,
            wsId: ((real[0].wsId + i) % 7) + 1,
            monId: real[0].monId,
            wsActive: real[0].wsActive,
            minimized: real[0].minimized,
            progressState: real[0].progressState,
            progress: real[0].progress,
            iconUrl: real[0].iconUrl,
            icon: real[0].icon,
            appClass: real[0].appClass,
            windowClass: real[0].windowClass,
            fullscreen: real[0].fullscreen
        });
        f.workspace = real[0].workspace;
        fakes.push(f);
        all.push(f);
    }
    root.fakeObjs = fakes;
    const by = {};
    for (const t of all) {
        if (!t.address)
            continue;
        const k = groupKey(t);
        if (!by[k])
            by[k] = [];
        by[k].push(t);
    }
    const order = root.groupOrder.filter(k => by[k]);
    for (const k of Object.keys(by))
        if (!order.includes(k))
            order.push(k);
    root.groupOrder = order;
    for (const g of root.appGroups)
        later(g);
    root.appGroups = order.map(k => {
        const p = groupProgress(by[k]);
        return root.makeGroup({
            key: k,
            exe: k,
            windows: by[k],
            icon: by[k][0].icon,
            iconUrl: by[k][0].iconUrl,
            progressState: p.state,
            progress: p.value
        });
    });
}

function updateRows(root, rows) {
    const known = {};
    const idx = {};
    for (let i = 0; i < rows.count; i++) {
        const o = rows.objectAt(i);
        if (o && o.key.startsWith("w:")) {
            idx[o.key.slice(2)] = i;
            known[o.key.slice(2)] = {
                title: o.title,
                exe: o.exe,
                iconUrl: o.iconUrl,
                minimized: o.minimized,
                progressState: o.progressState,
                progress: o.progress
            };
        }
    }
    const knownSig = JSON.stringify(known);
    if (knownSig !== root.knownSig) {
        const keys = Object.keys(known).sort().join(",");
        root.knownSig = knownSig;
        root.taskbarWindows = known;
        // A window that came or went: look at the desktops now instead of at the next poll.
        if (keys !== root.knownKeys) {
            root.knownKeys = keys;
            root.refreshDesktops();
        }
        root.rebuild();
    }
    const idxSig = JSON.stringify(idx);
    if (idxSig !== root.rowsSig) {
        root.rowsSig = idxSig;
        root.taskbarRows = idx;
    }
    for (let i = 0; i < rows.count; i++) {
        const o = rows.objectAt(i);
        if (o && o.active) {
            const fgSig = o.key + "|" + o.title + "|" + o.exe;
            if (fgSig === root.foregroundSig && root.foreground)
                return;
            root.foregroundSig = fgSig;
            later(root.foreground);
            root.foreground = root.makeToplevel({
                title: o.title,
                address: o.key.startsWith("w:") ? o.key.slice(2) : "",
                appClass: o.exe
            });
            return;
        }
    }
    root.foregroundSig = "";
    later(root.foreground);
    root.foreground = null;
}

function engineSignature(S) {
    return JSON.stringify([S.Workspaces.provider, S.Workspaces.connected, S.Workspaces.monitors]);
}

function find(list, pred) {
    for (let i = 0; i < list.length; i++)
        if (pred(list[i]))
            return list[i];
    return null;
}

function focusedWorkspace(list) {
    return find(list, w => w.focused);
}

function focusedMonitor(list) {
    return find(list, m => m.focused) ?? list[0] ?? null;
}

function monitorFor(list, name) {
    return find(list, m => m.name === name);
}

function workspaceById(list, id, mon) {
    return (mon ? find(list, x => x.monitor === mon && x.id === id) : null) ?? find(list, x => x.id === id);
}

function workspaceLabel(list, t) {
    const w = find(list, x => x.monitor?.id === t?.monId && x.id === t?.wsId);
    return w?.name ?? String(t?.wsId ?? "");
}

function groupByKey(groups, key) {
    return find(groups, g => g.key === key);
}

function toplevelsOf(ws) {
    return ws ? ws.toplevels : [];
}

function isFullscreenOn(ws) {
    return !!ws && ws.toplevels.some(t => t.fullscreen > 1);
}

function workspaceByName(list, name) {
    return name ? find(list, ws => ws.name === name) : null;
}

function groupSize(g) {
    return g ? g.windows.length : 0;
}

function windowAt(g, i) {
    return g && g.windows[i] ? g.windows[i] : null;
}

// The window a click on a group icon activates: the next window of the group when one of them has
// focus, else the one that had focus last (or the first).
function clickTarget(g, focusedHwnd, lastFocused) {
    const ws = g?.windows ?? [];
    if (ws.length === 0)
        return null;
    const fi = ws.findIndex(t => t.address === focusedHwnd);
    if (fi >= 0)
        return ws.length > 1 ? ws[(fi + 1) % ws.length] : ws[0];
    return ws.find(t => t.address === lastFocused[g.key]) ?? ws[0];
}

function noteFocus(root) {
    const t = find(root.toplevels.values, x => x.address === root.focusedHwnd);
    if (t) {
        const k = groupKey(t);
        if (root.groupLastFocused[k] !== t.address)
            root.groupLastFocused[k] = t.address;
    }
}

function appIconUrl(root, name) {
    // The exe name first, then without a vendor prefix ("ms-teams") and without separators.
    for (const n of [name, name.replace(/^ms-/, ""), name.replace(/[-_. ]/g, "")]) {
        const url = n ? root.iconUrlFor(n) : "";
        if (url)
            return url;
    }
    return "";
}

// `workspace N`, `workspace r+1`, `workspace r-1`: the argument; "" for anything else.
function parseDispatch(request) {
    const m = /^workspace\s+(r[+-]1|\d+)$/.exec(request ?? "");
    return m ? m[1] : "";
}

function names(list) {
    return list.map(e => e.name);
}
function rowIndex(taskbarRows, hwnd) {
    const row = taskbarRows[hwnd];
    return row === undefined ? -1 : row;
}

function activateWindow(windowControl, hwnd) {
    return typeof windowControl !== "undefined" && !!windowControl && !!windowControl.activate(Number(hwnd));
}

function hasWindowControl(windowControl) {
    return typeof windowControl !== "undefined" && !!windowControl;
}

function pendingHwnd(p) {
    return p ? String(p.hwnd) : "";
}

function roleValue(model, name, fallback) {
    return model[name] ?? fallback;
}

function specialIds(list, mon, allMonitors) {
    return list.filter(w => w.name.startsWith("special:") && (allMonitors || w.monitor === mon)).map(w => w.id);
}
