.pragma library

function maxHeight(screenHeight, border, padding, dashboardVisible, panels) {
    var max = screenHeight - border * 2 + padding;
    if (dashboardVisible)
        max -= panels.dashboard.nonAnimHeight;
    return max;
}
function preload(apps) { return apps; }
