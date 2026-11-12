.pragma library

function getMonitorForScreen(screen, monitors) {
    for (let i = 0; i < monitors.length; i++) {
        if (monitors[i].modelData === screen)
            return monitors[i];
    }
    return null;
}

function getMonitor(query, monitors, hypr) {
    let targetId = -1;
    if (query.startsWith("id:"))
        targetId = parseInt(query.slice(3), 10);

    for (let i = 0; i < monitors.length; i++) {
        const monitor = monitors[i];
        const screen = monitor.modelData;
        if (query === "active") {
            const hyprMonitor = hypr.monitorFor(screen);
            if (hyprMonitor && hyprMonitor.focused)
                return monitor;
        } else if (query.startsWith("model:") && screen.model === query.slice(6)) {
            return monitor;
        } else if (query.startsWith("serial:") && screen.serialNumber === query.slice(7)) {
            return monitor;
        } else if (query.startsWith("id:") && hypr.monitorFor(screen)?.id === targetId) {
            return monitor;
        } else if (!query.startsWith("model:") && !query.startsWith("serial:") && !query.startsWith("id:") && query !== "active" && screen.name === query) {
            return monitor;
        }
    }

    return query === "active" ? monitors[0] : null;
}

function setFor(monitor, query, value) {
    if (!monitor)
        return "Invalid monitor: " + query;

    let targetBrightness;
    if (value.endsWith("%-")) {
        const percent = parseFloat(value.slice(0, -2));
        targetBrightness = monitor.brightness - (percent / 100);
    } else if (value.startsWith("+") && value.endsWith("%")) {
        const percent = parseFloat(value.slice(1, -1));
        targetBrightness = monitor.brightness + (percent / 100);
    } else if (value.endsWith("%")) {
        const percent = parseFloat(value.slice(0, -1));
        targetBrightness = percent / 100;
    } else if (value.startsWith("+")) {
        const increment = parseFloat(value.slice(1));
        targetBrightness = monitor.brightness + increment;
    } else if (value.endsWith("-")) {
        const decrement = parseFloat(value.slice(0, -1));
        targetBrightness = monitor.brightness - decrement;
    } else if (value.includes("%") || value.includes("-") || value.includes("+")) {
        return "Invalid brightness format: " + value + "\nExpected: 0.1, +0.1, 0.1-, 10%, +10%, 10%-";
    } else {
        targetBrightness = parseFloat(value);
    }

    if (isNaN(targetBrightness))
        return "Failed to parse value: " + value + "\nExpected: 0.1, +0.1, 0.1-, 10%, +10%, 10%-";

    monitor.setBrightness(targetBrightness);
    return "Set monitor " + monitor.modelData.name + " brightness to " + Number(monitor.brightness.toFixed(2));
}

function adjustForScreen(screen, delta, monitors) {
    const monitor = getMonitorForScreen(screen, monitors);
    if (monitor)
        monitor.setBrightness(monitor.brightness + delta);
}

function adjustActive(direction, increment, monitors, hypr) {
    const monitor = getMonitor("active", monitors, hypr);
    if (monitor)
        monitor.setBrightness(monitor.brightness + direction * increment);
}
