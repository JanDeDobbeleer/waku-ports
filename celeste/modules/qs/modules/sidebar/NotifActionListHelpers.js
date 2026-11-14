.pragma library

function actions(notification) {
    const result = [{ isClose: true }];
    const available = notification && notification.actions ? notification.actions : [];
    for (let i = 0; i < available.length; i++)
        result.push(available[i]);
    result.push({ isCopy: true });
    return result;
}
function isClose(action) { return action && action.isClose === true; }
function isCopy(action) { return action && action.isCopy === true; }
function isSpecial(action) { return isClose(action) || isCopy(action); }
function iconText(action) { return isCopy(action) ? "content_copy" : "close"; }
function identifier(action) { return action ? action.identifier : ""; }
function actionText(action) { return action ? action.text : ""; }
function setIconText(item, text) { if (item) item.text = text; }
function activate(action, notification, quickshell, iconItem, timer) {
    if (isClose(action)) {
        notification.close();
    } else if (isCopy(action)) {
        quickshell.clipboardText = notification.body;
        setIconText(iconItem, "inventory");
        timer.start();
    } else if (action && action.invoke) {
        action.invoke();
    } else if (!notification.resident) {
        notification.close();
    }
}
