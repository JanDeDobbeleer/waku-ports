.pragma library

function setInterval(timer, interval) { timer.interval = interval; }
function close(notif, locks, notifications, notification) {
    notif.closed = true;
    if (locks.size === 0 && notifications.list.includes(notif)) {
        const remaining = [];
        for (let i = 0; i < notifications.list.length; i++) {
            if (notifications.list[i] !== notif)
                remaining.push(notifications.list[i]);
        }
        notifications.list = remaining;
        if (notification)
            notification.dismiss();
        notif.destroy();
    }
}
function actions(source) {
    const result = [];
    for (let i = 0; i < source.length; i++) {
        const action = source[i];
        result.push({
            identifier: action.identifier,
            text: action.text,
            invoke: function() { action.invoke(); }
        });
    }
    return result;
}
