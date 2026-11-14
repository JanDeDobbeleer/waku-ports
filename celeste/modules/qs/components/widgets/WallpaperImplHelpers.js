.pragma library

function shader(config, shaders, cutils) {
    cutils.dependency(config.wallpaperTransition);
    let transition = cutils.enumToString(config, "wallpaperTransition", config.wallpaperTransition);
    if (!transition)
        return shaders.crossfade;
    transition = transition[0].toLowerCase() + transition.slice(1);
    return shaders[transition] || shaders.crossfade;
}
function duration(shader) { return shader.duration; }
function easing(shader) { return shader.easing; }
function url(shader) { return shader.url; }
function setSourceItem(capture, item) { capture.sourceItem = item; }
function scheduleUpdate(capture) { capture.scheduleUpdate(); }
