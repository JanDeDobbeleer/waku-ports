.pragma library

function count(notifications) {
    let total = 0;
    for (let i = 0; i < notifications.length; i++) {
        if (!notifications[i].closed)
            total++;
    }
    return total;
}

function disablePopups(notifications) {
    for (let i = 0; i < notifications.length; i++)
        notifications[i].popup = false;
}

function clearNext(notifications, timer) {
    const first = notifications[0];
    if (!first) {
        timer.stop();
        return;
    }
    let cleared = 0;
    for (let i = 0; i < notifications.length; i++) {
        const notification = notifications[i];
        if (notification.appName !== first.appName)
            continue;
        notification.close();
        cleared++;
        if (cleared > 30) {
            timer.interval = 5;
            return;
        }
    }
}
