pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste.Config
import Celeste.State
import Quickshell.Services.UPower
import waku.services as S
import qs.services

// Idle timeouts over DesktopState.idleSeconds (upstream uses Wayland's IdleMonitor). `lock` is the
// lock screen, which is not ported yet: while it is null, "lock" actions are ignored. Other string
// actions were Hyprland dispatches and are ignored too; command lists are Linux commands and are
// ignored (idle timeouts never lock, sleep or shut down the machine).
Scope {
    id: root

    final property var lock: null
    readonly final property bool hasPlayer: Players.list.some(p => p.isPlaying)
    readonly final property bool isCharging: !UPower.onBattery
    readonly final property bool enabled: {
        if (GlobalConfig.general.idle.inhibitWhenAudio && hasPlayer)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenCharging && isCharging)
            return false;
        return !RuntimeState.inhibitIdle;
    }
    readonly final property int idleSeconds: S.DesktopState.idleSeconds

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

            required final property var modelData

            readonly final property bool monitored: {
                if (!root.enabled || !(modelData.enabled ?? true))
                    return false;
                if (modelData.inhibitWhenAudio && root.hasPlayer)
                    return false;
                if (modelData.inhibitWhenCharging && root.isCharging)
                    return false;
                return true;
            }
            readonly final property bool isIdle: monitored && root.idleSeconds >= modelData.timeout

            onIsIdleChanged: root.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction)
        }
    }
}
