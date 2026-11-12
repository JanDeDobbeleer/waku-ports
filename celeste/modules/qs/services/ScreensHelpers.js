.pragma library

function enabledScreens(screens, config) {
    var result = [];
    for (var i = 0; i < screens.length; i++) {
        var screen = screens[i];
        if (config.forScreen(screen.name).enabled)
            result.push(screen);
    }
    return result;
}
function isExcluded(screen, config) { return !config.forScreen(screen.name).enabled; }
