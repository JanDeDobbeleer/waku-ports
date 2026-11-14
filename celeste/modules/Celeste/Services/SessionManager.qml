pragma Singleton

import QtQuick
import "SessionManagerHelpers.js" as SessionManagerHelpers
import Quickshell
import Celeste
import Celeste.Config
import Celeste.I18n
import waku.services as S

// Port of celeste's C++ SessionManager (logind over DBus). Here the session actions go through
// waku's ControlCenter.requestAction: lock (LockWorkStation), sleep, hibernate, signOut, restart
// and shutdown. One gate: GlobalConfig.services.allowSystemActions (default true) blocks them all;
// the environment variable CELESTE_DRYRUN=1 makes a call log `DRYRUN session <action>` and do
// nothing else. A refused or dry-run call is recorded in `lastLogged`.
// `exec(command, confirmed)` returns true when the command was a session command (handled,
// refused or logged), so the caller must not run it as a process; false for any other command.
// waku's ControlCenter asks for a second call within a few seconds to confirm signOut, restart and
// shutdown. `confirmed` (the launcher, which hides those rows until the user opts in) makes the
// second call itself; the session menu leaves it false, so its button needs a second press and a
// toast says so.
QtObject {
    id: root

    readonly final property bool dryRun: Quickshell.env("CELESTE_DRYRUN") === "1"
    readonly final property bool allowed: GlobalConfig.services.allowSystemActions
    final property string lastLogged

    readonly final property var actions: ({
            "logout": "signOut",
            "poweroff": "shutdown",
            "shutdown": "shutdown",
            "reboot": "restart",
            "hibernate": "hibernate",
            "suspendThenHibernate": "sleep",
            "suspend": "sleep",
            "lock": "lock"
        })

    readonly final property var labels: ({
            "lock": "Locking the session",
            "sleep": "Going to sleep",
            "hibernate": "Hibernating",
            "signOut": "Signing out",
            "restart": "Restarting",
            "shutdown": "Shutting down"
        })

    readonly final property var icons: ({
            "lock": "lock",
            "sleep": "bedtime",
            "hibernate": "downloading",
            "signOut": "logout",
            "restart": "cached",
            "shutdown": "power_settings_new"
        })

    function actionFor(command: var): string {
        return SessionManagerHelpers.actionFor(command, actions);
    }

    function exec(command: var, confirmed: bool): bool {
        const action = actionFor(command);
        if (!action)
            return false;
        if (!allowed) {
            lastLogged = `REFUSED session ${action}`;
            console.warn(`REFUSED session ${action}: services.allowSystemActions is false`);
            return true;
        }
        if (dryRun) {
            lastLogged = `DRYRUN session ${action}`;
            console.warn(lastLogged);
            return true;
        }
        let ran = S.ControlCenter.requestAction(action);
        if (!ran && confirmed)
            ran = S.ControlCenter.requestAction(action);
        if (ran)
            Toaster.toast(Tr.tr(labels[action]), "", icons[action], Toast.Info, 2500);
        else if (S.ControlCenter.pendingAction === action)
            Toaster.toast(Tr.tr(labels[action]), Tr.tr("Press again to confirm"), icons[action], Toast.Warning, 3500);
        return true;
    }
}
