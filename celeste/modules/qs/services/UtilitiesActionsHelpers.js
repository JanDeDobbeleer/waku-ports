.pragma library

function actions(all, missing, displayDevice) {
    const result = [];
    for (let i = 0; i < all.length; i++) {
        const action = all[i];
        if ((!action.probe || !missing[action.probe]) && (!action.battery || displayDevice.isLaptopBattery))
            result.push(action);
    }
    return result;
}

function inGroup(actions, group) {
    const result = [];
    for (let i = 0; i < actions.length; i++) {
        if (actions[i].group === group)
            result.push(actions[i]);
    }
    return result;
}

function find(all, id) {
    for (let i = 0; i < all.length; i++) {
        if (all[i].id === id)
            return all[i];
    }
    return null;
}

function launch(root, id, all, dryRun, shell) {
    const action = find(all, id);
    if (!action || !action.target)
        return "";
    if (dryRun) {
        root.lastLogged = "DRYRUN utilities " + action.id + " " + action.target;
        console.warn(root.lastLogged);
        return action.target;
    }
    root.lastLogged = "utilities " + action.id + " " + action.target;
    shell.open(action.target);
    return action.target;
}

function probeCommand(all) {
    const paths = [];
    for (let i = 0; i < all.length; i++) {
        if (all[i].probe)
            paths.push("'" + all[i].probe + "'");
    }
    return ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", "@(" + paths.join(",") + ") | ForEach-Object { if (Test-Path -LiteralPath ([Environment]::ExpandEnvironmentVariables($_))) { 'Y ' + $_ } else { 'N ' + $_ } }"];
}

function applyProbeOutput(root, output) {
    const next = {};
    const lines = output.split(/\r?\n/);
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].startsWith("N "))
            next[lines[i].slice(2).trim()] = true;
    }
    root.missing = next;
    root.probed = true;
}
