pragma Singleton

import QtQuick
import Quickshell
import wabar.services as S

// Port of caelestia's C++ SessionManager (logind over DBus). Here the session actions go through
// wabar's ControlCenter.requestAction. Every action is blocked unless CAELESTIA_ALLOW_ACTIONS=1 is
// set in the environment: a blocked action only logs and records `lastBlocked`.
// `exec(command)` returns true when the command was a session command (blocked or sent), so the
// caller must not run it as a process; it returns false for any other command.
// wabar gap: ControlCenter asks for a second call to confirm sign out, restart and shutdown; the
// second `exec` of the same command inside the confirm window runs it.
QtObject {
    id: root

    readonly property bool allowed: Quickshell.env("CAELESTIA_ALLOW_ACTIONS") === "1"
    property string lastBlocked

    readonly property var actions: ({
            "logout": "signOut",
            "poweroff": "shutdown",
            "shutdown": "shutdown",
            "reboot": "restart",
            "hibernate": "hibernate",
            "suspendThenHibernate": "sleep",
            "suspend": "sleep",
            "lock": "lock"
        })

    function actionFor(command: var): string {
        if (!command || command.length === 0)
            return "";
        if (command.length >= 2 && command[0] === "loginctl" && command[1] === "lock-session")
            return "lock";
        if (command.length === 1)
            return actions[command[0]] ?? "";
        return "";
    }

    function exec(command: var): bool {
        const action = actionFor(command);
        if (!action)
            return false;
        if (!allowed) {
            lastBlocked = action;
            console.warn(`SessionManager: blocked session action "${action}" (CAELESTIA_ALLOW_ACTIONS is not set)`);
            return true;
        }
        S.ControlCenter.requestAction(action);
        return true;
    }
}
