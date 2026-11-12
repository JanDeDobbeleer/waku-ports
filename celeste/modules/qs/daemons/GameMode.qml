import QtQuick
import Quickshell
import Celeste
import Celeste.Config
import Celeste.I18n
import Celeste.State
import qs.services
import "GameModeHelpers.js" as GameModeHelpers

Scope {
    id: root

    // waku gap: nothing to switch off. Windows has no compositor effects to disable, so game
    // mode is a flag other modules can read.
    function applyGameMode(): void {
        GameModeHelpers.applyOptions(Hypr);
    }

    function syncState(enableDisable: bool): void {
        if (RuntimeState.gameMode) {
            root.applyGameMode();
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(Tr.tr("Game mode enabled"), Tr.tr("No window effects to disable on Windows"), "gamepad", Toast.Info, 5000);
        } else if (enableDisable) {
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(Tr.tr("Game mode disabled"), Tr.tr("Window effects unchanged"), "gamepad", Toast.Info, 5000);
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
