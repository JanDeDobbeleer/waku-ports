.pragma library

function viewport(qt, cutils, container, list, watcher, width) {
    cutils.dependency(watcher.transform);
    const origin = list.mapToItem(container.contentItem, 0, 0);
    return qt.rect(0, container.contentY - origin.y, width, container.height);
}

function previewItems(notifications, expanded, previewCount) {
    if (expanded)
        return notifications.slice();
    let count = 0;
    let i = 0;
    while (i < notifications.length && count < previewCount) {
        if (!(notifications[i] && notifications[i].closed))
            count++;
        i++;
    }
    return notifications.slice(0, i);
}

function lock(notification, item) { if (notification) notification.lock(item); }
function unlock(notification, item) { if (notification) notification.unlock(item); }
function close(notification) { if (notification) notification.close(); }
function cursorShape(body, pressed, qt) {
    return body && body.hoveredLink ? qt.PointingHandCursor : pressed ? qt.ClosedHandCursor : undefined;
}
function contentItem(container) { return container.contentItem; }
