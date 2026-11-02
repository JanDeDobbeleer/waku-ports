import QtQuick
import Quickshell
import Quickshell.Io
import waku.services as S
import Caelestia.State

Scope {
    id: root

    Connections {
        function onInhibitIdleChanged(): void {
            if (RuntimeState.inhibitIdle)
                RuntimeState.inhibitingIdleSince = new Date().getTime();
        }

        target: RuntimeState
    }

    // waku's IdleInhibitor holds SetThreadExecutionState; it ignores `window`.
    S.IdleInhibitor {
        enabled: RuntimeState.inhibitIdle
    }

    IpcHandler {
        function isEnabled(): bool {
            return RuntimeState.inhibitIdle;
        }

        function toggle(): void {
            RuntimeState.inhibitIdle = !RuntimeState.inhibitIdle;
        }

        function enable(): void {
            RuntimeState.inhibitIdle = true;
        }

        function disable(): void {
            RuntimeState.inhibitIdle = false;
        }

        target: "idleInhibitor"
    }
}
