.pragma library

function adjustBrightness(monitor, direction, increment) {
    if (!monitor || direction === 0)
        return;
    var change = direction > 0 ? increment : -increment;
    monitor.setBrightness(monitor.brightness + change);
}
function setBrightness(monitor, value) {
    if (monitor)
        monitor.setBrightness(value);
}
