.pragma library

function viewport(qt, container, width) {
    return qt.rect(0, container.contentY, width, container.height);
}

function appNames(notClosed, notifications) {
    const names = [];
    const seen = new Set();
    const lists = [notClosed, notifications];
    for (let listIndex = 0; listIndex < lists.length; listIndex++) {
        const list = lists[listIndex];
        for (let i = 0; i < list.length; i++) {
            const name = list[i].appName;
            if (!seen.has(name)) {
                seen.add(name);
                names.push(name);
            }
        }
    }
    return names;
}

function forApp(notifications, appName) {
    const result = [];
    for (let i = 0; i < notifications.length; i++) {
        if (notifications[i].appName === appName)
            result.push(notifications[i]);
    }
    return result;
}

function closeBatch(notifications, appName, timer) {
    const matching = forApp(notifications, appName);
    if (matching.length === 0) {
        timer.stop();
        return;
    }
    const count = Math.min(matching.length, 30);
    for (let i = 0; i < count; i++)
        matching[i].close();
}
