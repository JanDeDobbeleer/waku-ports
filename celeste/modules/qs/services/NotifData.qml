pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications
import Celeste.Config
import Celeste.I18n
import qs.services
import "NotifDataHelpers.js" as NotifDataHelpers

QtObject {
    id: notif

    final property bool popup
    final property bool closed
    final property var locks: new Set()

    final property date time: new Date()
    final property int ageMins: 0
    readonly final property string timeStr: {
        if (ageMins < 1)
            return Tr.tr("now");

        const h = Math.floor(ageMins / 60);
        const d = Math.floor(h / 24);

        if (d > 0)
            return Tr.trCtx("%1d", "abbreviated notification age, days").arg(d);
        if (h > 0)
            return Tr.trCtx("%1h", "abbreviated notification age, hours").arg(h);
        return Tr.trCtx("%1m", "abbreviated notification age, minutes").arg(ageMins);
    }

    readonly final property Timer timeStrTimer: Timer {
        running: !notif.closed
        repeat: true
        interval: 5000
        onTriggered: notif.updateTimeStr()
    }

    final property Notification notification
    final property string notificationId
    final property string summary
    final property string body
    final property string appIcon
    final property string appName
    final property string image
    final property var hints // Hints are not persisted across restarts
    final property real expireTimeout: GlobalConfig.notifs.defaultExpireTimeout
    final property int urgency: NotificationUrgency.Normal
    final property bool resident
    final property bool hasActionIcons
    final property list<var> actions

    // waku gap: no fullscreen detection (upstream asks Hyprland).
    readonly final property bool hasFullscreen: false

    readonly final property Timer timer: Timer {
        running: true
        interval: notif.expireTimeout > 0 ? notif.expireTimeout : notif.hasFullscreen ? GlobalConfig.notifs.fullscreenExpireTimeout : GlobalConfig.notifs.defaultExpireTimeout
        onTriggered: {
            // Always expire if the active workspace has a fullscreen window
            if (GlobalConfig.notifs.expire || notif.hasFullscreen)
                notif.popup = false;
        }
    }

    // waku: Notification has no expireTimeoutChanged, residentChanged, hasActionIconsChanged, actionsChanged or hintsChanged signals.
    readonly final property Connections conn: Connections {
        function onClosed(): void {
            notif.close();
        }

        function onSummaryChanged(): void {
            notif.summary = notif.notification.summary;
        }

        function onBodyChanged(): void {
            notif.body = notif.notification.body;
        }

        function onAppIconChanged(): void {
            notif.appIcon = notif.notification.appIcon;
        }

        function onAppNameChanged(): void {
            notif.appName = notif.notification.appName;
        }

        function onImageChanged(): void {
            notif.image = notif.notification.image;
        }

        function onUrgencyChanged(): void {
            notif.urgency = notif.notification.urgency;
        }

        target: notif.notification
    }

    function updateTimeStr(): void {
        const diff = Date.now() - time.getTime();
        const m = Math.floor(diff / 60000);
        ageMins = m;

        if (m < 1) {
            NotifDataHelpers.setInterval(timeStrTimer, 5000);
        } else {
            const h = Math.floor(m / 60);
            const d = Math.floor(h / 24);

            if (d > 0)
                NotifDataHelpers.setInterval(timeStrTimer, 3600000);
            else if (h > 0)
                NotifDataHelpers.setInterval(timeStrTimer, 300000);
            else
                NotifDataHelpers.setInterval(timeStrTimer, m < 10 ? 30000 : 60000);
        }
    }

    function lock(item: Item): void {
        locks.add(item);
    }

    function unlock(item: Item): void {
        locks.delete(item);
        if (closed)
            close();
    }

    function close(): void {
        NotifDataHelpers.close(notif, locks, Notifs, notification);
    }

    Component.onCompleted: {
        if (!notification)
            return;

        notificationId = notification.id;
        summary = notification.summary;
        body = notification.body;
        appIcon = notification.appIcon;
        appName = notification.appName;
        image = notification.image;
        expireTimeout = notification.expireTimeout;
        hints = notification.hints;
        urgency = notification.urgency;
        resident = notification.resident;
        hasActionIcons = notification.hasActionIcons;

        actions = NotifDataHelpers.actions(notification.actions);
    }
}
