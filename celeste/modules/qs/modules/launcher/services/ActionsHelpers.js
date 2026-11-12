.pragma library

function visibleActions(launcher) {
    const result = [];
    const values = launcher.actions.values || [];
    for (let i = 0; i < values.length; i++) {
        const action = values[i];
        if (action.enabled && (launcher.enableDangerousActions || !action.dangerous) && !(action.command || []).includes("nexus"))
            result.push(action);
    }
    return result;
}

function invoke(name, launcher, rows) {
    const wanted = name.toLowerCase();
    const values = launcher.actions.values || [];
    let config = null;
    for (let i = 0; i < values.length; i++) {
        const action = values[i];
        if (action.enabled && (action.name || "").toLowerCase() === wanted) {
            config = action;
            break;
        }
    }
    if (!config)
        return "no action named " + name;
    if (config.dangerous && !launcher.enableDangerousActions) {
        console.warn("REFUSED launcher action " + config.name + ": launcher.enableDangerousActions is false");
        return "refused: dangerous actions are disabled";
    }
    for (let i = 0; i < rows.length; i++) {
        if (rows[i].name.toLowerCase() === wanted) {
            rows[i].run(null, null);
            return "ok";
        }
    }
    return "no row for " + name;
}

function displayName(data, tr) {
    return data.name ? tr.trMarked(data.name) : tr.trCtx("Unnamed", "launcher action with no name");
}

function displayDescription(data, tr) {
    return data.description ? tr.trMarked(data.description) : tr.trCtx("No description", "launcher action with no description");
}

function icon(data) {
    return data.icon || "help_outline";
}

function command(data) {
    return data.command || [];
}

function enabled(data) {
    return data.enabled === undefined ? true : data.enabled;
}

function dangerous(data) {
    return data.dangerous === undefined ? false : data.dangerous;
}

function onClicked(list, run) {
    run(list.screenState, list.search);
}

function run(action, screenState, search, config, colours, sessionManager, wallpaperService) {
    const command = action.command;
    if (command.length === 0)
        return;
    if (action.dangerous && !config.launcher.enableDangerousActions) {
        console.warn("REFUSED launcher action " + action.name + ": launcher.enableDangerousActions is false");
        return;
    }
    if (command[0] === "autocomplete" && command.length > 1) {
        if (search)
            search.text = config.launcher.actionPrefix + command[1] + " ";
        return;
    }
    if (screenState)
        screenState.launcher = false;
    if (command[0] === "setMode" && command.length > 1) {
        colours.setMode(command[1]);
    } else if (sessionManager.exec(command, true)) {
        return;
    } else if (command[0] === "celeste" && command[1] === "wallpaper" && command[2] === "-r") {
        wallpaperService.setRandom();
    } else {
        console.warn("Launcher: no Windows counterpart for", command.join(" "));
    }
}
