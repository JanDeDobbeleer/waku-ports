pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.State
import Quickshell.Services.UPower
import wabar.services as S
import qs.services
import qs.utils

// Idle timeouts over DesktopState.idleSeconds (upstream uses Wayland's IdleMonitor). `lock` is the
// lock screen, which is not ported yet: while it is null, "lock" actions are ignored. Other string
// actions were Hyprland dispatches and are ignored too; command lists are Linux commands and are
// ignored (idle timeouts never lock, sleep or shut down the machine).
Scope {
    id: root

    property var lock: null
    readonly property bool hasPlayer: Players.list.some(p => p.isPlaying)
    readonly property bool isCharging: !UPower.onBattery
    readonly property bool enabled: {
        if (GlobalConfig.general.idle.inhibitWhenAudio && hasPlayer)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenCharging && isCharging)
            return false;
        return !RuntimeState.inhibitIdle;
    }
    readonly property int idleSeconds: S.DesktopState.idleSeconds

    function handleIdleAction(action: var): void {
        if (!action)
            return;

        if (action === "lock") {
            if (lock)
                lock.lock.locked = true;
        } else if (action === "unlock") {
            if (lock)
                lock.lock.locked = false;
        }
    }

    Variants {
        model: GlobalConfig.general.idle.timeouts.values

        QtObject {
            id: monitor

            required property var modelData

            readonly property bool monitored: {
                if (!root.enabled || !(modelData.enabled ?? true))
                    return false;
                if (modelData.inhibitWhenAudio && root.hasPlayer)
                    return false;
                if (modelData.inhibitWhenCharging && root.isCharging)
                    return false;
                return true;
            }
            readonly property bool isIdle: monitored && root.idleSeconds >= modelData.timeout

            onIsIdleChanged: root.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction)
        }
    }
}
