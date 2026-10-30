import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.State
import qs.services

Scope {
    id: root

    // wabar gap: nothing to switch off. Windows has no compositor effects to disable, so game
    // mode is a flag other modules can read.
    function applyGameMode(): void {
        Hypr.extras.applyOptions({});
    }

    function syncState(enableDisable: bool): void {
        if (RuntimeState.gameMode) {
            root.applyGameMode();
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(Tr.tr("Game mode enabled"), Tr.tr("No window effects to disable on Windows"), "gamepad");
        } else if (enableDisable) {
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(Tr.tr("Game mode disabled"), Tr.tr("Window effects unchanged"), "gamepad");
        }
    }

    Component.onCompleted: syncState(false)

    Connections {
        function onGameModeChanged(): void {
            root.syncState(true);
        }

        target: RuntimeState
    }

    Connections {
        function onConfigReloaded(): void {
            if (RuntimeState.gameMode)
                root.applyGameMode();
        }

        target: Hypr
    }

    IpcHandler {
        function isEnabled(): bool {
            return RuntimeState.gameMode;
        }

        function toggle(): void {
            RuntimeState.gameMode = !RuntimeState.gameMode;
        }

        function enable(): void {
            RuntimeState.gameMode = true;
        }

        function disable(): void {
            RuntimeState.gameMode = false;
        }

        target: "gameMode"
    }
}
