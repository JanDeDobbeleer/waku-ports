pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste.Config
import Celeste.State
import Quickshell.Services.UPower
import waku.services as S
import qs.services
import "IdleMonitorsHelpers.js" as IdleMonitorsHelpers

// Idle timeouts over DesktopState.idleSeconds (upstream uses Wayland's IdleMonitor). `lock` is the
// lock screen, which is not ported yet: while it is null, "lock" actions are ignored. Other string
// actions were Hyprland dispatches and are ignored too; command lists are Linux commands and are
// ignored (idle timeouts never lock, sleep or shut down the machine).
Scope {
    id: root

    final property var lock: null
    readonly final property bool hasPlayer: IdleMonitorsHelpers.anyPlaying(Players.list)
    readonly final property bool isCharging: !UPower.onBattery
    readonly final property bool enabled: {
        if (GlobalConfig.general.idle.inhibitWhenAudio && hasPlayer)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenCharging && isCharging)
            return false;
        return !RuntimeState.inhibitIdle;
    }
    readonly final property int idleSeconds: S.DesktopState.idleSeconds



    Variants {
        model: IdleMonitorsHelpers.timeouts(GlobalConfig.general.idle.timeouts)

        QtObject {
            id: monitor

            required final property var modelData

            readonly final property bool monitored: IdleMonitorsHelpers.monitored(modelData, root.enabled, root.hasPlayer, root.isCharging)
            readonly final property bool isIdle: monitored && IdleMonitorsHelpers.reachedTimeout(modelData, root.idleSeconds)

            onIsIdleChanged: IdleMonitorsHelpers.handleAction(root.lock, IdleMonitorsHelpers.action(modelData, isIdle))
        }
    }
}
