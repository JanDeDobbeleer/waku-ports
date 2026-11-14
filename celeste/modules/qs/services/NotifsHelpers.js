.pragma library

function notClosed(notifications) {
    const result = [];
    for (let i = 0; i < notifications.length; i++) {
        if (!notifications[i].closed)
            result.push(notifications[i]);
    }
    return result;
}

function popups(notifications) {
    const result = [];
    for (let i = 0; i < notifications.length; i++) {
        if (notifications[i].popup)
            result.push(notifications[i]);
    }
    return result;
}

function serialize(notifications) {
    const result = [];
    for (let i = 0; i < notifications.length; i++) {
        const notification = notifications[i];
        result.push({
            time: notification.time,
            id: notification.id,
            summary: notification.summary,
            body: notification.body,
            appIcon: notification.appIcon,
            appName: notification.appName,
            image: notification.image,
            expireTimeout: notification.expireTimeout,
            urgency: notification.urgency,
            resident: notification.resident,
            hasActionIcons: notification.hasActionIcons,
            actions: Array.from(notification.actions)
        });
    }
    return JSON.stringify(result);
}

function restore(data, root, component) {
    const notifications = JSON.parse(data);
    for (let i = 0; i < notifications.length; i++) {
        const properties = Object.assign({}, notifications[i]);
        if (properties.notificationId === undefined && properties.id !== undefined)
            properties.notificationId = properties.id;
        delete properties.id;
        root.list.push(component.createObject(root, properties));
    }
    root.list.sort(function (a, b) {
        return b.time - a.time;
    });
    root.loaded = true;
}

function closeAll(notifications) {
    const snapshot = notifications.slice();
    for (let i = 0; i < snapshot.length; i++)
        snapshot[i].close();
}

function track(notification, root, component) {
    notification.tracked = true;
    const item = component.createObject(root, {
        popup: root.shouldShowPopup(),
        notification: notification
    });
    root.list = [item, ...root.list];
}
