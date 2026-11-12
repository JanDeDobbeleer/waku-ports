pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Celeste
import Celeste.Config
import Celeste.I18n
import Celeste.State
import qs.components.misc
import qs.services
import qs.utils
import qs.compat
import "NotifsHelpers.js" as NotifsHelpers

Singleton {
    id: root

    final property list<NotifData> list: []
    readonly final property list<NotifData> notClosed: NotifsHelpers.notClosed(list)
    readonly final property list<NotifData> popups: NotifsHelpers.popups(list)

    final property bool loaded

    // waku gap: no fullscreen detection (upstream asks Hyprland).
    function hasFullscreen(): bool {
        return false;
    }

    function shouldShowPopup(): bool {
        if (PersistentState.doNotDisturb || ShellState.anySidebarOpen())
            return false;
        if (GlobalConfig.notifs.fullscreen === NotifsFullscreen.Off && hasFullscreen())
            return false;
        return true;
    }

    onListChanged: {
        if (loaded)
            saveTimer.restart();
    }

    Connections {
        function onDoNotDisturbChanged(): void {
            if (!GlobalConfig.utilities.toasts.dndChanged)
                return;

            if (PersistentState.doNotDisturb)
                Toaster.toast(Tr.tr("Do not disturb enabled"), Tr.tr("Popup notifications are now disabled"), "do_not_disturb_on", Toast.Info, 5000);
            else
                Toaster.toast(Tr.tr("Do not disturb disabled"), Tr.tr("Popup notifications are now enabled"), "do_not_disturb_off", Toast.Info, 5000);
        }

        target: PersistentState
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: storage.setText(NotifsHelpers.serialize(root.notClosed))
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => NotifsHelpers.track(notif, root, notifComp)
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/notifs.json`
        onLoaded: {
            NotifsHelpers.restore(text(), root, notifComp);
        }
        // Upstream creates an empty file here. The config home watcher reloads the shell on
        // every write under it, so the file appears with the first notification instead.
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.loaded = true;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clearNotifs"
        description: "Clear all notifications"
        onPressed: {
            NotifsHelpers.closeAll(root.list);
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "toggleDnd"
        description: "Toggle do not disturb"
        onPressed: {
            PersistentState.doNotDisturb = !PersistentState.doNotDisturb;
        }
    }

    IpcHandler {
        function clear(): void {
            NotifsHelpers.closeAll(root.list);
        }

        function isDndEnabled(): bool {
            return PersistentState.doNotDisturb;
        }

        function toggleDnd(): void {
            PersistentState.doNotDisturb = !PersistentState.doNotDisturb;
        }

        function enableDnd(): void {
            PersistentState.doNotDisturb = true;
        }

        function disableDnd(): void {
            PersistentState.doNotDisturb = false;
        }

        target: "notifs"
    }

    Component {
        id: notifComp

        NotifData {}
    }
}
