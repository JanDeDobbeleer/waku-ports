.pragma library

function forApp(notifications, appName) {
    const result = [];
    for (let i = 0; i < notifications.length; i++) {
        if (notifications[i].appName === appName)
            result.push(notifications[i]);
    }
    return result;
}

function active(notifications) {
    const result = [];
    for (let i = 0; i < notifications.length; i++) {
        if (!notifications[i].closed)
            result.push(notifications[i]);
    }
    return result;
}

function image(notifications) {
    for (let i = 0; i < notifications.length; i++) {
        if (notifications[i].image.length > 0)
            return notifications[i].image;
    }
    return "";
}

function appIcon(notifications) {
    for (let i = 0; i < notifications.length; i++) {
        if (notifications[i].appIcon.length > 0)
            return notifications[i].appIcon;
    }
    return "";
}

function urgency(notifications, critical, normal, low) {
    for (let i = 0; i < notifications.length; i++) {
        if (notifications[i].urgency === critical)
            return critical;
    }
    for (let i = 0; i < notifications.length; i++) {
        if (notifications[i].urgency === normal)
            return normal;
    }
    return low;
}

function summary(notifications) { return notifications.length > 0 ? notifications[0].summary : ""; }
function timeStr(notifications) { return notifications.length > 0 ? notifications[0].timeStr : ""; }
